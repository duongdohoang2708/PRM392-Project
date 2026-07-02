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
import 'register_screen.dart';
import 'forgot_password_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SuppressesModeChangeNotification {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      AppNotification.showError(context, 'Email and password are required.');
      return;
    }

    setState(() => _isLoading = true);
    final error = await context.read<UserProvider>().signIn(
          email: email,
          password: password,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppNotification.showError(context, error);
      return;
    }
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _handleGoogleSignIn() async {
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
        AppNotification.showError(context, 'Google sign-in failed.');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                      'Small steps, calm days, better focus.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.authBrandingSubtitleOf(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Card
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
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log in to continue your peaceful planner.',
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
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDarkOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: '••••••••',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.visibility_off_outlined),
                              onPressed: () {
                                // Toggle password visibility (mock)
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          CustomButton(
                            text: 'Log in',
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                          ),

                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppColors.borderOf(context)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                          ),

                          // Social Login
                          CustomButton(
                            text: 'Continue with Google',
                            onPressed: () {
                              if (!_isLoading) _handleGoogleSignIn();
                            },
                            isPrimary: false,
                            icon: const GoogleLogoIcon(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create account',
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
