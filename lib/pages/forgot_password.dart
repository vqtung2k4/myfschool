import 'dart:math';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ResetMethod { phone, email }

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController(); // Handles both Phone or Recovery Email
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  ResetMethod _selectedMethod = ResetMethod.phone;
  String? _verificationId;
  String? _generatedEmailOTP; // 🔥 Stores the OTP we sent via EmailJS
  bool _isLoading = false;
  bool _otpSent = false;

  // --- Logic to Send Code ---
  Future<void> _sendCode() async {
    String input = _identifierController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

    if (_selectedMethod == ResetMethod.phone) {
      // 📱 PHONE LOGIC (OTP)
      String phone = input.startsWith('0') ? "+84${input.substring(1)}" : "+84$input";
      await _sendPhoneOTP(phone);
    } else {
      // 📧 EMAIL OTP LOGIC
      await _sendEmailOTP(input);
    }
  }

  Future<void> _sendPhoneOTP(String phone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {},
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

  // --- NEW: Send Email OTP via EmailJS ---
  Future<void> _sendEmailOTP(String recoveryEmail) async {
    try {
      // 1. Search for the user document by the 'recoveryMail' field (matches your Firestore)
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('recoveryMail', isEqualTo: recoveryEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        throw "No user found with the recovery email: $recoveryEmail";
      }

      final userData = userQuery.docs.first.data();
      String? actualMail = userData['recoveryMail'];

      if (actualMail == null || actualMail.isEmpty) {
        throw "No recovery email found for this user.";
      }

      // 2. Generate the 6-digit OTP
      _generatedEmailOTP = (100000 + Random().nextInt(900000)).toString();

      // 3. Send via EmailJS
      // Using explicit options in the send method to be 100% sure the public key is passed.
      await emailjs.EmailJS.send(
        'service_ps8g8nc',
        'template_6f9f6e9',
        {
          'email': actualMail,
          'otp_code': _generatedEmailOTP,
        },
        const emailjs.Options(
          publicKey: 'ZO5JWdYOXyOMe8obX', 
        ),
      );

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      // Mask the email for privacy (e.g., v***5@gmail.com)
      String maskedEmail = actualMail;
      if (actualMail.contains('@')) {
        var parts = actualMail.split('@');
        if (parts[0].length > 2) {
          maskedEmail = "${parts[0][0]}***${parts[0].characters.last}@${parts[1]}";
        }
      }
      _showSnackBar("OTP sent to: $maskedEmail");

    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("EmailJS Error detail: $e");
      _showSnackBar("Error: Email service issue. Please try again later.");
    }
  }

  // --- Final Reset Logic (Combined for Phone and Email) ---
  Future<void> _handlePasswordReset() async {
    if (_selectedMethod == ResetMethod.phone) {
      await _resetPasswordWithPhoneOTP();
    } else {
      await _resetPasswordWithEmailOTP();
    }
  }

  Future<void> _resetPasswordWithPhoneOTP() async {
    final smsCode = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final rawPhone = _identifierController.text.trim();

    if (smsCode.isEmpty || newPassword.isEmpty || _verificationId == null) return;

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential phoneAuthCred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(phoneAuthCred);
      User? user = userCredential.user;

      if (user != null) {
        await user.updatePassword(newPassword);
        String fakeEmail = "$rawPhone@fschool.edu";

        if (user.email != fakeEmail) {
          try {
            AuthCredential emailCred = EmailAuthProvider.credential(
              email: fakeEmail,
              password: newPassword,
            );
            await user.linkWithCredential(emailCred);
          } catch (e) {
            debugPrint("Email association skipped: $e");
          }
        }
      }

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSnackBar("Success! Password updated. Please login with your new password.");
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  Future<void> _resetPasswordWithEmailOTP() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp != _generatedEmailOTP) {
      _showSnackBar("Invalid Email OTP code.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NOTE: Password update via Email OTP is currently a verification placeholder.
      _showSnackBar("Email OTP Verified! (Password update requires backend integration)");
      
      setState(() => _isLoading = false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Reset failed: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.orange[900], elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  if (!_otpSent) _buildMethodToggle(),
                  const SizedBox(height: 20),
                  if (!_otpSent) 
                    _buildInputField()
                  else ...[
                    _buildOTPAndPasswordField(),
                  ],
                  const SizedBox(height: 40),
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            _otpSent 
              ? "Enter the OTP and your new password." 
              : (_selectedMethod == ResetMethod.phone 
                  ? "Enter your phone number to receive an OTP." 
                  : "Enter your recovery email to receive an Email OTP."),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Phone OTP"),
          selected: _selectedMethod == ResetMethod.phone,
          selectedColor: Colors.orange[900],
          labelStyle: TextStyle(color: _selectedMethod == ResetMethod.phone ? Colors.white : Colors.black),
          onSelected: (val) => setState(() => _selectedMethod = ResetMethod.phone),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Email OTP"),
          selected: _selectedMethod == ResetMethod.email,
          selectedColor: Colors.orange[900],
          labelStyle: TextStyle(color: _selectedMethod == ResetMethod.email ? Colors.white : Colors.black),
          onSelected: (val) => setState(() => _selectedMethod = ResetMethod.email),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    return TextField(
      controller: _identifierController,
      decoration: InputDecoration(
        labelText: _selectedMethod == ResetMethod.phone ? "Phone Number" : "Recovery Email",
        prefixIcon: Icon(_selectedMethod == ResetMethod.phone ? Icons.phone : Icons.email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildOTPAndPasswordField() {
    return Column(
      children: [
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
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_otpSent ? _handlePasswordReset : _sendCode),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _otpSent ? "Update Password" : "Send OTP",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
      ),
    );
  }
}
