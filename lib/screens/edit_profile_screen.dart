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

  // =========================
  // UI Helpers (Professional)
  // =========================
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String text,
    required bool loading,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    final canPress = enabled && !loading && onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: canPress ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                loading ? "Please wait..." : text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _softButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, color: color),
        label: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: color.withOpacity(.08),
          side: BorderSide(color: color.withOpacity(.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final p = context.read<ProfileProvider>();
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
      avatarProvider = NetworkImage(
        "$netUrl?v=${DateTime.now().millisecondsSinceEpoch}",
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FC), Color(0xFFF2F5FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.10),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? const Icon(Icons.person, size: 56)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: InkWell(
                                onTap: (busy) ? null : _pickImage,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2563EB),
                                        Color(0xFF7C3AED),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
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
                      const SizedBox(height: 12),
                      Text(
                        _localImageBytes != null
                            ? "Selected: ${_localImageName ?? "image"}"
                            : "Tap camera to choose image",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (p.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(.18)),
                    ),
                    child: Text(
                      p.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _sectionTitle("Username"),
                _card(
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameCtrl,
                        enabled: !busy,
                        decoration: InputDecoration(
                          labelText: "Username",
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _gradientButton(
                        icon: Icons.save,
                        text: "Save Username",
                        loading: _savingUsername,
                        enabled: !busy,
                        onPressed: _saveUsername,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _sectionTitle("Profile Image"),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _gradientButton(
                        icon: Icons.cloud_upload,
                        text: "Save Image",
                        loading: _uploadingImage,
                        enabled: !busy && _localImageBytes != null,
                        onPressed: (_localImageBytes == null)
                            ? null
                            : _saveImage,
                      ),
                      if (_localImageBytes == null) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Pick an image first to enable upload.",
                          style: TextStyle(
                            color: Colors.black.withOpacity(.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _softButton(
                        icon: Icons.photo_library_outlined,
                        text: "Choose another image",
                        color: const Color(0xFF2563EB),
                        enabled: !busy,
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
              ],
            ),

            // ✅ Loading overlay (only when truly busy)
            if (busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
