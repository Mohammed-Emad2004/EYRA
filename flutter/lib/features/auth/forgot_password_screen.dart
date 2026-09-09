import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/firebase/firebase_auth_service.dart';
import '../../core/state/auth_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/eyra_primary_button.dart';
import '../../core/widgets/eyra_secondary_button.dart';
import '../../core/widgets/eyra_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSent = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    final pattern = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _formError = null;
    });
    try {
      await AuthController.of(context).sendPasswordReset(email: _emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _isSent ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(context.tr('resetYourPassword'), style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Enter the email linked to your account and we'll send you a reset link.",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_formError != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: cs.error),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(_formError!, style: TextStyle(color: cs.error)),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
            onChanged: (_) {
              if (_formError != null) setState(() => _formError = null);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          EyraPrimaryButton(
            label: context.tr('sendResetLink'),
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, color: cs.secondary, size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('checkYourEmail'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('resetInstructionsSent'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xl),
        EyraSecondaryButton(
          label: context.tr('backToLogin'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
