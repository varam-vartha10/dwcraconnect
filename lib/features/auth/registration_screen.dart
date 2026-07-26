import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _villageController = TextEditingController();
  final _groupController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    _villageController.dispose();
    _groupController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _handleSendOtp() {
    if (_formKey.currentState!.validate()) {
      // Navigate to OTP Verification with mobile number
      context.push('/otp-verification', extra: _mobileController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.register),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: AppColors.primaryPurple,
            secondary: AppColors.secondaryPink,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _previousStep,
            controlsBuilder: (context, controls) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    if (_currentStep == 2)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: _handleSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: Text(l10n.sendOtp),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controls.onStepContinue,
                          child: Text(l10n.next),
                        ),
                      ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controls.onStepCancel,
                          child: Text(l10n.previous),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(_currentStep == 0 ? l10n.stepPersonal : ''),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.editing,
                content: Column(
                  children: [
                    _buildTextField(l10n.fullName, _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(l10n.mobileNumber, _mobileController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(l10n.aadhaarNumber, _aadhaarController, Icons.credit_card_rounded, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              Step(
                title: Text(_currentStep == 1 ? l10n.stepGroup : ''),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.indexed),
                content: Column(
                  children: [
                    _buildTextField(l10n.village, _villageController, Icons.location_on_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(l10n.shgGroup, _groupController, Icons.group_outlined),
                  ],
                ),
              ),
              Step(
                title: Text(_currentStep == 2 ? l10n.stepSecurity : ''),
                isActive: _currentStep >= 2,
                state: _currentStep == 2 ? StepState.editing : StepState.indexed,
                content: Column(
                  children: [
                    _buildTextField(l10n.password, _passwordController, Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 16),
                    _buildTextField(l10n.confirmPassword, _confirmPasswordController, Icons.lock_reset, isPassword: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            final l10n = AppLocalizations.of(context)!;
            if (value == null || value.isEmpty) {
              return l10n.required;
            }
            if (label == l10n.mobileNumber && value.length != 10) {
              return l10n.invalidMobile;
            }
            if (label == l10n.aadhaarNumber && value.length != 12) {
              return l10n.invalidAadhaar;
            }
            if (label == l10n.confirmPassword && value != _passwordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),
      ],
    );
  }
}
