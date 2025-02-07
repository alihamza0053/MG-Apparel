import 'package:gms/screens/credentials/users/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDatabase {
  //database
  final database = Supabase.instance.client.from('users');

  //create
  Future createUser(Users newUser) async {
    await database.insert(newUser.toMap());
  }

  // Read and sort users by ID
  final stream = Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) {
    return data
        .map((userMap) => Users.fromMap(userMap))
        .toList()
      ..sort((a, b) => a.id!.compareTo(b.id!)); // Sorting by ID (Ascending)
  });


  //update
  Future update(Users oldUser, String role,) async {
    await database.update({
      'role': role,

    }).eq('id', oldUser.id!);
  }

  //delete
  Future delete(Users users) async{
    await database.delete().eq('id', users.id!);
  }
}
