git remote add origin https://github.com/Kanha12-Jane/flutter-khmer25.gitimport 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _localImage;
  final _usernameCtrl = TextEditingController();

  bool _savingUsername = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<ProfileProvider>();
      await p.loadMe(context);
      _usernameCtrl.text = (p.me?["username"] ?? "").toString();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    final netUrl = p.imageUrl;

    ImageProvider? avatarProvider;
    if (_localImage != null) {
      avatarProvider = FileImage(_localImage!);
    } else if (netUrl != null && netUrl.isNotEmpty) {
      avatarProvider = NetworkImage(
        "$netUrl?v=${DateTime.now().millisecondsSinceEpoch}",
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: ListView(
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
                    onTap: _uploadingImage
                        ? null
                        : () async {
                            final file = await context
                                .read<ProfileProvider>()
                                .pickImage();
                            if (file == null) return;
                            setState(() => _localImage = file);
                          },
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
              child: Text(p.error!, style: const TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 16),

          TextField(
            controller: _usernameCtrl,
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
            onPressed: _savingUsername
                ? null
                : () async {
                    final username = _usernameCtrl.text.trim();
                    if (username.isEmpty) return;

                    setState(() => _savingUsername = true);
                    final ok = await context
                        .read<ProfileProvider>()
                        .updateUsername(context, username);
                    if (ok)
                      await context.read<ProfileProvider>().loadMe(context);
                    if (!mounted) return;
                    setState(() => _savingUsername = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? "Username updated ✅"
                              : (p.error ?? "Update failed"),
                        ),
                      ),
                    );
                  },
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
            onPressed: _uploadingImage
                ? null
                : () async {
                    if (_localImage == null) return;

                    setState(() => _uploadingImage = true);
                    final ok = await context
                        .read<ProfileProvider>()
                        .uploadProfileImage(context, _localImage!);
                    if (ok) setState(() => _localImage = null);

                    if (!mounted) return;
                    setState(() => _uploadingImage = false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? "Profile image updated ✅"
                              : (p.error ?? "Upload failed"),
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
