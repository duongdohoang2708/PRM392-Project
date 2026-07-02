import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/keyboard/keyboard_insets.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/background_pattern.dart';
import '../../widgets/common/google_logo_icon.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/theme/mode_change_notification_suppression.dart';
import '../../services/google_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SuppressesModeChangeNotification {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    final error = await context.read<UserProvider>().signUp(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppNotification.showError(context, error);
      return;
    }

    AppNotification.showSuccess(context, 'Account created successfully!');
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final tokens = await GoogleAuthService.signIn();
      if (tokens == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final error = await context.read<UserProvider>().signInWithGoogle(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (error != null) {
        AppNotification.showError(context, error);
        return;
      }
      Navigator.of(context).pushReplacementNamed('/main');
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotification.showError(context, 'Google sign-up failed.');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          const BackgroundPattern(),
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
                    Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authBrandingTitleOf(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account and start planning calmly.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.authBrandingSubtitleOf(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceFillOf(context),
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
                            'Create account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Full name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'Your name',
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: '••••••••',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Confirm password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: '••••••••',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            text: 'Create account',
                            onPressed: _handleRegister,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: AppColors.borderOf(context)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryOf(context),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: AppColors.borderOf(context)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Sign up with Google',
                            onPressed: () {
                              if (!_isLoading) _handleGoogleSignUp();
                            },
                            isPrimary: false,
                            icon: const GoogleLogoIcon(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDarkOf(context),
                            ),
                          ),
                        ),
                      ],
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
