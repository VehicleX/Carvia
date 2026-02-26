
import 'dart:ui';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationModal extends StatefulWidget {
  final Function(String code)? onVerified;
  final String? email;
  final VoidCallback? onResend;
  
  const OtpVerificationModal({
    super.key, 
    this.onVerified,
    this.email,
    this.onResend,
  });

  @override
  State<OtpVerificationModal> createState() => _OtpVerificationModalState();
}

class _OtpVerificationModalState extends State<OtpVerificationModal> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextField(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.fromBorderSide(BorderSide(color: Theme.of(context).colorScheme.outline, width: 1)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 32),
            
            // Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_read_outlined, color: Theme.of(context).colorScheme.primary, size: 32),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            
            SizedBox(height: 24),
            
            Text(
              "OTP Verification",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.email != null 
                ? "Enter the 4-digit code sent to\n${_maskEmail(widget.email!)}"
                : "Enter the 4-digit code sent to your email",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                height: 1.5,
              ),
            ),
            
            SizedBox(height: 32),
            
            // OTP Inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (value) => _nextField(index, value),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      counterText: "",
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 2),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
              }),
            ),
            
            SizedBox(height: 32),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Collect code
                  String code = _controllers.map((c) => c.text).join();
                  if (code.length == 4) {
                     widget.onVerified?.call(code);
                  }
                },
                child: Text("Verify Code"),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            
            SizedBox(height: 24),
            
            // Resend Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary),
                ),
                GestureDetector(
                  onTap: widget.onResend,
                  child: Text(
                    "Resend",
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 3) {
      return '${username[0]}***@$domain';
    }
    
    return '${username.substring(0, 2)}***${username[username.length - 1]}@$domain';
  }
}
