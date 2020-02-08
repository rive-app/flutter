import '../platform.dart';

Platform makePlatform() => throw UnsupportedError(
    '''Cannot create a platform object without the packages '''
    '''dart:html or dart:io''');
