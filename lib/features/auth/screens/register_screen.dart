import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';
import '../../../models/user_model.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isEmbedded;
  
  const RegisterScreen({super.key, this.isEmbedded = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserModel? user = await AuthRepository.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // Error handled in AuthRepository
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Column(
      children: [
        // Welcome text for embedded mode
        if (widget.isEmbedded) ...[
          Text(
            'Tạo tài khoản mới',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tham gia cùng chúng tôi để bắt đầu học tiếng Anh',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
        
        // Form fields
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Display Name Field
              CustomTextField(
                label: widget.isEmbedded ? 'Họ và tên' : 'Full Name',
                hint: widget.isEmbedded ? 'Nhập họ và tên của bạn' : 'Enter your full name',
                prefixIcon: Icons.person_rounded,
                controller: _displayNameController,
                validator: (value) => Validators.validateRequired(value, widget.isEmbedded ? 'Họ và tên' : 'Full name'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              
              // Email Field
              CustomTextField(
                label: widget.isEmbedded ? 'Địa chỉ Email' : 'Email Address',
                hint: widget.isEmbedded ? 'Nhập địa chỉ email của bạn' : 'Enter your email address',
                prefixIcon: Icons.email_rounded,
                controller: _emailController,
                validator: Validators.validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              
              // Password Field
              CustomTextField(
                label: widget.isEmbedded ? 'Mật khẩu' : 'Password',
                hint: widget.isEmbedded ? 'Tạo mật khẩu mạnh' : 'Create a strong password',
                prefixIcon: Icons.lock_rounded,
                controller: _passwordController,
                validator: Validators.validatePassword,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                helperText: widget.isEmbedded ? 'Mật khẩu phải có ít nhất 6 ký tự' : 'Password must be at least 6 characters',
              ),
              const SizedBox(height: 20),
              
              // Confirm Password Field
              CustomTextField(
                label: widget.isEmbedded ? 'Xác nhận mật khẩu' : 'Confirm Password',
                hint: widget.isEmbedded ? 'Nhập lại mật khẩu' : 'Re-enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                controller: _confirmPasswordController,
                validator: _validateConfirmPassword,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 32),
              
              // Register Button
              CustomButton(
                text: widget.isEmbedded ? 'Tạo tài khoản' : 'Create Account',
                onPressed: _register,
                isLoading: _isLoading,
                icon: Icons.person_add_rounded,
              ),
              const SizedBox(height: 20),
              
              // Terms and Conditions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.isEmbedded 
                    ? 'Bằng cách tạo tài khoản, bạn đồng ý với Điều khoản Dịch vụ và Chính sách Bảo mật của chúng tôi'
                    : 'By creating an account, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _buildRegisterForm(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join us and start learning English',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildRegisterForm(context),
              
              const SizedBox(height: 40),
              
              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 