import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  String? _verificationId;
  bool _isLoading = false;
  bool _otpSent = false;

  // STEP 1: Send OTP to Phone
  Future<void> _sendOTP() async {
    String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;

    setState(() => _isLoading = true);
    
    String phone = rawPhone.startsWith('0') ? "+84${rawPhone.substring(1)}" : "+84$rawPhone";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification not usually handled for password reset
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed: ${e.message}");
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          _verificationId = verId;
          _isLoading = false;
          _otpSent = true;
        });
        _showSnackBar("OTP Sent to $phone");
      },
      codeAutoRetrievalTimeout: (String verId) {},
    );
  }

  // STEP 2: Use your logic to Reset Password
  Future<void> _resetPasswordWithOTP() async {
    final smsCode = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (smsCode.isEmpty || newPassword.isEmpty || _verificationId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create the Phone Credential
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // 2. Sign in with the phone temporarily to gain "User" context
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // 3. Update the password for this user
      await userCredential.user!.updatePassword(newPassword);

      if (mounted) {
        _showSnackBar("Password updated successfully!");
        Navigator.pop(context); // Go back to login
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error resetting password: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.orange[900], elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.orange[900],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reset Password", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _otpSent ? "Enter the OTP and your new password." : "Enter your phone number to receive an OTP.",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  if (!_otpSent) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "OTP Code",
                        prefixIcon: const Icon(Icons.lock_clock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "New Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_otpSent ? _resetPasswordWithOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_otpSent ? "Update Password" : "Send OTP", style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
