import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:shared_model/shared_model.dart';

/// The API client, for communicating with the WannaChat server.
class ChatApi {
  late final Uri baseUrl;
  final String conversationId;
  final Client _client;

  ChatApi({required String baseUrl, required this.conversationId}) : _client = Client() {
    final base = Uri.parse(baseUrl);
    this.baseUrl = base.replace(pathSegments: [...base.pathSegments, conversationId]);
  }

  Future<ChatConversation> restoreConversation() async {
    final response = await _client.get(baseUrl);
    _handleResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final messagesJson = body['history'] as List;
    return ChatConversation(
        id: conversationId,
        messages: messagesJson.map((e) => WannaChatMessage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<WannaChatMessage> sendMessage(WannaChatMessage message) async {
    final response = await _client.post(baseUrl, body: jsonEncode(message), headers: {'Content-type': 'application/json'});
    _handleResponse(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return WannaChatMessage.fromJson(body['answer'] as Map<String, dynamic>);
  }

  Stream<String> sendMessageStreamed(WannaChatMessage message) {
    final request = Request('POST', baseUrl)
      ..body = jsonEncode(message.toJson()..['stream'] = true)
      ..headers['Content-type'] = 'application/json';

    final stream = StreamController<String>();

    bool responseProcessed = false;
    _client.send(request).then((response) {
      if (!responseProcessed) {
        responseProcessed = true;
        _handleResponse(response, onError: (e) => stream.addError(e));
      }
      if (response.statusCode == 200) {
        late final StreamSubscription subscription;
        subscription = response.stream.listen((value) {
          //print('Response: $value');
          stream.add(utf8.decode(value));
        }, onDone: () {
          stream.close();
          subscription.cancel();
        }, onError: (Object e) {
          stream.addError(e);
          stream.close();
          subscription.cancel();
        });
      }
    }).catchError((Object e) {
      stream.addError(e);
    });

    return stream.stream;
  }

  Future<void> clearHistory() async {
    final response = await _client.delete(baseUrl);
    _handleResponse(response);
  }

  void _handleResponse(BaseResponse response, {Function(Exception)? onError}) {
    final handleError = onError ?? (e) => throw e;

    Exception? exception;
    if (response.statusCode == 503) {
      exception = Exception('Server not yet ready...');
    } else if (response.statusCode != 200) {
      exception = Exception('Failed to send request ($baseUrl) - ${response.statusCode} - ${response.reasonPhrase}');
    }
    if(exception != null) {
      handleError(exception);
    }
  }
}


/// A conversation in the chat, i.e. the history of a chat
class ChatConversation {
  ChatConversation({required this.id, this.messages = const []});

  final String id;
  final List<WannaChatMessage> messages;

  ChatConversation withMessage(WannaChatMessage message) {
    return ChatConversation(id: id, messages: [...messages, message]);
  }

  ChatConversation withMessages(List<WannaChatMessage> messages) {
    return ChatConversation(id: id, messages: [...this.messages, ...messages]);
  }

  ChatConversation appendLastAIMessage(String partialResponse) {
    if (messages.isEmpty || messages.last.isHuman) {
      return this;
    }
    return ChatConversation(id: id, messages: [...messages.sublist(0, messages.length-1), messages.last.appendMessage(partialResponse)]);
  }

  ChatConversation removeLastAILoadingMessage() {
    final truncatedMessages = messages.last.isAiLoading ? messages.sublist(0, messages.length-1) : messages;
    return ChatConversation(id: id, messages: truncatedMessages);
  }
}
