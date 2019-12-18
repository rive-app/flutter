import '../serdes.dart';

class IntSerDes extends SerDes<int> {
  @override
  int deserializeJson(Object value) {
    return 0;
  }

  @override
  Object deserializeMemory(int value) {
    return value;
  }

  @override
  String serializeJson(int value) {
    return value.toString();
  }

  @override
  Object serializeMemory(int value) {
    return value;
  }
}