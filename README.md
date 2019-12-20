![](https://github.com/rive-app/binary-buffer-dart/workflows/Dart%20CI/badge.svg)

# Binary Buffer
Includes BinaryWriter and BinaryReader classes.

## Integers
All integers support signed and unsigned read/write.
- 8 bit
- 16 bit
- 32 bit
- 64 bit
- variable bit [LEB128](https://en.wikipedia.org/wiki/LEB128) encoded 

## Floating Point
- 32 bit
- 64 bit

## Strings
Strings utf8 encoded with a variable length unsigned integer written before the encoded string representing the number of bytes in the string.

```dart
var writer = BinaryWriter();
writer.writeVarUint(10);
writer.writeString("Node");
writer.writeFloat32(22.100000381469727);
writer.writeFloat32(129.3000030517578);
writer.writeInt32(1920);

var reader = BinaryReader(writer.buffer);
expect(reader.readVarInt(), 10);
expect(reader.readString(), "Node");
expect(reader.readFloat32(), 22.100000381469727);
expect(reader.readFloat32(), 129.3000030517578);
expect(reader.readInt32(), 1920);
```
