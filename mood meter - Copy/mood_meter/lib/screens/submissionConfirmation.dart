import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_meter/screens/userDashboard.dart';


class SubmissionConfirmationScreen extends StatelessWidget {
  final String moodType;

  const SubmissionConfirmationScreen({
    Key? key,
    required this.moodType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double maxContentWidth = 800.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation
                  SizedBox(
                    height: 180,
                    child: Lottie.asset(
                      'assets/animations/success_check.json',
                      repeat: false,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Thank you message
                  Text(
                    'Thank You!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2AABE2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirmation message
                  Text(
                    'Your ${moodType.toLowerCase()} mood has been recorded successfully.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Motivational quote
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getRandomQuote(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Back to dashboard button
                  ElevatedButton(
                    onPressed:(){ Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>UserDashboard()));},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2AABE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRandomQuote() {
    final quotes = [
      "Your feedback helps us create a better workplace for everyone.",
      "Thank you for sharing how you feel today. Your input matters.",
      "Small moments of honesty create big changes over time.",
      "Your voice matters. Together we can create positive change.",
      "Your wellbeing is important to us. Thank you for participating.",
      "Every voice counts in building our company culture.",
      "Thank you for your contribution to making our workplace better.",
    ];

    return quotes[Random().nextInt(quotes.length)];
  }
}
