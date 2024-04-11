import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:result_notifier/result_notifier.dart';
import 'package:shared_model/shared_model.dart';

import 'package:wanna_chat_app/api/chat_api.dart';
import 'package:wanna_chat_app/widgets/chat_bubble.dart';
import 'package:wanna_chat_app/widgets/extensions.dart';


class ChatScreen extends StatefulWatcherWidget {
  const ChatScreen({required this.conversationId, required this.baseUrl, super.key});

  final String conversationId;
  final String baseUrl;

  @override
  WatcherState createState() => _ChatScreenState();

  Widget _build(WatcherContext context, _ChatScreenState state) {
    final chatState = state.chat.watch(context);

    final size = MediaQuery.sizeOf(context);
    final double width = min(size.width, 800.0);
    final contentWidth = width - (context.margin * 2);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Wanna chat?!'),
        actions: [
          if (chatState.isLoading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator()).padded(right: 16),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chatList(context, state, contentWidth).expanded(),
              const SizedBox(height: 16),
              SafeArea(
                child: SizedBox(
                  width: contentWidth,
                  height: 88,
                  child: _messageInput(context, state),
                ),
              ),
            ],
          ).padded(horizontal: context.margin),
        ),
      ),
    );
  }

  Widget _chatList(BuildContext context, _ChatScreenState state, double maxWidth) {
    final messages = state.messages.reversed.toList();
    final sessionInitials = conversationId.substring(0, 1).toUpperCase();

    if (messages.isEmpty) return const Text('Conversation is empty').centered();

    return ListView.builder(
      shrinkWrap: true,
      reverse: true,
      controller: state.scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: messages.length,
      itemBuilder: (BuildContext context, int index) {
        return ChatBubble(
          sessionInitials: sessionInitials,
          message: messages[index],
          maxWidth: maxWidth,
          key: ValueKey('message$index'),
        );
      },
    );
  }

  Widget _messageInput(BuildContext context, _ChatScreenState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        TextField(
          enabled: !state.chat.isLoading,
          onSubmitted: (_) => state.askQuestion(),
          controller: state.textController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.circular(8.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.teal),
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.only(
              right: 42,
              left: 16,
              top: 18,
            ),
            hintText: 'Enter your question here',
          ),
        ).expanded(),

        const SizedBox(width: 8),
        // if (state.chat.isLoading) const CircularProgressIndicator().centered(),
        // if (!state.chat.isLoading)
          IconButton(
            icon: Icon(Icons.send, color: state.chat.isLoading ? Colors.grey : Colors.teal),
            tooltip: 'Ask question',
            onPressed: state.chat.isLoading ? null : state.askQuestion,
          ),
      ],
    );
  }
}

/// State
class _ChatScreenState extends WatcherState<ChatScreen> {
  late final api = ChatApi(baseUrl: widget.baseUrl, conversationId: widget.conversationId);

  late final ResultNotifier<ChatConversation> chat = ResultNotifier<ChatConversation>(
    result: Loading(data: ChatConversation(id: widget.conversationId)),
    onErrorReturn: (_) => chat.data.removeLastAILoadingMessage(),
  );

  List<WannaChatMessage> get messages => chat.dataOrNull?.messages ?? [];

  StreamSubscription<String>? _responseSubscription;

  late final Disposer onErrorDisposer;

  final scrollController = ScrollController();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    onErrorDisposer = chat.onError((error, stackTrace, data) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 6000),
        content: Text(error.toString()),
        action: SnackBarAction(
          label: 'Close',
          onPressed: scaffoldMessenger.hideCurrentSnackBar,
        ),
      ));
    });
    restoreConversation();
  }

  @override
  void dispose() {
    onErrorDisposer();
    super.dispose();
  }

  void clearConversation() {
    chat.updateDataAsync(() async {
      await api.clearHistory();
      return await api.restoreConversation();
    });
  }

  void restoreConversation() {
    chat.updateDataAsync(() => api.restoreConversation());
  }

  void askQuestion() {
    final question = WannaChatMessage.human(message: textController.text);
    final aiLoadingMessage = WannaChatMessage.aiLoading();
    chat.data = chat.data.withMessages([question, aiLoadingMessage]);
    chat.toLoading();

    //askQuestionComplete(question);
    askQuestionStreamed(question);
  }

  void askQuestionComplete(WannaChatMessage question) {
    Future<ChatConversation> sendMessage() async {
      final aiMessage = await api.sendMessage(question);
      textController.clear();
      return chat.data.appendLastAIMessage(aiMessage.message);
    }

    chat.updateDataAsync(() => sendMessage());
  }

  void askQuestionStreamed(WannaChatMessage question) {
    final response = api.sendMessageStreamed(question);
    _responseSubscription?.cancel();
    _responseSubscription = response.listen((response) {
      if (textController.text.isNotEmpty) textController.clear();
      chat.toLoading(data: chat.data.appendLastAIMessage(response));
    }, onError: (Object error) {
      _responseSubscription?.cancel();
      chat.toError(error: error);
    }, onDone: () {
      _responseSubscription?.cancel();
      chat.toData();
    });
  }

  @override
  Widget build(WatcherContext context) => widget._build(context, this);
}
