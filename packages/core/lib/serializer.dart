abstract class Serializer {
  void openObject(String name);
  void closeObject();
  void writeValue<T>(String name, T value);
}
