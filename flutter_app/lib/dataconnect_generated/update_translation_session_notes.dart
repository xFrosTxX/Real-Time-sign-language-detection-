part of 'generated.dart';

class UpdateTranslationSessionNotesVariablesBuilder {
  String id;
  Optional<String> _notes = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateTranslationSessionNotesVariablesBuilder notes(String? t) {
   _notes.value = t;
   return this;
  }

  UpdateTranslationSessionNotesVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdateTranslationSessionNotesData> dataDeserializer = (dynamic json)  => UpdateTranslationSessionNotesData.fromJson(jsonDecode(json));
  Serializer<UpdateTranslationSessionNotesVariables> varsSerializer = (UpdateTranslationSessionNotesVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTranslationSessionNotesData, UpdateTranslationSessionNotesVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTranslationSessionNotesData, UpdateTranslationSessionNotesVariables> ref() {
    UpdateTranslationSessionNotesVariables vars= UpdateTranslationSessionNotesVariables(id: id,notes: _notes,);
    return _dataConnect.mutation("UpdateTranslationSessionNotes", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTranslationSessionNotesTranslationSessionUpdate {
  final String id;
  UpdateTranslationSessionNotesTranslationSessionUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTranslationSessionNotesTranslationSessionUpdate otherTyped = other as UpdateTranslationSessionNotesTranslationSessionUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTranslationSessionNotesTranslationSessionUpdate({
    required this.id,
  });
}

@immutable
class UpdateTranslationSessionNotesData {
  final UpdateTranslationSessionNotesTranslationSessionUpdate? translationSession_update;
  UpdateTranslationSessionNotesData.fromJson(dynamic json):
  
  translationSession_update = json['translationSession_update'] == null ? null : UpdateTranslationSessionNotesTranslationSessionUpdate.fromJson(json['translationSession_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTranslationSessionNotesData otherTyped = other as UpdateTranslationSessionNotesData;
    return translationSession_update == otherTyped.translationSession_update;
    
  }
  @override
  int get hashCode => translationSession_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (translationSession_update != null) {
      json['translationSession_update'] = translationSession_update!.toJson();
    }
    return json;
  }

  UpdateTranslationSessionNotesData({
    this.translationSession_update,
  });
}

@immutable
class UpdateTranslationSessionNotesVariables {
  final String id;
  late final Optional<String>notes;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTranslationSessionNotesVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    notes = Optional.optional(nativeFromJson, nativeToJson);
    notes.value = json['notes'] == null ? null : nativeFromJson<String>(json['notes']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTranslationSessionNotesVariables otherTyped = other as UpdateTranslationSessionNotesVariables;
    return id == otherTyped.id && 
    notes == otherTyped.notes;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, notes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(notes.state == OptionalState.set) {
      json['notes'] = notes.toJson();
    }
    return json;
  }

  UpdateTranslationSessionNotesVariables({
    required this.id,
    required this.notes,
  });
}

