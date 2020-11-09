import 'package:http/http.dart';

final successLogoutResponse = Response("", 302);

final successMeResponse = Response("""
{
  "signedIn":true,
  "id":40839,
  "ownerId":40839,
  "name":"MaxMax",
  "username":"maxmax",
  "avatar":null,
  "isAdmin":false,
  "isPaid":false,
  "notificationCount":5,
  "verified":true
}
""", 200);

final failureMeResponse = Response('{"signedIn":false}', 200);

final successTeamsResponse = Response("""
[{
    "ownerId": 41545,
    "name": "Team Titans",
    "username": "team_titans",
    "avatar": "https://cdn.2dimensions.com/avatars/krypton-41545-b131305f-6aba-4fe5-b797-a10035143fa0",
    "permission": "Owner",
    "status": "ACTIVE"
}, {
    "ownerId": 41576,
    "name": "Avengers",
    "username": "avengers_101",
    "avatar": null,
    "permission": "Member",
    "status": "ACTIVE"
}]
""", 200);

final successTeamAffiliatesResponse = Response("""
[{
    "ownerId":40944,
    "username":"foofoo",
    "name":null,
    "status":"complete",
    "permission":"Owner",
    "avatar":null
},{
    "ownerId":41594,
    "username":"mightymax",
    "name":null,
    "status":"pending",
    "permission":"Member",
    "avatar":null}]
""", 200);

final successSearchResponse = Response("""
[{
    "n": "Mike",
    "i": 40981,
    "l": null,
    "a": null
}, {
    "n": "pollux",
    "i": 40836,
    "l": "Guido Rosso",
    "a": "https://cdn.2dimensions.com/avatars/40836-1-1570241275-krypton"
}, {
    "n": "castor",
    "i": 16479,
    "l": "Luigi Rosso",
    "a": "https://cdn.2dimensions.com/avatars/16479-1-1547266294-krypton"
}]""", 200);

final successFoldersResponse = Response("""
[{
    "id": 12,
    "name": "Your Files",
    "parent": null,
    "order": 0
}, {
    "id": 19,
    "name": "New Folder",
    "parent": 1,
    "order": 0
}, {
    "id": 18,
    "name": "New Folder",
    "parent": 0,
    "order": 0
}]
""", 200);

final successTeamFoldersResponse = Response("""
[{
    "id": 3,
    "name": "Some files",
    "parent": null,
    "order": 0,
    "project_name": "default",
    "project_owner_id": 3
}, {
    "id": 4,
    "name": "More files",
    "parent": null,
    "order": 1,
    "project_name": "default",
    "project_owner_id": 3
}]
""", 200);

final successFilesResponse = Response("""
[
11,
12,
13,
14,
15,
16,
17,
18,
19,
20,
3,
21,
22,
23,
24,
25
]""", 200);

final successRecentFilesResponse = Response("""
[
1,
2,
4
]""", 200);

final successFileDetailsResponse = Response("""
{
  "cdn": {
    "1" : {
      "base": "http://foofo.com/",
      "params": "?param"
    }
  },
  "files":[ {
    "id":1,
    "oid":1,
    "name":"New File",
    "thumbnail":"<thumbnail>"
  }, {
    "id":2,
    "oid":1,
    "name":"New File 2",
    "thumbnail":"<thumbnail2>"
  }, {
    "id":3,
    "oid":1,
    "name":"New File 3",
    "thumbnail":"<thumbnail3>"
  }]
}
""", 200);

final successTeamMembersResponse = Response("""
[{
    "ownerId":40836,
    "username":"pollux",
    "name":"Guido Rosso",
    "status":"complete",
    "permission":"Member",
    "avatar":null
}]
""", 200);

final myFoldersResponse = """
{
  "folders": [
    {
      "id": 1,
      "name": "Your Files",
      "parent": null,
      "order": 0
    },
    {
      "id": 2,
      "name": "New Folder",
      "parent": 1,
      "order": 0
    },
    {
      "id": 3,
      "name": "New Folder",
      "parent": 2,
      "order": 0
    },
    {
      "id": 4,
      "name": "New Folder",
      "parent": 2,
      "order": 0
    },
    {
      "id": 0,
      "name": "Deleted Files",
      "parent": null,
      "order": 1
    }
  ],
  "sortOptions": [
    {
      "name": "Recent",
      "route": "/api/my/files/recent/"
    },
    {
      "name": "Oldest",
      "route": "/api/my/files/oldest/"
    },
    {
      "name": "A - Z",
      "route": "/api/my/files/a-z/"
    },
    {
      "name": "Z - A",
      "route": "/api/my/files/z-a/"
    }
  ]
}
""";

const myFilesResponse = '[1,2]';

const myFilesDetailsResponse = """
{
  "cdn": {
    "base": "https://base.rive.app/",
    "params": "riveCDNparams"
  },
  "files": [
    {
      "id": 1,
      "oid": 12345,
      "name": "First file"
    },
    {
      "id": 2,
      "oid": 12345,
      "name": "Prova"
    }
  ]
}
""";

final successFileCreationResponse = Response("""
{
  "file": {
    "oid": 1,
    "name": "New File",
    "id": 10
  }
}
""", 200);

final successFolderCreationResponse = Response("""
{
  "id": 10, 
  "name": "New Folder", 
  "order": 0, 
  "parent": 1
}
""", 200);

final successTeamFolderCreationResponse = Response("""
{
  "id": 10, 
  "name": "New Folder", 
  "project_owner_id": 1,
  "order": 1, 
  "parent": 1
}
""", 200);

final successNotificationsResponse = Response("""
{
  "data": "[{\\"u\\":{\\"oi\\":41594,\\"pf\\":0,\\"un\\":\\"mightymax\\",\\"nm\\":null,\\"av\\":null,\\"fl\\":0,\\"f1\\":null,\\"f2\\":null,\\"bg\\":null,\\"s1\\":null,\\"s2\\":null},\\"t\\":21,\\"w\\":1588426218,\\"m\\":{\\"ti\\":41595,\\"tn\\":\\"bump2\\",\\"ii\\":40952,\\"pn\\":3,\\"av\\":\\"https://cdn.2dimensions.com/avatars/krypton-41595-33953877-8371-46ad-a393-24aaa9767e40\\"}},{\\"u\\":{\\"oi\\":40944,\\"pf\\":0,\\"un\\":\\"foofoo\\",\\"nm\\":null,\\"av\\":\\"https://cdn.2dimensions.com/avatars/40883-7-1585914912-krypton\\",\\"fl\\":0,\\"f1\\":null,\\"f2\\":null,\\"bg\\":null,\\"s1\\":null,\\"s2\\":null},\\"t\\":22,\\"w\\":1587739698,\\"m\\":{\\"ti\\":41576,\\"tn\\":\\"newteam\\",\\"ii\\":40949,\\"pn\\":3}}]",
  "count":2
}
""", 200);

final successProfileMeResponse = Response("""
{
  "name": "John Cleese",
  "username":"mrfawlty",
  "email": "fawlty@towers.app",
  "location": "Torquay",
  "avatar": "https://pbs.twimg.com/profile_images/640910812538896384/LdYOoJzZ_400x400.png",
  "website": "www.fawlty.com",
  "bio": "BritishRiviera",
  "twitter": "fawltytowers_",
  "instagram": "fawltytowers_ig",
  "dribbble": null,
  "linkedin": null,
  "behance": null,
  "vimeo": null,
  "github": null,
  "medium": null,
  "isForHire": false
}
""", 200);

final errorUpdateProfileMeResponse =
    Response('{"username":"bad-characters"}', 422);
