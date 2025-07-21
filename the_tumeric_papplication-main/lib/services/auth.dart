import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //create a user firebase

  UserModel? _userWithFirebaseUseruID(User? user) {
    return user != null ? UserModel(uID: user.uid) : null;
  }

  //Create Stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userWithFirebaseUseruID);
  }

  //signin Annoymus
  Future signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userWithFirebaseUseruID(user);
    } catch (err) {
      print(err.toString());
      return null;
    }
  }

  //sign out annonimous
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (err) {
      print(err.toString());
    }
  }

  //register email password
  Future registerToEmailPassword(
    String name,
    String email,
    String password,
    String address,
    String phone,
    List<String> cart,
    List<String> favFoods,
  ) async {
    try {
      // Create user with Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the authentication UID
      String uid = result.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'userId': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'cart': cart.isEmpty ? [] : cart,
        'favFoods': favFoods.isEmpty ? [] : favFoods,
        'createdAt': FieldValue.serverTimestamp(),
      });

      User? user = result.user;
      return _userWithFirebaseUseruID(user);
    } catch (e) {
      print("Registration Error: $e");
      return null;
    }
  }

  //sign in email passowrd
  Future signInEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return _userWithFirebaseUseruID(user);
    } on Exception catch (err) {
      print(err.toString());
      return null;
    }
  }
}
