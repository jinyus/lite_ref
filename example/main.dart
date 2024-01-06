// ignore_for_file: avoid_print

import 'package:lite_ref/lite_ref.dart';

class Database {
  Database(this.connectionString);

  final Map<String, dynamic> _cache = {};
  final String connectionString;

  Future<void> save(String key, dynamic value) async {
    return _cache[key] = value;
  }

  Future<dynamic> get(String key) async {
    return _cache[key];
  }
}

class UserService {
  UserService({required this.database});

  final Database database;

  Future<void> saveUser(String name) async {
    return database.save('user', name);
  }

  Future<String> getUser() async {
    return database.get('user') as String;
  }
}

void main() async {
// create a singleton
  final dbRef = Ref.singleton(
    create: () => Database('example-connection-string'),
  );

  final db = dbRef.instance;

// create a transient (always return new instance)
  final userServiceRef = Ref.transient(
    create: () => UserService(database: db),
  );

  final userService = userServiceRef.instance;

  await userService.saveUser('John Doe');

  final user = await userService.getUser();

  print(user); // John Doe
}
