import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_tumeric_papplication/models/user_model.dart'; // Adjust path
import 'package:the_tumeric_papplication/services/user_services.dart'; // Adjust path
import 'package:the_tumeric_papplication/services/profile_picture_service.dart'; // Add this import

class ProfileDetailsPage extends StatefulWidget {
  final UserModel?
  currentUser; // Make it nullable as it might be loading or null

  const ProfileDetailsPage({Key? key, this.currentUser}) : super(key: key);

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final UserServices _userServices = UserServices();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isSaving = false; // To show loading indicator on save button
  bool _isUploadingImage = false; // To show loading indicator for image upload
  String? _currentProfileImageUrl; // Track current profile image URL

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data or empty strings
    _nameController = TextEditingController(
      text: widget.currentUser?.name ?? '',
    );
    _emailController = TextEditingController(
      text: widget.currentUser?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.currentUser?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.currentUser?.address ?? '',
    );
    _currentProfileImageUrl = widget.currentUser?.profileImageUrl;
  }

  Future<void> _changeProfilePicture() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _profilePictureService
          .showImageSourceDialog(context);
      if (source == null) return;

      // Pick image
      final File? imageFile = await _profilePictureService.pickImage(
        source: source,
      );
      if (imageFile == null) return;

      setState(() {
        _isUploadingImage = true;
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
      if (_currentProfileImageUrl != null &&
          _currentProfileImageUrl!.isNotEmpty) {
        await _profilePictureService.deleteProfilePicture(
          _currentProfileImageUrl!,
        );
      }

      // Upload new image
      final String? downloadUrl = await _profilePictureService
          .uploadProfilePicture(imageFile);

      if (downloadUrl != null && widget.currentUser != null) {
        // Update user profile in Firestore
        await _userServices.updateProfilePicture(
          widget.currentUser!.uID,
          downloadUrl,
        );

        if (mounted) {
          // Hide loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Update local state
          setState(() {
            _currentProfileImageUrl = downloadUrl;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      if (widget.currentUser == null) {
        // This case indicates no logged-in user or data not fetched
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save profile: User data not available.'),
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final updatedUser = widget.currentUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        profileImageUrl:
            _currentProfileImageUrl, // Include the updated profile image URL
      );

      try {
        await _userServices.updateUserDetails(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          // Return true to the previous page (ProfilePage) to indicate data refresh is needed
          Navigator.pop(context, true);
        }
      } catch (e) {
        print("Failed to update profile: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section with Edit Functionality
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _currentProfileImageUrl != null
                              ? NetworkImage(_currentProfileImageUrl!)
                              : const AssetImage('assets/images/profile.jpg')
                                  as ImageProvider,
                      backgroundColor: Colors.grey,
                      child:
                          _currentProfileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                          child:
                              _isUploadingImage
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Form Fields
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
              ),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                readOnly: true, // Often email should not be editable here
              ),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_isSaving || _isUploadingImage) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),

              const SizedBox(height: 10),

              // Information text
              if (_isUploadingImage)
                const Text(
                  'Please wait while your profile picture is being uploaded...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false, // Added readOnly parameter
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly, // Apply readOnly
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange),
          ),
          filled: readOnly, // Grey out if readOnly
          fillColor: readOnly ? Colors.grey[200] : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Email' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
