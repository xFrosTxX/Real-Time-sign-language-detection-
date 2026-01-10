library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'get_translation_sessions_for_user.dart';

part 'update_translation_session_notes.dart';

part 'list_public_users.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser () {
    return CreateUserVariablesBuilder(dataConnect, );
  }
  
  
  GetTranslationSessionsForUserVariablesBuilder getTranslationSessionsForUser ({required String userId, }) {
    return GetTranslationSessionsForUserVariablesBuilder(dataConnect, userId: userId,);
  }
  
  
  UpdateTranslationSessionNotesVariablesBuilder updateTranslationSessionNotes ({required String id, }) {
    return UpdateTranslationSessionNotesVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListPublicUsersVariablesBuilder listPublicUsers () {
    return ListPublicUsersVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'real-time-sign-language-detection',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
