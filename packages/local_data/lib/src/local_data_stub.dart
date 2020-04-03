import '../local_data.dart';

LocalData makeLocalData(LocalDataPlatform platform, String context) =>
    throw UnsupportedError(
        '''Cannot create a local data object without the packages '''
        '''dart:html or dart:io''');

LocalDataPlatform makeLocalDataPlatform() => throw UnsupportedError(
    '''Cannot create a local data platform object without the packages '''
    '''dart:html or dart:io''');
