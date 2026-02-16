
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});


  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final PageController _pageController = PageController();
  // int _currentPage = 0; // Removed unused

  void _scrollToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Background handled by scroll or container
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.bolt_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              "Carvia",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: Text("Login", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
           // Animated Background
           Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 5.seconds),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroToSection(context),
                _buildWhyCarviaSection(),
                _buildHowItWorksSection(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Hero Section ---
  Widget _buildHeroToSection(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Headline
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
              children: const [
                TextSpan(text: "Buy. Sell.\n"),
                TextSpan(
                  text: "Digitally.",
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          
          const SizedBox(height: 16),
          
          Text(
            "Experience the future of automotive ownership. Instant verification, secure payments, and AI-driven insights.",
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 32),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: const Text("Get Started", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.textMuted),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Learn More", style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

          const SizedBox(height: 40),

          // Car Image
          Center(
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?q=80&w=2070&auto=format&fit=crop", // High quality fallback
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.grey[900]);
                  },
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900], child: const Icon(Icons.car_rental, size: 50, color: Colors.white)),
                ),
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  // --- Why Carvia ---
  Widget _buildWhyCarviaSection() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 32, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                "Why Carvia?",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildFeatureCard(
            Icons.swap_horiz_rounded,
            "Buy & Sell Vehicles",
            "List your car instantly or find your dream ride with verified history.",
            0,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.verified_user_rounded,
            "Digital Ownership",
            "Blockchain-backed vehicle history that cannot be tampered with.",
            200,
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.receipt_long_rounded,
            "Challan Management",
            "Track and pay fines instantly. Never miss a deadline.",
            400,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, int delay) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }

  // --- How It Works ---
  Widget _buildHowItWorksSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "How It Works",
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          
          _buildStepCard(1, "Browse", "Find verified vehicles."),
          const SizedBox(height: 16),
          _buildStepCard(2, "Verify", "Check history & AI score."),
          const SizedBox(height: 16),
          _buildStepCard(3, "Own", "Digital transfer of ownership."),
          
          const SizedBox(height: 60),
          
          // Footer
          Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                const Icon(Icons.bolt, size: 30),
                const SizedBox(height: 8),
                Text(
                  "© 2026 CARVIA TECHNOLOGIES INC.",
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepCard(int number, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
           Container(
             width: 44,
             height: 44,
             decoration: BoxDecoration(
               color: AppColors.primary, // Primary background
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
               ],
             ),
             alignment: Alignment.center,
             child: Text(
               "$number",
               style: GoogleFonts.outfit(
                 color: Colors.white, // FIX: Forced White color for visibility
                 fontWeight: FontWeight.bold,
                 fontSize: 20,
               ),
             ),
           ),
           const SizedBox(width: 20),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
             ],
           )
        ],
      ),
    ).animate().fadeIn(delay: (number * 200).ms).slideY(begin: 0.1);
  }
}
