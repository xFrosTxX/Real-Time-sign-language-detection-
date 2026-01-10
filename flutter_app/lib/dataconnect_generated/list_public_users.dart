part of 'generated.dart';

class ListPublicUsersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListPublicUsersVariablesBuilder(this._dataConnect, );
  Deserializer<ListPublicUsersData> dataDeserializer = (dynamic json)  => ListPublicUsersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListPublicUsersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<ListPublicUsersData, void> ref() {
    
    return _dataConnect.query("ListPublicUsers", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListPublicUsersUsers {
  final String id;
  final String displayName;
  final String? photoUrl;
  ListPublicUsersUsers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  displayName = nativeFromJson<String>(json['displayName']),
  photoUrl = json['photoUrl'] == null ? null : nativeFromJson<String>(json['photoUrl']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPublicUsersUsers otherTyped = other as ListPublicUsersUsers;
    return id == otherTyped.id && 
    displayName == otherTyped.displayName && 
    photoUrl == otherTyped.photoUrl;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, displayName.hashCode, photoUrl.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['displayName'] = nativeToJson<String>(displayName);
    if (photoUrl != null) {
      json['photoUrl'] = nativeToJson<String?>(photoUrl);
    }
    return json;
  }

  ListPublicUsersUsers({
    required this.id,
    required this.displayName,
    this.photoUrl,
  });
}

@immutable
class ListPublicUsersData {
  final List<ListPublicUsersUsers> users;
  ListPublicUsersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListPublicUsersUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListPublicUsersData otherTyped = other as ListPublicUsersData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListPublicUsersData({
    required this.users,
  });
}

