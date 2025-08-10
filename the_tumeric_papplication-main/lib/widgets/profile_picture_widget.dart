import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/services/profile_picture_service.dart';
import 'package:the_tumeric_papplication/services/user_services.dart';

class ProfilePictureWidget extends StatefulWidget {
  final UserModel? currentUser;
  final Function(String)? onImageUpdated; // Callback when image is updated

  const ProfilePictureWidget({
    Key? key,
    required this.currentUser,
    this.onImageUpdated,
  }) : super(key: key);

  @override
  _ProfilePictureWidgetState createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final UserServices _userServices = UserServices();
  bool _isUploading = false;

  Future<void> _changeProfilePicture() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _profilePictureService.showImageSourceDialog(context);
      if (source == null) return;

      // Pick image
      final File? imageFile = await _profilePictureService.pickImage(source: source);
      if (imageFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text('Uploading profile picture...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Delete old profile picture if exists
      if (widget.currentUser?.profileImageUrl != null && 
          widget.currentUser!.profileImageUrl!.isNotEmpty) {
        await _profilePictureService.deleteProfilePicture(widget.currentUser!.profileImageUrl!);
      }

      // Upload new image
      final String? downloadUrl = await _profilePictureService.uploadProfilePicture(imageFile);

      if (downloadUrl != null && widget.currentUser != null) {
        // Update user profile in Firestore
        await _userServices.updateProfilePicture(widget.currentUser!.uID, downloadUrl);

        if (mounted) {
          // Hide loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call callback if provided
          if (widget.onImageUpdated != null) {
            widget.onImageUpdated!(downloadUrl);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error changing profile picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile Image
        CircleAvatar(
          radius: 50,
          backgroundImage: widget.currentUser?.profileImageUrl != null
              ? NetworkImage(widget.currentUser!.profileImageUrl!)
              : const AssetImage('assets/images/profile.jpg') as ImageProvider,
          backgroundColor: Colors.white,
          child: widget.currentUser?.profileImageUrl == null
              ? const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey,
                )
              : null,
        ),
        
        // Edit Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploading ? null : _changeProfilePicture,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}