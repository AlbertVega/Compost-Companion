import 'package:flutter/material.dart';
import 'package:compost_companion/core/theme/app_colors.dart';
import 'package:compost_companion/features/auth/presentation/screens/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                // Email Field
                _buildEmailField(context),
                const SizedBox(height: 20),
                // Password Field
                _buildPasswordField(context),
                const SizedBox(height: 32),
                // Login Button
                _buildLoginButton(context),
                const SizedBox(height: 16),
                // Continue as Guest Button
                _buildTextButton(
                  context,
                  'Continue as Guest',
                  () {},
                ),
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

  Widget _buildEmailField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.iconColor,
            ),
          ),
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
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        child: const Text(
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
