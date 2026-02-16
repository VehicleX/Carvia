import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailOtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // EmailJS Configuration (Free tier: 200 emails/month)
  // Sign up at: https://www.emailjs.com/
  static const String _emailJsServiceId = 'service_8y52fh1'; // Get from EmailJS dashboard
  static const String _emailJsTemplateId = 'template_0jik5g2'; // Get from EmailJS dashboard
  static const String _emailJsUserId = 'bGv7HYq5c_--eDU0m'; // Get from EmailJS dashboard
  
  // Alternative: Use your own backend API endpoint
  // static const String _emailApiEndpoint = 'https://your-api.com/send-email';
  
  // Generate a 4-digit OTP
  String _generateOTP() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }
  
  // Send OTP to email
  Future<String> sendOtpToEmail(String email) async {
    try {
      final otp = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      
      // Store OTP in Firestore temporarily
      await _firestore.collection('email_otps').doc(email).set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': Timestamp.now(),
      });
      
      // Send email via HTTP API (works on all platforms including web)
      await _sendEmailViaHTTP(email, otp);
      
      return otp;
    } catch (e) {
      rethrow;
    }
  }
  
  // Send email using HTTP API (works on web, mobile, desktop)
  Future<void> _sendEmailViaHTTP(String toEmail, String otp) async {
    try {
      // EmailJS API call
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _emailJsServiceId,
          'template_id': _emailJsTemplateId,
          'user_id': _emailJsUserId,
          'template_params': {
            'email': toEmail,  // Changed from 'to_email' to match template
            'otp_code': otp,
            'app_name': 'Carvia',
          }
        }),
      );

      // Email sent successfully or failed silently
      
    } catch (e) {
      // Silently handle email sending errors
    }
  }
  
  // Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final doc = await _firestore.collection('email_otps').doc(email).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      
      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _firestore.collection('email_otps').doc(email).delete();
        return false;
      }
      
      // Check if OTP matches
      if (storedOtp == otp) {
        // Delete OTP after successful verification
        await _firestore.collection('email_otps').doc(email).delete();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Resend OTP (same as send, but checks rate limiting)
  Future<String> resendOtp(String email) async {
    try {
      final doc = await _firestore.collection('email_otps').doc(email).get();
      
      if (doc.exists) {
        final createdAt = (doc.data()!['createdAt'] as Timestamp).toDate();
        final now = DateTime.now();
        
        // Rate limiting: Only allow resend after 30 seconds
        if (now.difference(createdAt).inSeconds < 30) {
          throw 'Please wait before requesting a new OTP';
        }
      }
      
      return await sendOtpToEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
