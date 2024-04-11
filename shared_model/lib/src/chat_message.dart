import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class WannaChatMessage {
  final MessageType type;
  final String message;

  final bool _loading;
  bool get isAi => type == MessageType.ai;
  bool get isAiLoading => isAi && _loading;
  bool get isHuman => type == MessageType.human;

  WannaChatMessage({required this.type, required this.message}) : _loading = false;
  WannaChatMessage.ai({required this.message}) : _loading = false, type = MessageType.ai;
  WannaChatMessage.aiLoading() : _loading = true, type = MessageType.ai, message = '';
  WannaChatMessage.human({required this.message}) : _loading = false, type = MessageType.human;

  WannaChatMessage appendMessage(String partialMessage) {
    return WannaChatMessage(type: type, message: message + partialMessage);
  }

  static WannaChatMessage fromJson(Map<String, dynamic> json) => _$WannaChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WannaChatMessageToJson(this);
}

enum MessageType {
  human,
  ai,
}
