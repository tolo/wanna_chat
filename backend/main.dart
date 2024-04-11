import 'dart:io';
import 'dart:developer';

import 'package:dart_frog/dart_frog.dart';
import 'package:logging/logging.dart';
import 'package:wanna_chat_server/chat_service.dart';

late final WannaChatService wannaChatService;

Future<void> init(InternetAddress ip, int port) async {
  // Any code initialized within this method will only run on server start, any hot reloads
  // afterwards will not trigger this method until a hot restart.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log('${record.level.name}: ${record.time}: ${record.message}');
    //print('${record.level.name}: ${record.time}: ${record.message}'); // ignore: avoid_print
  });

  wannaChatService = WannaChatService();
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final Handler rootHandler = handler.use(provider<WannaChatService>((_) => wannaChatService));
  return serve(rootHandler, ip, port);
}
