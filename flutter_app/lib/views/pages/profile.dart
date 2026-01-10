import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final ImagePicker _picker = ImagePicker();

  String _displayName = "Guest User";

  File? _profileImageFile; // mobile
  Uint8List? _profileImageBytes; // web

  String _nameKey(String uid) => 'display_name_$uid';
  String _imgPathKey(String uid) => 'profile_image_path_$uid';
  String _imgB64Key(String uid) => 'profile_image_base64_$uid';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // ✅ Username from Firestore
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection("users").doc(uid).get();
        final username = doc.data()?["username"];

        if (username != null && username.toString().trim().isNotEmpty) {
          _displayName = username.toString().trim();
          await prefs.setString(_nameKey(uid), _displayName); // cache
        } else {
          final cached = prefs.getString(_nameKey(uid));
          if (cached != null && cached.trim().isNotEmpty) {
            _displayName = cached.trim();
          }
        }
      } catch (_) {
        final cached = prefs.getString(_nameKey(uid));
        if (cached != null && cached.trim().isNotEmpty) {
          _displayName = cached.trim();
        }
      }
    }

    // ✅ Photo locally (FREE)
    if (uid != null) {
      if (kIsWeb) {
        final b64 = prefs.getString(_imgB64Key(uid));
        if (b64 != null && b64.isNotEmpty) {
          try {
            _profileImageBytes = base64Decode(b64);
          } catch (_) {
            _profileImageBytes = null;
          }
        }
      } else {
        final path = prefs.getString(_imgPathKey(uid));
        if (path != null && path.isNotEmpty) {
          final f = File(path);
          if (await f.exists()) _profileImageFile = f;
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveName(String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newName = name.trim();
    if (newName.isEmpty) return;

    // Save online
    await FirebaseFirestore.instance.collection("users").doc(uid).set(
      {"username": newName},
      SetOptions(merge: true),
    );

    // Cache locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey(uid), newName);
  }

  Future<void> _pickFromGallery() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() => _profileImageBytes = bytes);
      await prefs.setString(_imgB64Key(uid), base64Encode(bytes));
    } else {
      setState(() => _profileImageFile = File(image.path));
      await prefs.setString(_imgPathKey(uid), image.path);
    }
  }

  Future<void> _removePhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      await prefs.remove(_imgB64Key(uid));
      setState(() => _profileImageBytes = null);
    } else {
      await prefs.remove(_imgPathKey(uid));
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
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if ((kIsWeb && _profileImageBytes != null) ||
                (!kIsWeb && _profileImageFile != null))
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Remove Photo"),
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

  Widget _avatarWidget() {
    if (kIsWeb && _profileImageBytes != null) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: MemoryImage(_profileImageBytes!),
      );
    }
    if (!kIsWeb && _profileImageFile != null) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: FileImage(_profileImageFile!),
      );
    }

    return const CircleAvatar(
      radius: 55,
      child: Icon(Icons.person, size: 55),
    );
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
                _avatarWidget(), //
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
              "Add a photo and update your username anytime.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
