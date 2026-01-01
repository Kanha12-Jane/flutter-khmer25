import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Uint8List? _localImageBytes;
  String? _localImageName;

  final _usernameCtrl = TextEditingController();
  bool _savingUsername = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<ProfileProvider>();
      await p.loadMe(context);
      if (!mounted) return;
      _usernameCtrl.text = (p.me?["username"] ?? "").toString();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final p = context.read<ProfileProvider>();

    // Clear old error UI by refreshing provider state (optional)
    // If you don't want this, remove it.
    // p.clearError(); // (only if you implement clearError)

    final picked = await p.pickImageBytes();
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      _localImageBytes = picked.bytes;
      _localImageName = picked.name;
    });
  }

  Future<void> _saveUsername() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) return;

    setState(() => _savingUsername = true);

    final p = context.read<ProfileProvider>();
    final ok = await p.updateUsername(context, username);

    if (ok) {
      await p.loadMe(context);
    }

    if (!mounted) return;
    setState(() => _savingUsername = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Username updated ✅" : (p.error ?? "Update failed")),
      ),
    );
  }

  Future<void> _saveImage() async {
    if (_localImageBytes == null) return;

    setState(() => _uploadingImage = true);

    final p = context.read<ProfileProvider>();
    final ok = await p.uploadProfileImageBytes(
      context,
      bytes: _localImageBytes!,
      filename: _localImageName ?? "profile.jpg",
    );

    if (ok) {
      // clear local preview + reload profile
      if (mounted) {
        setState(() {
          _localImageBytes = null;
          _localImageName = null;
        });
      }
      await p.loadMe(context);
    }

    if (!mounted) return;
    setState(() => _uploadingImage = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? "Profile image updated ✅" : (p.error ?? "Upload failed"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    final netUrl = p.imageUrl;

    final bool busy = p.isLoading || _savingUsername || _uploadingImage;

    ImageProvider? avatarProvider;
    if (_localImageBytes != null) {
      avatarProvider = MemoryImage(_localImageBytes!);
    } else if (netUrl != null && netUrl.isNotEmpty) {
      // cache-busting so web shows new image after upload
      avatarProvider = NetworkImage(
        "$netUrl?v=${DateTime.now().millisecondsSinceEpoch}",
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? const Icon(Icons.person, size: 55)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: (_uploadingImage || p.isLoading)
                            ? null
                            : _pickImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          child: const Icon(
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

              const SizedBox(height: 18),

              if (p.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    p.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),

              TextField(
                controller: _usernameCtrl,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              ElevatedButton.icon(
                icon: _savingUsername
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_savingUsername ? "Saving..." : "Save Username"),
                onPressed: busy ? null : _saveUsername,
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                icon: _uploadingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_uploadingImage ? "Uploading..." : "Save Image"),
                onPressed: (busy || _localImageBytes == null)
                    ? null
                    : _saveImage,
              ),

              if (_localImageBytes == null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Pick an image first to enable upload.",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
            ],
          ),

          // Optional: simple loading overlay
          if (busy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.05),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
