import 'package:final_project/Firebase/main_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // PAGE VIEW (FULLSCREEN PAGES)
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              OnboardingPage(
                title: "Welcome to PennyWise",
                description:
                    "Your smart financial companion helping you track expenses, save more, and take control of your money.",
                image: "assets/onboarding.png",
              ),
              OnboardingPage(
                title: "Track Your Spending",
                description:
                    "Record your daily expenses easily and understand your spending habits with clean insights.",
                image: "assets/onboarding.png",
              ),
              OnboardingPage(
                title: "Set Budgets",
                description:
                    "Create categorized budgets and stay on track. Spend wisely and avoid overspending.",
                image: "assets/onboarding.png",
              ),
              OnboardingPage(
                title: "Achieve Savings Goals",
                description:
                    "Track your progress toward dreams — vacations, gadgets, emergencies and investments.",
                image: "assets/onboarding.png",
              ),
            ],
          ),

          // BOTTOM CONTROLS (DOTS + NEXT/START BUTTON)
          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // DOTS
                Row(children: List.generate(4, (index) => _buildDot(index))),

                // BUTTON
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentPage == 3
                      ? _buildButton("Get Started", _completeOnboarding, isDark)
                      : _buildButton(
                          "Next",
                          () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          isDark,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 6),
      width: isActive ? 26 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.white70,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback action, bool isDark) {
    return ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//      FULLSCREEN PAGE WITH GRADIENT OVERLAY
// ─────────────────────────────────────────────

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // FULLSCREEN IMAGE
        Positioned.fill(child: Image.asset(image, fit: BoxFit.cover)),

        // GRADIENT OVERLAY
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // TEXT CONTENT
        Positioned(
          left: 25,
          right: 25,
          bottom: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // DESCRIPTION
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
