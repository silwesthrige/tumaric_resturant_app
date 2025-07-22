import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_tumeric_papplication/models/user_model.dart'; // Adjust path

class UserServices {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection("users");

  // Get user details by ID (Stream for real-time updates)
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

  // Get current user details (Future for one-time fetch)
  Future<UserModel?> getCurrentUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("No user logged in.");
      return null;
    }

    try {
      // Using .first on the stream converts it to a Future, getting the first emitted value
      UserModel? userModel = await getUserDetails(user.uid).first;
      return userModel;
    } catch (e) {
      print("Error getting current user details: $e");
      return null;
    }
  }

  // Update user details in Firestore
  Future<void> updateUserDetails(UserModel userModel) async {
    try {
      await _userCollection.doc(userModel.uID).update(userModel.toJson());
      print("User details updated successfully for ID: ${userModel.uID}");
    } catch (e) {
      print("Error updating user details for ID: ${userModel.uID}, Error: $e");
      rethrow; // Re-throw the error for the UI to handle
    }
  }

  // Example: update only specific fields
  Future<void> updateSpecificUserDetails(
      String userId, Map<String, dynamic> data) async {
    try {
      await _userCollection.doc(userId).update(data);
      print("Specific user details updated successfully for ID: $userId");
    } catch (e) {
      print("Error updating specific user details for ID: $userId, Error: $e");
      rethrow;
    }
  }
}
