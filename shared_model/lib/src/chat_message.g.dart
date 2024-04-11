// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WannaChatMessage _$WannaChatMessageFromJson(Map<String, dynamic> json) =>
    WannaChatMessage(
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      message: json['message'] as String,
    );

Map<String, dynamic> _$WannaChatMessageToJson(WannaChatMessage instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type]!,
      'message': instance.message,
    };

const _$MessageTypeEnumMap = {
  MessageType.human: 'human',
  MessageType.ai: 'ai',
};
