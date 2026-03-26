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
  final _identifierController = TextEditingController(); 
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  ResetMethod _selectedMethod = ResetMethod.phone;
  String? _verificationId;
  String? _generatedEmailOTP; 
  bool _isLoading = false;
  bool _otpSent = false;

  Future<void> _sendCode() async {
    String input = _identifierController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

    if (_selectedMethod == ResetMethod.phone) {
      String phone = input.startsWith('0') ? "+84${input.substring(1)}" : "+84$input";
      await _sendPhoneOTP(phone);
    } else {
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

  // --- Send Email OTP via EmailJS ---
  Future<void> _sendEmailOTP(String recoveryEmail) async {
    setState(() => _isLoading = true);
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('recoveryMail', isEqualTo: recoveryEmail.trim())
          .get();

      if (userQuery.docs.isEmpty) {
        throw "User not found with recovery email: $recoveryEmail";
      }

      final userData = userQuery.docs.first.data();
      final actualMail = (userData['recoveryMail'] as String).trim();

      final otp = (100000 + Random().nextInt(900000)).toString();
      _generatedEmailOTP = otp;

      debugPrint("EmailJS: Sending OTP to $actualMail");

      final response = await emailjs.send(
        'service_06q7mbg',
        'template_hemjvl3',
        {
          'email': actualMail,
          'otp_code': otp,
        },
        const emailjs.Options(
          publicKey: 'ZO5JWdYOXyOMe8obX',
        ),
      );

      debugPrint("EmailJS Status: ${response.status} - ${response.text}");

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      _showSnackBar("OTP sent successfully to $actualMail");

    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("EmailJS Error: $e");

      String message = "Failed to send OTP.";
      if (e.toString().contains("400")) {
        message = "Error 400: Please check EmailJS Security (UNCHECK 'Use Private Key').";
      }
      _showSnackBar(message);
    }
  }

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
      }
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSnackBar("Success! Password updated.");
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  Future<void> _resetPasswordWithEmailOTP() async {
    if (_otpController.text.trim() != _generatedEmailOTP) {
      _showSnackBar("Invalid Email OTP code.");
      return;
    }
    _showSnackBar("Email OTP Verified! (Implement password update here)");
    Navigator.pop(context);
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
              : "Choose how you want to reset your password.",
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
          onSelected: (val) => setState(() => _selectedMethod = ResetMethod.phone),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Email OTP"),
          selected: _selectedMethod == ResetMethod.email,
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
