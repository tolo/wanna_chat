import 'package:dart_frog/dart_frog.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as shelf;

import 'package:wanna_chat_server/chat_service.dart';

// final _service = WannaChatService();

Handler middleware(Handler handler) {
  return handler
      .use(
        fromShelfMiddleware(
          shelf.corsHeaders(
            headers: {
              shelf.ACCESS_CONTROL_ALLOW_ORIGIN: '*',
              shelf.ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, OPTIONS',
              shelf.ACCESS_CONTROL_ALLOW_HEADERS: '*',
            },
          ),
        ),
      )
      .use(requestLogger());
      // .use(provider<WannaChatService>((_) => _service));
}
