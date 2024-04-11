import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:logging/logging.dart';
import 'package:shared_model/shared_model.dart';

import 'package:wanna_chat_server/chat_service.dart';

Logger _logger = Logger('WannaChatAPI');

Future<Response> onRequest(RequestContext context, String sessionId) async {
  final service = context.read<WannaChatService>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _restoreHistory(context, service, sessionId);
    case HttpMethod.post:
      return _question(context, service, sessionId);
    case HttpMethod.delete:
      return _clearHistory(context, service, sessionId);
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.put:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // service.clearHistory(sessionId: sessionId);
  // return Response(
  //   headers: {'Content-type': 'application/json'},
  //   body: jsonEncode({
  //     'answer': response,
  //   }),
  // );
}

Future<Response> _restoreHistory(RequestContext context, WannaChatService service, String sessionId) async {
  final history = await service.getHistory(sessionId: sessionId);
  return Response(
    headers: {'Content-type': 'application/json'},
    body: jsonEncode({
      'history': history,
    }),
  );
}

Future<Response> _question(RequestContext context, WannaChatService service, String sessionId) async {
  if (!service.ready) {
    return Response(statusCode: HttpStatus.serviceUnavailable);
  }

  final body = await context.request.body();
  final payload = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
  // TODO: Add support for cancelling the previous question

  _logger.fine('($sessionId) Received question: "$payload"');

  if (payload.isNotEmpty) {
    final streamed = payload['stream'] as bool? ?? false;
    final question = WannaChatMessage.fromJson(payload);
    if (streamed) {
      final response = service.askQuestionStreamed(
        question: question.message,
        sessionId: sessionId,
      );

      String resultString = '';
      final resultStream = StreamController<Uint8List>();
      response.listen((event) {
        print('DATA: $event');
        resultString += event;
        resultStream.add(utf8.encode(event));
      }, onDone: () {
        service.saveHistory(question: question.message, result: resultString, sessionId: sessionId);
        resultStream.close();
      }, onError: (Object e) {
        resultStream.addError(e);
        resultStream.close();
      });

      return Response.stream(
        body: resultStream.stream,
        bufferOutput: false,
      );
    } else {
      final response = await service.askQuestion(
        question: question.message,
        sessionId: sessionId,
      );

      return Response(
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({
          'answer': WannaChatMessage.ai(message: response),
        }),
      );
    }
  }
  return Response(
    statusCode: 400,
    headers: {'Content-type': 'application/json'},
    body: 'Bad request: Missing "question" and "session_id" in request body',
  );
}

Future<Response> _clearHistory(RequestContext context, WannaChatService service, String sessionId) async {
  service.clearHistory(sessionId: sessionId);
  return Response();
}
