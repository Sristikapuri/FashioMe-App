import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/core/utils/snackbar_utils.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  final TextEditingController fullNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Removed redirect to allow signup page to display
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupViewModelProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F6F5),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),

          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// top image
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),

                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),

                    child: const Padding(
                      padding: EdgeInsets.all(24),

                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Create Your\nFashion Identity',
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                /// title
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Join the luxury fashion experience.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 34),

                /// full name
                buildTextField(
                  label: 'Full Name',
                  hint: 'Aria Chen',
                  controller: fullNameController,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required.';
                    }
                    if (value.trim().length < 3) {
                      return 'Full name must be at least 3 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                /// email
                buildTextField(
                  label: 'Email Address',
                  hint: 'aria@fashiome.com',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required.';
                    }
                    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(value.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                /// password
                buildPasswordField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: signupState.obscurePassword,
                  onTap: () {
                    ref
                        .read(signupViewModelProvider.notifier)
                        .togglePasswordVisibility();
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required.';
                    }
                    final trimmed = value.trim();
                    if (trimmed.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 22),

                /// confirm password
                buildPasswordField(
                  label: 'Confirm Password',
                  controller: confirmPasswordController,
                  obscureText: signupState.obscureConfirmPassword,
                  onTap: () {
                    ref
                        .read(signupViewModelProvider.notifier)
                        .toggleConfirmPasswordVisibility();
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Confirm password is required.';
                    }
                    if (passwordController.text.trim() != value.trim()) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),

                if (signupState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    signupState.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF7A0000),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 34),

                /// create account button
                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A0000),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: signupState.isLoading ? null : _onCreateAccount,

                    child: signupState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                /// login redirect
                Center(
                  child: GestureDetector(
                    onTap: () {
                      AppRoutes.pushReplacement(context, const LoginPage());
                    },

                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.black54, fontSize: 16),

                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: Color(0xFF7A0000),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Future<void> _onCreateAccount() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      setState(() => _autoValidate = true);
      return;
    }

    final success = await ref
        .read(signupViewModelProvider.notifier)
        .register(
          fullName: fullNameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
        );
    if (!mounted) return;
    if (success) {
      showAppSnackBar(
        context,
        'Account created successfully!',
        isError: false,
      );
      AppRoutes.pushAndRemoveUntil(context, const DashboardPage());
    } else {
      final message = ref.read(signupViewModelProvider).errorMessage;
      if (message != null) {
        showAppSnackBar(context, message);
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
            color: Color(0xFF6B6B6B),
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: controller,
          validator: validator,

          decoration: InputDecoration(
            hintText: hint,

            prefixIcon: Icon(icon, color: const Color(0xFF7A0000)),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),

              borderSide: BorderSide(color: Colors.grey.shade200),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),

              borderSide: const BorderSide(
                color: Color(0xFF7A0000),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onTap,
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
            color: Color(0xFF6B6B6B),
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,

          decoration: InputDecoration(
            hintText: '••••••••',

            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF7A0000),
            ),

            suffixIcon: IconButton(
              onPressed: onTap,

              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),

              borderSide: BorderSide(color: Colors.grey.shade200),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),

              borderSide: const BorderSide(
                color: Color(0xFF7A0000),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
