import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:the_tumeric_papplication/models/user_model.dart';

class UserServices {
  final CollectionReference _userCollection = FirebaseFirestore.instance
      .collection("users");

      
}
