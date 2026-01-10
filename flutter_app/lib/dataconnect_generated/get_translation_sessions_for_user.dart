part of 'generated.dart';

class GetTranslationSessionsForUserVariablesBuilder {
  String userId;

  final FirebaseDataConnect _dataConnect;
  GetTranslationSessionsForUserVariablesBuilder(this._dataConnect, {required  this.userId,});
  Deserializer<GetTranslationSessionsForUserData> dataDeserializer = (dynamic json)  => GetTranslationSessionsForUserData.fromJson(jsonDecode(json));
  Serializer<GetTranslationSessionsForUserVariables> varsSerializer = (GetTranslationSessionsForUserVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTranslationSessionsForUserData, GetTranslationSessionsForUserVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetTranslationSessionsForUserData, GetTranslationSessionsForUserVariables> ref() {
    GetTranslationSessionsForUserVariables vars= GetTranslationSessionsForUserVariables(userId: userId,);
    return _dataConnect.query("GetTranslationSessionsForUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetTranslationSessionsForUserTranslationSessions {
  final String id;
  final String? sessionName;
  final Timestamp startTime;
  final Timestamp endTime;
  GetTranslationSessionsForUserTranslationSessions.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  sessionName = json['sessionName'] == null ? null : nativeFromJson<String>(json['sessionName']),
  startTime = Timestamp.fromJson(json['startTime']),
  endTime = Timestamp.fromJson(json['endTime']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTranslationSessionsForUserTranslationSessions otherTyped = other as GetTranslationSessionsForUserTranslationSessions;
    return id == otherTyped.id && 
    sessionName == otherTyped.sessionName && 
    startTime == otherTyped.startTime && 
    endTime == otherTyped.endTime;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, sessionName.hashCode, startTime.hashCode, endTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (sessionName != null) {
      json['sessionName'] = nativeToJson<String?>(sessionName);
    }
    json['startTime'] = startTime.toJson();
    json['endTime'] = endTime.toJson();
    return json;
  }

  GetTranslationSessionsForUserTranslationSessions({
    required this.id,
    this.sessionName,
    required this.startTime,
    required this.endTime,
  });
}

@immutable
class GetTranslationSessionsForUserData {
  final List<GetTranslationSessionsForUserTranslationSessions> translationSessions;
  GetTranslationSessionsForUserData.fromJson(dynamic json):
  
  translationSessions = (json['translationSessions'] as List<dynamic>)
        .map((e) => GetTranslationSessionsForUserTranslationSessions.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTranslationSessionsForUserData otherTyped = other as GetTranslationSessionsForUserData;
    return translationSessions == otherTyped.translationSessions;
    
  }
  @override
  int get hashCode => translationSessions.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['translationSessions'] = translationSessions.map((e) => e.toJson()).toList();
    return json;
  }

  GetTranslationSessionsForUserData({
    required this.translationSessions,
  });
}

@immutable
class GetTranslationSessionsForUserVariables {
  final String userId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetTranslationSessionsForUserVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTranslationSessionsForUserVariables otherTyped = other as GetTranslationSessionsForUserVariables;
    return userId == otherTyped.userId;
    
  }
  @override
  int get hashCode => userId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    return json;
  }

  GetTranslationSessionsForUserVariables({
    required this.userId,
  });
}

