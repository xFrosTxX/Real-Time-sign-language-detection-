import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _kDisplayName = 'display_name';
  static const _kProfileImagePath = 'profile_image_path'; // mobile
  static const _kProfileImageBase64 = 'profile_image_base64'; // web

  final ImagePicker _picker = ImagePicker();

  String _displayName = "Guest User";

  // For mobile/desktop
  File? _profileImageFile;

  // For web
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = prefs.getString(_kDisplayName);
    if (savedName != null && savedName.trim().isNotEmpty) {
      _displayName = savedName.trim();
    }

    if (kIsWeb) {
      final b64 = prefs.getString(_kProfileImageBase64);
      if (b64 != null && b64.isNotEmpty) {
        try {
          _profileImageBytes = base64Decode(b64);
        } catch (_) {
          _profileImageBytes = null;
        }
      }
    } else {
      final path = prefs.getString(_kProfileImagePath);
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) _profileImageFile = f;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, name.trim());
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _profileImageBytes = bytes);
        await prefs.setString(_kProfileImageBase64, base64Encode(bytes));
      } else {
        setState(() => _profileImageFile = File(image.path));
        await prefs.setString(_kProfileImagePath, image.path);
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not pick image: $e")),
      );
    }
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      await prefs.remove(_kProfileImageBase64);
      setState(() => _profileImageBytes = null);
    } else {
      await prefs.remove(_kProfileImagePath);
      setState(() => _profileImageFile = null);
    }
  }

  Future<void> _editNameDialog() async {
    final controller = TextEditingController(text: _displayName);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: "Enter your name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context, newName);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => _displayName = result.trim());
      await _saveName(result.trim());
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (!kIsWeb)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Tip: On web, camera capture is not reliable in all browsers.\nUse Gallery for best results.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if ((kIsWeb && _profileImageBytes != null) ||
                (!kIsWeb && _profileImageFile != null))
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _avatarProvider() {
    // Web: show bytes
    if (kIsWeb && _profileImageBytes != null) {
      return MemoryImage(_profileImageBytes!);
    }
    // Mobile/desktop: show file
    if (!kIsWeb && _profileImageFile != null) {
      return FileImage(_profileImageFile!);
    }
    // Fallback
    return const AssetImage('assets/image/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: _avatarProvider(),
                ),
                FloatingActionButton.small(
                  onPressed: _showPhotoOptions,
                  child: const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _editNameDialog,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: "Edit name",
                ),
              ],
            ),
            Text(
              "Personalize your profile by adding a photo and updating your display name.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
