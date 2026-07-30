import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:fashio_me/features/auth/presentation/pages/signup_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// top image banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 230,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: AppColors.surfaceSoft),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.heroOverlayLight,
                                AppColors.heroOverlayDark,
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Luxury Fashion,\nPersonalized For You',
                              style: TextStyle(
                                fontSize: 30,
                                height: 1.2,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                /// title
                Text(
                  context.strings.welcomeBack,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  context.strings.signInToContinue,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                /// email field
                buildTextField(
                  label: context.strings.emailAddress,
                  hint: 'aria@fashiome.com',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.strings.emailRequired;
                    }
                    if (!RegExp(
                      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                    ).hasMatch(value.trim())) {
                      return context.strings.invalidEmail;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// password field
                buildPasswordField(loginState.obscurePassword),

                if (loginState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    loginState.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                /// forgot password
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      AppRoutes.push(
                        context,
                        ForgotPasswordPage(
                          initialEmail: emailController.text.trim(),
                        ),
                      );
                    },

                    child: Text(
                      context.strings.forgotPassword,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// sign in button
                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    onPressed: loginState.isLoading ? null : _onSignIn,

                    child: loginState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.strings.signIn,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                /// signup button
                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.3,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    onPressed: () {
                      AppRoutes.push(context, const SignupPage());
                    },

                    child: Text(
                      context.strings.createNewAccount,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSignIn() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() => _autoValidate = true);
      return;
    }

    final success = await ref
        .read(loginViewModelProvider.notifier)
        .login(email: emailController.text, password: passwordController.text);
    if (!mounted) return;
    if (success) {
      AppRoutes.pushAndRemoveUntil(context, const DashboardPage());
    } else {
      final message = ref.read(loginViewModelProvider).errorMessage;
      if (message != null) {
        context.showSnackBar(message);
      }
    }
  }

  Widget buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),

          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: AppColors.profileAccent,
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: controller,
          validator: validator,

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: Icon(icon, color: AppColors.primary),

            filled: true,
            fillColor: AppColors.cardBackground,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: const BorderSide(color: AppColors.divider),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(bool obscurePassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.password.toUpperCase(),

          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: AppColors.profileAccent,
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.strings.passwordRequired;
            }
            final trimmed = value.trim();
            if (trimmed.length < 6) {
              return context.strings.passwordTooShort;
            }
            return null;
          },

          decoration: InputDecoration(
            hintText: '••••••••',

            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
            ),

            suffixIcon: IconButton(
              onPressed: () {
                ref
                    .read(loginViewModelProvider.notifier)
                    .togglePasswordVisibility();
              },

              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textLight,
              ),
            ),

            filled: true,
            fillColor: AppColors.cardBackground,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: const BorderSide(color: AppColors.divider),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),

              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
