abstract class SerDes<T> {
  const SerDes();
  String serializeJson(T value);
  T deserializeJson(Object value);
  Object serializeMemory(T value);
  Object deserializeMemory(T value);
  // Need to add binary...
}
