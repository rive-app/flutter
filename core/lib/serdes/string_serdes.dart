import '../serdes.dart';

class StringSerDes extends SerDes<String> {
  @override
  String deserializeJson(Object value) {
    return "";
  }

  @override
  Object deserializeMemory(String value) {
    return value;
  }

  @override
  String serializeJson(String value) {
    return value.toString();
  }

  @override
  Object serializeMemory(String value) {
    return value;
  }
}