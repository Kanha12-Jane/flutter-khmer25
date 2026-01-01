import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _rePassword = TextEditingController();

  bool _hidePass = true;
  bool _hideRePass = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _rePassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final ok = await auth.register(
      _username.text.trim(),
      _password.text,
      _rePassword.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Register success ✅")));

      // ✅ OPTION: auto login after register (recommended UX)
      // await auth.login(_username.text.trim(), _password.text);

      Navigator.pop(context, true);
      return;
    }

    // ✅ show error if failed
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(auth.error ?? "Register failed")));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (auth.error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Enter username";
                    final ok = RegExp(r'^[\w.@+-]+$').hasMatch(v.trim());
                    if (!ok) return "Use only letters, numbers, @ . + - _";
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                      icon: Icon(
                        _hidePass ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  obscureText: _hidePass,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter password";
                    if (v.length < 8) return "Min 8 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _rePassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hideRePass = !_hideRePass),
                      icon: Icon(
                        _hideRePass ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  obscureText: _hideRePass,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Confirm password";
                    if (v != _password.text) return "Passwords do not match";
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () {
                            FocusScope.of(
                              context,
                            ).unfocus(); // ✅ close keyboard
                            if (_formKey.currentState!.validate()) _submit();
                          },
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
