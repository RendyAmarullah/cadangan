// appwrite_service.dart
import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static final Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('681aa0b70002469fc157') 
    ..setSelfSigned();

  static final Account account = Account(client);
}
