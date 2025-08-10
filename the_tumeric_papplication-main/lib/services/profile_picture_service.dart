import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ProfilePictureService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000, // Limit image size for better performance
        maxHeight: 1000,
        imageQuality: 80, // Compress image quality
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Create a unique filename
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Reference to the profile pictures folder in Firebase Storage
      final Reference storageRef = _storage.ref().child('profile_pictures').child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print("Profile picture uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  // Delete old profile picture from Firebase Storage
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
        final Reference storageRef = _storage.refFromURL(imageUrl);
        await storageRef.delete();
        print("Old profile picture deleted successfully");
      }
    } catch (e) {
      print("Error deleting old profile picture: $e");
      // Don't throw error here as it's not critical if old image deletion fails
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}