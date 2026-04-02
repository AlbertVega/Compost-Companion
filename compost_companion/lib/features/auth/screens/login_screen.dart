import 'package:flutter/material.dart';
import 'package:compost_companion/core/theme/app_colors.dart';
import 'package:compost_companion/features/auth/screens/signup_screen.dart';
import 'package:compost_companion/data/services/auth_service.dart';
import 'package:compost_companion/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // proceed to main navigation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    'Compost Companion',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Smart compost tracking made simple',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: 15,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Username Field
                  _buildUsernameField(context),
                  const SizedBox(height: 20),
                  // Password Field
                  _buildPasswordField(context),
                  const SizedBox(height: 32),
                  // Login Button
                  _buildLoginButton(context),
                  const SizedBox(height: 12),
                  // Create Account Button
                  _buildTextButton(
                    context,
                    'Create Account',
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _usernameController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.iconColor,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.iconColor,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
