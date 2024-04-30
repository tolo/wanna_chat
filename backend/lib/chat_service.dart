import 'dart:io';

import 'package:collection/collection.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:logging/logging.dart';
import 'package:shared_model/shared_model.dart';


const String _rephraseQuestionPromptTemplate = '''
Given the following conversation history and a follow up question, rephrase the follow up question to be a standalone question.

Conversation history, delimited by ```:
```{history}```

Follow up question, delimited by ```:
```{question}```

Standalone question:
''';

const String _answerGenerationPromptTemplate = '''
Now, answer this question using the previous context and chat history:
{question}
''';

const String _areaOfExpertise = 'DDD';

const String _welcomeMessage = 'Hello **{name}**! I am a friendly AI bot, expert in $_areaOfExpertise and happy to teach you everything I know - go ahead and ask me a question!';

const String _responseStylePersona = 'Erlich Bachman from the TV series "Silicon Valley"';

// Feel free to have a lot of opinions and give suggestions around improvements and embellishments.
const String _finalAnswerPromptTemplate = '''
You are an experienced software architect, expert at answering questions based on provided sources and giving helpful advice. 
Using the below provided context, answer the user's question to the best of your ability using only the resources provided. 
Be concise and stick to the subject! 
If you don't know the answer, just say that you don't know, don't try to make up an answer.

When responding, do it in the style of $_responseStylePersona.  

<context>
{context}
</context>
''';

const List<String> _documentFileNames = [
  './data/DDD_Reference_2015-03-2.txt',
  './data/DomainDrivenDesignQuicklyOnline.txt',
  './data/The-InfoQ-eMag-Domain-Driven-Design-in-Practice-1539011107810.txt',
  './data/Domain-Driven Design in Software Development-arxiv.org-2310.01905.txt',
];


class WannaChatService {
  WannaChatService() {
    final openAiApiKey = Platform.environment['OPENAI_API_KEY'];
    if (openAiApiKey == null) {
      stderr.writeln('You need to set your OpenAI key in the OPENAI_API_KEY environment variable.');
      exit(64);
    }
    _deterministicModel = ChatOpenAI(
      apiKey: openAiApiKey,
      defaultOptions: const ChatOpenAIOptions(
        temperature: 0.0,
        //model: 'gpt-3.5-turbo', // Default
        model: 'gpt-4-turbo',
      ),
    );
    _creativeModel = ChatOpenAI(
      apiKey: openAiApiKey,
      defaultOptions: const ChatOpenAIOptions(
        temperature: 1.0,
        model: 'gpt-4-turbo',
      ),
    );

    _embeddings = OpenAIEmbeddings(apiKey: openAiApiKey);

    _loadData().then((value) => _setupRetriever());
  }


  late final Logger _logger = Logger('WannaChatService');

  late final ChatOpenAI _deterministicModel;
  late final ChatOpenAI _creativeModel;
  late final OpenAIEmbeddings _embeddings;
  late final MemoryVectorStore _vectorStore;
  late final RunnableSequence<String, String> _documentRetrievalChain;

  bool ready = false;

  final Map<String, ConversationBufferMemory> _messageHistories = {};

  // --------------------
  // API
  // --------------------

  Future<String> askQuestion({required String question, required String sessionId}) async {
    final result = await _setupFinalAnswerChain(sessionId).invoke(question);

    // Save history
    final memory = _getMessageHistoryForSession(sessionId);
    await memory.saveContext(
      inputValues: {'input': question},
      outputValues: {'output': result},
    );

    return result;
  }

  Stream<String> askQuestionStreamed({required String question, required String sessionId}) {
    return _setupFinalAnswerChain(sessionId).stream(question);
  }

  void saveHistory({required String question, required String result, required String sessionId}) {
    // Save history
    final memory = _getMessageHistoryForSession(sessionId);
    memory.saveContext(
      inputValues: {'input': question},
      outputValues: {'output': result},
    );
  }

  void clearHistory({required String sessionId}) {
    _logger.fine('Clearing history for session $sessionId');
    _messageHistories.remove(sessionId);
  }

  Future<List<WannaChatMessage>> getHistory({required String sessionId}) async {
    final messages = await _messageHistories[sessionId]?.chatHistory.getChatMessages() ?? [];
    final filtered = messages.map((msg) {
      if (msg is HumanChatMessage) {
        return WannaChatMessage.human(message: msg.contentAsString);
      } else if (msg is AIChatMessage) {
        return WannaChatMessage.ai(message: msg.contentAsString);
      } else {
        return null;
      }
    });
    if (filtered.isNotEmpty) {
      _logger.fine('Returning ${filtered.length} messages for session $sessionId');
      return filtered.whereNotNull().toList();
    } else {
      _logger.fine('No messages found for session $sessionId');
      return [WannaChatMessage.ai(message: _welcomeMessage.replaceAll('{name}', sessionId))];
    }
  }

  // Setup document retrieval chain

  Future<void> _loadData() async {
    _logger.fine('Loading file documents (${_documentFileNames.length})...');
    final List<Document> documents = [];
    for (final fileName in _documentFileNames) {
      documents.addAll(await TextLoader(fileName).load());
    }

    _logger.fine('Splitting data (${documents.length} docs)...');
    const textSplitter = RecursiveCharacterTextSplitter(chunkSize: 1536, chunkOverlap: 128);
    final splitDocs = textSplitter.splitDocuments(documents);

    final textsWithSources = splitDocs
        .mapIndexed(
          (i, d) => d.copyWith(
            metadata: {
              ...d.metadata,
              'source': '$i-pl',
            },
          ),
        )
        .toList(growable: false);

    _vectorStore = await MemoryVectorStore.fromDocuments(
      documents: textsWithSources,
      embeddings: _embeddings,
    );
  }

  Future<void> _setupRetriever() async {
    final retriever = _vectorStore.asRetriever();

    /// Setup document retrieval chain
    _logger.fine('Setting up document retrieval chain...');
    final convertDocsToString = Runnable.mapInput<List<Document>, String>((documents) {
      final docs = documents.map((document) => '<doc>\n${document.pageContent}\n</doc>').join('\n');
      final info = documents.map((document) => '${document.id} (${document.metadata})').join(',');
      _logger.fine('Using documents: $info');
      return docs;
    });

    _documentRetrievalChain = retriever.pipe(convertDocsToString);

    _logger.fine('Done setting up');
    ready = true;
  }

  // Memory

  ConversationBufferMemory _getMessageHistoryForSession(String sessionId) {
    return _messageHistories.putIfAbsent(sessionId, () => ConversationBufferMemory(returnMessages: true));
  }

  Runnable<String, RunnableOptions, List<ChatMessage>> _messageHistory(String sessionId) {
    return Runnable.mapInput<String, List<ChatMessage>>(
      (_) async {
        final memory = await _getMessageHistoryForSession(sessionId).loadMemoryVariables();
        final chatMessages = memory[BaseMemory.defaultMemoryKey] as List<ChatMessage>?;
        return chatMessages ?? [];
      },
    );
  }

  // Rephrasing / standalone question

  Runnable<String, RunnableOptions, String> _setupRephraseChain(
      Runnable<String, RunnableOptions, List<ChatMessage>> history) {
    _logger.fine("Adding rephrasing support...");

    String formatChatHistory(List<ChatMessage> chatHistory) {
      final formattedDialogueTurns = chatHistory.map((entry) {
        if (entry is HumanChatMessage) {
          return '${entry.contentAsString}\n';
        }
        return '';
      });
      return formattedDialogueTurns.join();
    }

    final rephraseQuestionChainPrompt = ChatPromptTemplate.fromTemplate(_rephraseQuestionPromptTemplate);

    final chain = Runnable.fromMap<String>({
          'question': Runnable.passthrough(),
          'history': history.pipe(Runnable.mapInput(formatChatHistory)),
        }) |
        rephraseQuestionChainPrompt |
        _logOutput<PromptValue>('rephraseQuestionChainPrompt') |
        _deterministicModel;

    return chain.pipe(const StringOutputParser()); // Using pipe instead of | to get return type right...
  }

  // Final answer chain

  RunnableSequence<String, String> _setupFinalAnswerChain(String sessionId) {
    final hasHistory = _messageHistories.containsKey(sessionId);
    final history = _messageHistory(sessionId);

    /// Answer generation prompt
    final answerGenerationChainPrompt = ChatPromptTemplate.fromTemplates(const [
      (ChatMessageType.system, _finalAnswerPromptTemplate),
      (ChatMessageType.messagesPlaceholder, 'history'),
      (ChatMessageType.human, _answerGenerationPromptTemplate),
    ]);

    /// Rephrase question into standalone question
    final Runnable<String, RunnableOptions, String> rephrasedQuestion =
        hasHistory ? _setupRephraseChain(history) : Runnable.passthrough<String>();

    /// Answer generation chain
    final answerChain =
        rephrasedQuestion |
        _logOutput<String>('rephrase') |
        Runnable.fromMap<String>({
          'history': history,
          'question': Runnable.passthrough(),
          'context':  Runnable.passthrough<String>() | _documentRetrievalChain,
        }) |
        answerGenerationChainPrompt |
        _creativeModel;

    return answerChain.pipe(const StringOutputParser());
  }

  Runnable<T, RunnableOptions, T> _logOutput<T extends Object>(String stepName) {
    return Runnable.mapInput((input) {
      _logger.fine('Result from step "$stepName": $input');
      return input;
    });
  }
}
