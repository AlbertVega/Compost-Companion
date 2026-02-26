import 'package:flutter/material.dart';
import 'package:compost_companion/core/theme/app_colors.dart';
import 'package:compost_companion/features/auth/presentation/screens/login_screen.dart';
import 'package:compost_companion/data/services/auth_service.dart';
import 'package:compost_companion/data/models/user_create.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _authService = const AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _countryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final country = _countryCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
      return;
    }

    setState(() => _isLoading = true);

    final user = UserCreate(
      username: username,
      email: email,
      password: password,
      country: country,
      location: location,
    );

    try {
      await _authService.registerUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                // Email Field
                _buildEmailField(context),
                const SizedBox(height: 20),
                // Password Field
                _buildPasswordField(context),
                const SizedBox(height: 20),
                // Country Field
                _buildCountryField(context),
                const SizedBox(height: 20),
                // Location Field
                _buildLocationField(context),
                const SizedBox(height: 32),
                // Create Account Button
                _buildCreateAccountButton(context),
                const SizedBox(height: 20),
                // Login Link
                _buildLoginLink(context),
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
        TextField(
          controller: _usernameCtrl,
          decoration: InputDecoration(
            hintText: 'Choose your username',
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.iconColor,
            ),
          ),
        ),
      ],
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
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: const Icon(
              Icons.mail_outline,
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
          controller: _passwordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Create a password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _countryCtrl,
          decoration: InputDecoration(
            hintText: 'Select your country',
            prefixIcon: const Icon(
              Icons.public,
              color: AppColors.iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _locationCtrl,
          decoration: InputDecoration(
            hintText: 'City / Region',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            'Login',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
