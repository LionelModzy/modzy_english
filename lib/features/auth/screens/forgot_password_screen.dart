import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthRepository.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: _emailSent 
                    ? LinearGradient(
                        colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: (_emailSent ? AppColors.success : AppColors.primary).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _emailSent ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                _emailSent ? 'Check Your Email!' : 'Reset Password',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                _emailSent 
                  ? 'We\'ve sent a password reset link to\n${_emailController.text}'
                  : 'Enter your email address and we\'ll send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              if (!_emailSent) ...[
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        prefixIcon: Icons.email_rounded,
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      
                      // Send Reset Email Button
                      CustomButton(
                        text: 'Send Reset Link',
                        onPressed: _sendResetEmail,
                        isLoading: _isLoading,
                        icon: Icons.send_rounded,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Success Actions
                Column(
                  children: [
                    CustomButton(
                      text: 'Resend Email',
                      onPressed: () {
                        setState(() {
                          _emailSent = false;
                        });
                      },
                      icon: Icons.refresh_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Back to Login',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Security Notice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For your security, the reset link will expire in 24 hours. If you don\'t receive the email, please check your spam folder.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 