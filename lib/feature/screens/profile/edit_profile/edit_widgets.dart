import 'dart:io';
import 'package:flutter/material.dart';

class EditTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;

  const EditTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2D2D),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFFF4081)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileImagePicker extends StatelessWidget {
  final bool isUploading;
  final File? imageFile;
  final String? photoUrl;
  final String? email;
  final VoidCallback onPickImage;

  const ProfileImagePicker({
    super.key,
    required this.isUploading,
    required this.imageFile,
    required this.photoUrl,
    required this.email,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF4081),
              width: 2,
            ),
          ),
          child: isUploading
              ? const CircularProgressIndicator(
                  color: Color(0xFFFF4081),
                )
              : ClipOval(
                  child: Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFFFEBF2),
                    child: imageFile != null
                        ? Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                          )
                        : (photoUrl != null && photoUrl!.isNotEmpty
                            ? (photoUrl!.startsWith('http')
                                ? Image.network(
                                    photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  )
                                : Image.file(
                                    File(photoUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder();
                                    },
                                  ))
                            : _buildPlaceholder()),
                  ),
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onPickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4081),
                shape: BoxShape.circle,
              ),
              child: const Icon(
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

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        email != null && email!.isNotEmpty ? email![0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 40,
          color: Color(0xFFFF4081),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class EditSaveButton extends StatelessWidget {
  final bool isUploading;
  final VoidCallback? onPressed;

  const EditSaveButton({
    super.key,
    required this.isUploading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isUploading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4081),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: const Color(0xFFFF4081).withOpacity(0.4),
      ),
      child: isUploading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
