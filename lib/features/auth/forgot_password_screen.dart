import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _mobileController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _mobileController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _handleReset() {
    if (_formKey.currentState!.validate()) {
      _nextStep(); // Move to Success Step
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPasswordTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentStep == 1) _buildMobileStep(l10n, theme),
              if (_currentStep == 2) _buildOtpStep(l10n, theme),
              if (_currentStep == 3) _buildNewPasswordStep(l10n, theme),
              if (_currentStep == 4) _buildSuccessStep(l10n, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStep(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.lock_reset_rounded, size: 80, color: AppColors.primaryPurple),
        const SizedBox(height: 24),
        Text(
          l10n.enterMobileToReset,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.mobileNumber,
            prefixIcon: const Icon(Icons.phone_android_rounded),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || value.length != 10) {
              return l10n.invalidMobile;
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        _buildGradientButton(l10n.sendOtp, () {
          if (_formKey.currentState!.validate()) {
            _nextStep();
          }
        }),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(l10n.otpSentTo, textAlign: TextAlign.center),
        Text(
          _mobileController.text,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: InputDecoration(counterText: ""),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        _buildGradientButton(l10n.verifyOtp, () {
          String otp = _otpControllers.map((e) => e.text).join();
          if (otp.length == 6) {
            _nextStep();
          }
        }),
      ],
    );
  }

  Widget _buildNewPasswordStep(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(l10n.setNewPassword, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 32),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: l10n.newPassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) => (value == null || value.length < 6) ? l10n.invalidPassword : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: l10n.confirmPassword,
            prefixIcon: const Icon(Icons.lock_reset_rounded),
          ),
          validator: (value) => (value != _newPasswordController.text) ? l10n.passwordsDoNotMatch : null,
        ),
        const SizedBox(height: 32),
        _buildGradientButton(l10n.resetPassword, _handleReset),
      ],
    );
  }

  Widget _buildSuccessStep(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.check_circle_rounded, size: 100, color: AppColors.successGreen),
        const SizedBox(height: 24),
        Text(
          l10n.passwordUpdated,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.successGreen),
        ),
        const SizedBox(height: 40),
        _buildGradientButton(l10n.backToLogin, () => context.go('/login')),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(text),
      ),
    );
  }
}
