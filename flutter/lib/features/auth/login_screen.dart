import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_logo.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/eyra_password_field.dart';
import '../../core/widgets/eyra_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    final pattern = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await AuthController.of(context).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } catch (_) {
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const Center(child: EyraLogo(size: 84)),
                const SizedBox(height: AppSpacing.xl),
                Text(context.tr('welcomeBack'), style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(context.tr('continueToEyra'), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                if (_formError != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(_formError!, style: const TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                EyraTextField(
                  label: context.tr('email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  onChanged: (_) {
                    if (_formError != null) setState(() => _formError = null);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                EyraPasswordField(
                  label: context.tr('password'),
                  controller: _passwordController,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: _validatePassword,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                    child: Text(context.tr('forgotPassword')),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                EyraPrimaryButton(
                  label: context.tr('logIn'),
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pushNamed(AppRoutes.signUp),
                    child: Text(context.tr('createAccount')),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
