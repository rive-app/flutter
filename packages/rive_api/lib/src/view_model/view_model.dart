export 'me.dart';
export 'volume.dart';
export 'directory_tree.dart';
export 'file.dart';

abstract class ViewModel {
  const ViewModel();
  
  @override
  String toString() => description;

  String get description;
}
