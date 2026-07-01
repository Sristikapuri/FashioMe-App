import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/utils/snackbar_utils.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
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

  final TextEditingController firstNameController = TextEditingController();

  final TextEditingController lastNameController = TextEditingController();

  final TextEditingController usernameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController ageController = TextEditingController();

  String? _selectedGender;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Removed redirect to allow signup page to display
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupState = ref.watch(signupViewModelProvider);
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
                /// top image
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.cardBackground,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                /// title
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Join the luxury fashion experience.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                /// first name
                buildTextField(
                  label: 'First Name',
                  hint: 'Aria',
                  controller: firstNameController,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required.';
                    }
                    if (value.trim().length < 2) {
                      return 'First name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// last name
                buildTextField(
                  label: 'Last Name',
                  hint: 'Chen',
                  controller: lastNameController,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required.';
                    }
                    if (value.trim().length < 2) {
                      return 'Last name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// username
                buildTextField(
                  label: 'Username',
                  hint: 'ariachen',
                  controller: usernameController,
                  icon: Icons.alternate_email,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required.';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

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
                    if (!RegExp(
                      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                    ).hasMatch(value.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                /// gender dropdown
                buildDropdownField(
                  label: 'Gender',
                  hint: 'Select Gender',
                  value: _selectedGender,
                  options: _genderOptions,
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Gender is required.';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// age
                buildTextField(
                  label: 'Enter your age',
                  hint: 'Enter your age',
                  controller: ageController,
                  icon: Icons.cake_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Age is required.';
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null) {
                      return 'Please enter a valid age.';
                    }
                    if (age < 1 || age > 100) {
                      return 'Please enter a valid age (1-100).';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

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
                    final trimmed = value.trim();
                    if (trimmed.length < 6) {
                      return 'Confirm password must be at least 6 characters.';
                    }
                    if (trimmed != passwordController.text.trim()) {
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
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                /// create account button
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
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),

                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
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
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          username: usernameController.text,
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          gender: _selectedGender,
          age: ageController.text,
        );
    if (!mounted) return;
    if (success) {
      showAppSnackBar(context, 'Account created successfully!', isError: false);
      AppRoutes.pushAndRemoveUntil(context, const LoginPage());
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
            color: AppColors.profileAccent,
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
              color: AppColors.primary,
            ),

            suffixIcon: IconButton(
              onPressed: onTap,

              icon: Icon(
                obscureText
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

  Widget buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required IconData icon,
    required String? Function(String?)? validator,
    required void Function(String?) onChanged,
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
        DropdownButtonFormField<String>(
          initialValue: value,
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
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
