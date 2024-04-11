import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:wanna_chat_server/chat_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final service = context.read<WannaChatService>();

  final body = await context.request.body();
  final payload = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : <String, dynamic>{};
  final question = payload['question']?.toString();
  final sessionId = payload['session_id']?.toString();

  print('($sessionId) Received question: "$question"');

  if (question != null && sessionId != null) {
    final response = await service.askQuestion(
      question: question,
      sessionId: sessionId,
    );

    return Response(
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        'answer': response,
      }),
    );
  }
  return Response(
    statusCode: 400,
    headers: {'Content-type': 'application/json'},
    body: 'Bad request: Missing "question" and "session_id" in request body',
  );
}
