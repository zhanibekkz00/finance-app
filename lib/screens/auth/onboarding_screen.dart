import 'package:flutter/material.dart';
import '../../app.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome',
      'description': 'Track your expenses easily.',
      'color': Colors.blueAccent,
    },
    {
      'title': 'Analyze',
      'description': 'See where your money goes.',
      'color': Colors.greenAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(context, _pages[index], index == _pages.length - 1);
            },
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('Skip', style: TextStyle(color: Colors.white)),
                ),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Next', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: const Text('Get Started'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, Map<String, dynamic> page, bool isLast) {
    return Container(
      color: page['color'],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page['title'],
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            page['description'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
