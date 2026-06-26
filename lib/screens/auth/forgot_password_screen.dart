import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/keyboard/keyboard_insets.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/background_pattern.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _handleResetPassword() {
    // Mock reset logic
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email!'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          // Background Pattern
          const BackgroundPattern(),

          // Main Content
          SafeArea(
            child: Center(
              child: KeyboardAwareSingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Branding
                    const Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Don\'t worry, we\'ll get you back on track.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Reset Password Card
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.cardOf(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderOf(context)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimaryOf(context).withAlpha(
                              (255 * 0.08).round(),
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email address and we will send you a link to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Input
                          Text(
                            'Email address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'your@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.mail_outline),
                          ),
                          const SizedBox(height: 32),

                          // Reset Button
                          CustomButton(
                            text: 'Send Reset Link',
                            onPressed: _handleResetPassword,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 24),

                          // Back to Login Link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16,
                                    color: AppColors.primaryDark,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Back to Log In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
