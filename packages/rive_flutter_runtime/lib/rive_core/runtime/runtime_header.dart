import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:rive/rive_core/runtime/exceptions/rive_unsupported_version_exception.dart';
import 'package:rive/src/utilities/binary_buffer/binary_reader.dart';
import 'exceptions/rive_format_error_exception.dart';

enum RuntimePermissions { allowEditorImport }

class RuntimeHeader {
  static const int majorVersion = 0;
  static const int minorVersion = 1;
  static const String fingerprint = 'RIVE';
  final int ownerId;
  final int fileId;
  final int permissions;
  final Uint8List signature;
  bool hasAccess(RuntimePermissions permission) =>
      (permissions & permission.index) != 0;
  RuntimeHeader(
      {@required this.ownerId,
      @required this.fileId,
      this.permissions = 0,
      this.signature});
  factory RuntimeHeader.read(BinaryReader reader) {
    var fingerprint = RuntimeHeader.fingerprint.codeUnits;
    for (int i = 0; i < fingerprint.length; i++) {
      if (reader.readUint8() != fingerprint[i]) {
        throw const RiveFormatErrorException('Fingerprint doesn\'t match.');
      }
    }
    int readMajorVersion = reader.readVarUint();
    int readMinorVersion = reader.readVarUint();
    if (readMajorVersion > majorVersion) {
      throw RiveUnsupportedVersionException(
          majorVersion, minorVersion, readMajorVersion, readMinorVersion);
    }
    int ownerId = reader.readVarUint();
    int fileId = reader.readVarUint();
    int permissions = reader.readVarUint();
    int signatureLength = reader.readVarUint();
    Uint8List signature;
    if (signatureLength != 0) {
      signature = reader.read(signatureLength);
    }
    return RuntimeHeader(
        ownerId: ownerId,
        fileId: fileId,
        permissions: permissions,
        signature: signature);
  }
}
