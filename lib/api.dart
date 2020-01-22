import 'src/web_service.dart';

Future<void> testRiveApi() async {
  var service = WebService();
  var init = await service.initialize('rive');
  var response =
      await service.get('http://localhost:3000/api/search/ac/artists/lu');
  print("GOT BACK ${response.body}");
}
