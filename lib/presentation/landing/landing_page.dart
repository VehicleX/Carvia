
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              "Carvia",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {}, // Menu Placeholder
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // Allow content to go behind AppBar
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          // setState(() { _currentPage = index; }); // Unused
        },
        children: [
          _buildHeroPage(context),
          _buildWhyCarviaPage(),
          _buildHowItWorksPage(),
        ],
      ),
    );
  }

  // --- Page 1: Hero ---
  Widget _buildHeroPage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40), // Minimal top spacing
          
          // Car Image (Responsive)
          Expanded(
            flex: 4,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: Image.asset(
                      "assets/images/landing_car.jpg",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                         return Container(color: AppColors.surface);
                      },
                    ),
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Headline
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 32, // Responsive Font Size
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
              children: const [
                TextSpan(text: "Buy. Sell.\nManage.\n"),
                TextSpan(
                  text: "Digitally.",
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          
          const SizedBox(height: 12),
          
          Text(
            "Experience the future of automotive ownership. Instant verification, secure payments.",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 24),
          
          // Buttons
          SizedBox(
            width: double.infinity,
            height: 50, // Reduced height
            child: ElevatedButton(
              onPressed: _scrollToNext, // Scroll to next section
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Explore Marketplace"),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_downward_rounded, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            height: 50, // Reduced height
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surface, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: AppColors.textPrimary,
              ),
              child: Text(
                "Login", 
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)
              ),
            ),
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
          
          const Spacer(),
          
          // Scroll Indicator
          Center(
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .slideY(begin: -0.2, end: 0.2, duration: 1.seconds),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Page 2: Why Carvia ---
  Widget _buildWhyCarviaPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Why Choose Carvia?",
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 40),
          
          Expanded(
            child: Center(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  _buildFeatureRow(
                    Icons.swap_horiz_rounded,
                    "Buy & Sell Vehicles",
                    "List your car instantly or find your dream ride with verified history.",
                    0,
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureRow(
                    Icons.verified_user_rounded,
                    "Digital Ownership",
                    "Blockchain-backed vehicle history that cannot be tampered with.",
                    200,
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureRow(
                    Icons.receipt_long_rounded,
                    "Challan Management",
                    "Track and pay fines instantly. Never miss a deadline.",
                    400,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: IconButton(
              onPressed: _scrollToNext,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, int delay) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1);
  }

  // --- Page 3: How It Works & Footer ---
  Widget _buildHowItWorksPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            
             Center(
              child: Column(
                children: [
                  Text(
                    "TRUSTED BY",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.security, color: AppColors.textSecondary, size: 20),
                  const SizedBox(height: 24),
                  Text(
                    "© 2026 CARVIA TECHNOLOGIES INC.",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepCard(int number, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
           Container(
             width: 40,
             height: 40,
             decoration: BoxDecoration(
               color: AppColors.primary,
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
               ],
             ),
             alignment: Alignment.center,
             child: Text(
               "$number",
               style: GoogleFonts.outfit(
                 color: AppColors.background,
                 fontWeight: FontWeight.bold,
                 fontSize: 18,
               ),
             ),
           ),
           const SizedBox(width: 20),
           // ...
        ],
      ),
    ).animate().fadeIn(delay: (number * 200).ms).slideY(begin: 0.1);
  }
}
