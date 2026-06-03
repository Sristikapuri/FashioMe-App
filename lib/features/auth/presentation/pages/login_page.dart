import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/core/utils/snackbar_utils.dart';
import 'package:fashio_me/features/auth/presentation/pages/signup_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart';
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
                /// top image banner
                Container(
                  height: 230,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
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
                  ),
                ),

                const SizedBox(height: 36),

                /// title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Sign in to continue your style journey.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 34),

                /// email field
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

                /// password field
                buildPasswordField(loginState.obscurePassword),

                if (loginState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    loginState.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF7A0000),
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
                    onPressed: () {},

                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF7A0000),
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
                      backgroundColor: const Color(0xFF7A0000),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
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
                        : const Text(
                            'Sign In',
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
                        color: Color(0xFF7A0000),
                        width: 1.3,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: () {
                      AppRoutes.push(
                        context,
                        const SignupPage(),
                      );
                    },

                    child: const Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A0000),
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
      AppRoutes.pushAndRemoveUntil(
        context,
        const DashboardPage(),
      );
    } else {
      final message = ref.read(loginViewModelProvider).errorMessage;
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

  Widget buildPasswordField(bool obscurePassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASSWORD',

          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B6B6B),
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
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

          decoration: InputDecoration(
            hintText: '••••••••',

            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF7A0000),
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
