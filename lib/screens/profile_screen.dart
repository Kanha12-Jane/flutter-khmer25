import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();

    // ✅ when logged in first time, load profile once
    if (auth.isLoggedIn && !_loaded) {
      _loaded = true;
      Future.microtask(() => context.read<ProfileProvider>().loadMe(context));
    }

    // ✅ if logout then allow load again next login
    if (!auth.isLoggedIn) {
      _loaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();

    const fallbackImage =
        "https://img.freepik.com/premium-vector/vector-flat-illustration-grayscale-avatar-user-profile-person-icon-profile-picture-business-profile-woman-suitable-social-media-profiles-icons-screensavers-as-templatex9_719432-1351.jpg";

    final loggedIn = auth.isLoggedIn;
    final me = profile.me;

    final userName = loggedIn
        ? (me == null ? "Loading..." : (me["username"] ?? "User").toString())
        : "Guest";

    final email = loggedIn
        ? (me == null ? "" : (me["email"] ?? "").toString())
        : "";

    final img = (profile.imageUrl != null && profile.imageUrl!.isNotEmpty)
        ? profile.imageUrl!
        : fallbackImage;

    return RefreshIndicator(
      onRefresh: () async => profile.loadMe(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ White card + avatar (old design)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.network(
                    "$img?v=${DateTime.now().millisecondsSinceEpoch}",
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 40),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        profile.isLoading
                            ? "Loading..."
                            : (loggedIn ? "Logged in ✅" : "Guest"),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: loggedIn ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ✅ error box
          if (profile.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profile.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ✅ when not logged in => show login button
          if (!loggedIn)
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("ចូលកម្មវិធី"),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),

          // ✅ when logged in => show options
          if (loggedIn) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit profile"),
              subtitle: const Text("Update username & photo"),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                // refresh when return
                await profile.loadMe(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text("Reload profile"),
              onTap: () => profile.loadMe(context),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                context.read<ProfileProvider>().clear();
              },
            ),
          ],
        ],
      ),
    );
  }
}
