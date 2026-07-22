import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';

class ProfileUpdatePage extends ConsumerStatefulWidget {
  const ProfileUpdatePage({super.key});

  @override
  ConsumerState<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends ConsumerState<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _gender;
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userResult = await ref
        .read(authSessionViewModelProvider.notifier)
        .getCurrentUser();
    userResult.fold(
      (failure) => setState(() => _errorMessage = failure.message),
      (user) {
        setState(() {
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _usernameController.text = user.username;
          _ageController.text = user.age ?? '';
          _gender = user.gender;
        });
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await ref
        .read(authSessionViewModelProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          username: _usernameController.text.trim(),
          gender: _gender,
          age: _ageController.text.isNotEmpty
              ? int.tryParse(_ageController.text)
              : null,
          profileImage: _profileImage,
        );

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) => setState(() => _errorMessage = failure),
      (user) =>
          setState(() => _successMessage = 'Profile updated successfully'),
    );
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both password fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await ref
        .read(authSessionViewModelProvider.notifier)
        .updateProfile(password: _passwordController.text);

    setState(() {
      _isLoading = false;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });

    result.fold(
      (failure) => setState(() => _errorMessage = failure),
      (user) =>
          setState(() => _successMessage = 'Password updated successfully'),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProgress = _calculateFormProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontFamily: AppFonts.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppColors.surfaceSoft.withValues(alpha: 0.65),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormProgressCard(progress: formProgress),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Tap to change profile photo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: AppFonts.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontFamily: AppFonts.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: AppFonts.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontFamily: AppFonts.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => _showDeleteConfirmation(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(fontFamily: AppFonts.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account',
          style: TextStyle(fontFamily: AppFonts.bold, color: AppColors.error),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await ref
          .read(authSessionViewModelProvider.notifier)
          .deleteAccount();
      setState(() => _isLoading = false);

      if (success) {
        if (!context.mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        setState(
          () => _errorMessage =
              'Failed to delete account. Please try again later.',
        );
      }
    }
  }

  double _calculateFormProgress() {
    int completedFields = 0;
    int totalFields = 5;

    if (_firstNameController.text.isNotEmpty) completedFields++;
    if (_lastNameController.text.isNotEmpty) completedFields++;
    if (_usernameController.text.isNotEmpty) completedFields++;
    if (_gender != null) completedFields++;
    if (_ageController.text.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }
}

class _FormProgressCard extends StatelessWidget {
  const _FormProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Form Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppFonts.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppFonts.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
