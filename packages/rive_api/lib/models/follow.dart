import 'package:utilities/deserialize.dart';

/// Model for a user that the user is following
/// Opposite of follower
class RiveFollowee {
  const RiveFollowee(this.ownerId, this.name, this.username);
  final int ownerId;
  final String name;
  final String username;

  static Iterable<RiveFollowee> fromDataList(
          List<Map<String, dynamic>> dataList) =>
      dataList.map<RiveFollowee>((data) => RiveFollowee.fromData(data));

  factory RiveFollowee.fromData(Map<String, dynamic> data) {
    return RiveFollowee(
      data.getInt('id'),
      data.getString('nm'),
      data.getString('un'),
    );
  }
}

/*

{"artists":[{"id":40843,"np":0,"nf":1,"p1":null,"p2":null,"s1":null,"s2":null,"un":"maxmaxmax","nm":"max","av":null,"bg":null,"bl":"{\"object\":\"value\",\"document\":{\"object\":\"document\",\"data\":{},\"nodes\":[{\"object\":\"block\",\"type\":\"p\",\"data\":{},\"nodes\":[{\"object\":\"text\",\"leaves\":[{\"object\":\"leaf\",\"text\":\"\",\"marks\":[]}]}]}]}}","fl":1,"fh":0},{"id":40836,"np":0,"nf":1,"p1":null,"p2":null,"s1":null,"s2":null,"un":"pollux","nm":"Guido Rosso","av":"https://cdn.2dimensions.com/avatars/40836-1-1570241275-krypton","bg":null,"bl":"{\"object\":\"value\",\"document\":{\"object\":\"document\",\"data\":{},\"nodes\":[{\"object\":\"block\",\"type\":\"p\",\"data\":{},\"nodes\":[{\"object\":\"text\",\"leaves\":[{\"object\":\"leaf\",\"text\":\"\",\"marks\":[]}]}]}]}}","fl":1,"fh":0},{"id":40842,"np":11,"nf":2,"p1":1,"p2":2,"s1":null,"s2":null,"un":"matt","nm":"Matt","av":null,"bg":null,"bl":"{\"object\":\"value\",\"document\":{\"object\":\"document\",\"data\":{},\"nodes\":[{\"object\":\"block\",\"type\":\"p\",\"data\":{},\"nodes\":[{\"object\":\"text\",\"leaves\":[{\"object\":\"leaf\",\"text\":\"\",\"marks\":[]}]}]}]}}","fl":1,"fh":0}],"next":1587165474}

*/
