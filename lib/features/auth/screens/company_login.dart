
import 'package:flutter/material.dart';
import '../../dashboard/screens/main_dashboard.dart'; 
import '../logic/auth_repository.dart';
import '../../../core/widgets/custom_text_field.dart';

class CompanyLogin extends StatefulWidget {
  const CompanyLogin({super.key});

  @override
  State<CompanyLogin> createState() => _CompanyLoginState();
}

class _CompanyLoginState extends State<CompanyLogin> {
  final _companyIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  
  final AuthRepository _authRepository = AuthRepository();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyIdController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (_companyIdController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please enter ID and Password");
      return;
    }

    setState(() => _isLoading = true);

    String safeId = _companyIdController.text.trim().replaceAll(' ', '').toUpperCase();
    String syntheticEmail = _authRepository.generateSyntheticEmail(safeId, "company.jeevdhara.app");

    try {
      if (_isLogin) {
        await _authRepository.signIn(syntheticEmail, _passwordController.text.trim());
      } else {
        if (_companyNameController.text.isEmpty) {
          _showSnackBar("Please enter a Company Name");
          setState(() => _isLoading = false);
          return;
        }
        await _authRepository.signUpCompany(
          safeId: safeId,
          syntheticEmail: syntheticEmail,
          password: _passwordController.text.trim(),
          companyName: _companyNameController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (BuildContext context) => const MainDashboard()),
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('email')) {
        errorMsg = errorMsg.replaceAll('email address', 'Company ID').replaceAll('email', 'Company ID');
      }
      _showSnackBar(errorMsg.replaceFirst(RegExp(r'^\[.*?\] '), '')); 
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 60, color: colorScheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          _isLogin ? 'Corporate Portal' : 'Register Company',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_isLogin) ...[
                          CustomTextField(
                            controller: _companyNameController,
                            labelText: 'Company Name',
                            prefixIcon: Icons.apartment,
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomTextField(
                          controller: _companyIdController,
                          labelText: 'Company ID',
                          prefixIcon: Icons.badge,
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitAuth,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isLogin ? 'Login' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? 'Register your Company?'
                                : 'Already have an account? Log in',
                            style: TextStyle(color: colorScheme.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: colorScheme.onSurface,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}