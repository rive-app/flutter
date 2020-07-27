import 'package:utilities/binary_buffer/binary_writer.dart';

class RiveHeader {
  static const int _majorVersion = 1;
  static const int _minorVersion = 0;
  static const String _fingerprint = 'RIVE';

  // This converter will keep a 0 file id since it cannot know it ahead of time.
  static const int _fileId = 0;

  static void serialize(BinaryWriter writer, int ownerId) {
    RiveHeader._fingerprint.codeUnits.forEach(writer.writeUint8);
    writer.writeVarUint(RiveHeader._majorVersion);
    writer.writeVarUint(RiveHeader._minorVersion);
    writer.writeVarUint(ownerId);
    writer.writeVarUint(RiveHeader._fileId);
  }
}