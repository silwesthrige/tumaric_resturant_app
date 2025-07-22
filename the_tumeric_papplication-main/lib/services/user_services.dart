import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:the_tumeric_papplication/models/user_model.dart';

class UserServices {
  final CollectionReference _userCollection = FirebaseFirestore.instance
      .collection("users");

  // Get user details by ID
  Stream<UserModel?> getUserDetails(String id) {
    return _userCollection.doc(id).snapshots().map((docSnapshot) {
      if (docSnapshot.exists) {
        return UserModel.fromJson(
          docSnapshot.data() as Map<String, dynamic>,
          docSnapshot.id,
        );
      } else {
        return null;
      }
    });
  }

  Future<UserModel?> getCurrentUserDetails() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("No user logged in");
    return null;
  }

  try {
    UserModel? userModel = await UserServices().getUserDetails(user.uid.trim()).first;
    return userModel;
  } catch (e) {
    print("Error getting user details: $e");
    return null;
  }
}
}
