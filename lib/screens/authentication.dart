import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'profilefeature.dart';
import 'admin/adminhome.dart';
import 'package:madhubeautystudio/fcm_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isAdminMode = false;
  bool isOtpStage = false;
  bool loading = false;
  bool _autoVerified = false;

  String? errorMsg;

  final phoneController = TextEditingController();
  final adminEmail = TextEditingController();
  final adminPassword = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> _otpDigits =
      List.generate(6, (_) => TextEditingController());

  // =======================
  // SEND OTP (USER)
  // =======================
  Future<void> sendOtp() async {
    final rawPhone = phoneController.text.trim();

    if (rawPhone.length != 10) {
      _showError("Enter valid 10-digit phone number");
      return;
    }

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: "+91$rawPhone",
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (_autoVerified) return;
          _autoVerified = true;

          await _auth.signInWithCredential(credential);
          await _onUserLoginSuccess(isNewUser: true);
        },
        verificationFailed: (e) {
          _showError(e.message ?? "OTP verification failed");
          setState(() => loading = false);
        },
        codeSent: (verificationId, _) {
          setState(() {
            loading = false;
            isOtpStage = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (_) {
      _showError("Failed to send OTP");
      setState(() => loading = false);
    }
  }

  // =======================
  // VERIFY OTP (USER)
  // =======================
  Future<void> verifyOtp() async {
    final otp = _otpDigits.map((c) => c.text).join();

    if (otp.length != 6) {
      _showError("Enter 6-digit OTP");
      return;
    }

    if (_verificationId == null) {
      _showError("Request OTP again");
      return;
    }

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);
      await _onUserLoginSuccess(isNewUser: true);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Invalid OTP");
    } finally {
      setState(() => loading = false);
    }
  }

  // =======================
  // BACKEND USER SYNC
  // =======================
  Future<void> _createUserInBackend(User user) async {
    final phone = user.phoneNumber;
    if (phone == null) return;

    try {
      await http.post(
        Uri.parse(
          "https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod/user",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "createUser",
          "userId": user.uid,
          "phone": phone,
        }),
      );
    } catch (_) {
      // do not block login
    }
  }

  // =======================
  // USER LOGIN SUCCESS
  // =======================
  Future<void> _onUserLoginSuccess({required bool isNewUser}) async {
    final user = _auth.currentUser;
    if (user == null || !mounted) return;

    await _createUserInBackend(user);

    FcmService.registerToken(
      accountId: user.uid,
      isAdmin: false,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialUser: {},
          isNewUser: isNewUser,
        ),
      ),
    );
  }

  // =======================
  // ADMIN LOGIN (FIXED)
  // =======================
  Future<void> adminLogin() async {
    final email = adminEmail.text.trim();
    final pass = adminPassword.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError("Enter email & password");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse(
          "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/login",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": pass}),
      );

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      if (res.statusCode == 200 && data["token"] != null) {
        final prefs = await SharedPreferences.getInstance();

        // 🔐 persist admin session
        await prefs.setBool("isAdmin", true);
        await prefs.setString("adminToken", data["token"]);
        await prefs.setInt(
          "adminLoginAt",
          DateTime.now().millisecondsSinceEpoch,
        );

        FcmService.registerToken(
          accountId: email,
          isAdmin: true,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else {
        _showError(data["error"] ?? "Login failed");
      }
    } catch (_) {
      _showError("Network error");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // =======================
  // ERROR HANDLER (MISSING BEFORE)
  // =======================
  void _showError(String msg) {
    if (!mounted) return;
    setState(() => errorMsg = msg);
  }

  // =======================
  // CLEANUP
  // =======================
  @override
  void dispose() {
    phoneController.dispose();
    adminEmail.dispose();
    adminPassword.dispose();
    for (final c in _otpDigits) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  // =======================
  // UI (UNCHANGED)
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                isAdminMode
                    ? "Admin Login"
                    : isOtpStage
                        ? "Enter OTP"
                        : "User Login",
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(errorMsg!,
                      style: const TextStyle(color: Colors.red)),
                ),
              if (!isAdminMode) ...[
                if (!isOtpStage) _phoneInput(),
                if (isOtpStage) _otpBoxes(),
                const SizedBox(height: 20),
                _userButton(),
              ],
              if (isAdminMode) ...[
                _adminEmailInput(),
                const SizedBox(height: 12),
                _adminPassInput(),
                const SizedBox(height: 20),
                _adminButton(),
              ],
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isAdminMode = !isAdminMode;
                    isOtpStage = false;
                    errorMsg = null;
                  });
                },
                child: Text(
                  isAdminMode ? "Login as User" : "Admin Login",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.brown,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneInput() => TextField(
        controller: phoneController,
        keyboardType: TextInputType.number,
        maxLength: 10,
        decoration: const InputDecoration(
          counterText: "",
          hintText: "Phone Number",
          prefixText: "+91 ",
          border: OutlineInputBorder(),
        ),
      );

  Widget _otpBoxes() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (i) {
          return SizedBox(
            width: 45,
            child: TextField(
              controller: _otpDigits[i],
              focusNode: _otpFocus[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: const InputDecoration(
                counterText: "",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                if (val.isNotEmpty && i < 5) {
                  _otpFocus[i + 1].requestFocus();
                }
              },
            ),
          );
        }),
      );

  Widget _adminEmailInput() => TextField(
        controller: adminEmail,
        decoration: const InputDecoration(
          labelText: "Admin Email",
          border: OutlineInputBorder(),
        ),
      );

  Widget _adminPassInput() => TextField(
        controller: adminPassword,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(),
        ),
      );

  Widget _userButton() => ElevatedButton(
        onPressed: loading ? null : (isOtpStage ? verifyOtp : sendOtp),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(isOtpStage ? "Verify OTP" : "Send OTP"),
      );

  Widget _adminButton() => ElevatedButton(
        onPressed: loading ? null : adminLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Login"),
      );
}
