import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dwcra_connect/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Step 1: Personal Details
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _altMobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _villageController = TextEditingController();
  final _mandalController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController(text: 'Andhra Pradesh');
  String _preferredLanguage = 'en';

  // Step 2: Group Details
  final _groupController = TextEditingController(text: 'GRP001');
  String _requestedRole = 'member';

  // Step 3: Optional Financial Details
  bool _hasLoan = false;
  final _providerController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _outstandingBalanceController = TextEditingController();
  final _emiAmountController = TextEditingController();
  final _nextEmiDueDateController = TextEditingController();
  final _totalInstallmentsController = TextEditingController();
  final _paidInstallmentsController = TextEditingController();
  bool _hasSubsidy = false;
  final _subsidyAmountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _altMobileController.dispose();
    _dobController.dispose();
    _villageController.dispose();
    _mandalController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _groupController.dispose();
    _providerController.dispose();
    _accountNumberController.dispose();
    _originalAmountController.dispose();
    _outstandingBalanceController.dispose();
    _emiAmountController.dispose();
    _nextEmiDueDateController.dispose();
    _totalInstallmentsController.dispose();
    _paidInstallmentsController.dispose();
    _subsidyAmountController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty ||
          _mobileController.text.trim().length != 10 ||
          _villageController.text.trim().isEmpty ||
          _mandalController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty) {
        _showErrorSnackBar('Please complete all required personal details correctly.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_groupController.text.trim().isEmpty) {
        _showErrorSnackBar('Please enter a valid SHG Group ID.');
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleInitiateRegistration() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fix validation errors before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.post('/auth/register/initiate', {
        'fullName': _nameController.text.trim(),
        'phoneNumber': _mobileController.text.trim(),
        'altPhoneNumber': _altMobileController.text.trim().isNotEmpty ? _altMobileController.text.trim() : null,
        'dob': _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        'village': _villageController.text.trim(),
        'mandal': _mandalController.text.trim(),
        'district': _districtController.text.trim(),
        'state': _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : 'Andhra Pradesh',
        'preferredLanguage': _preferredLanguage,
        'groupId': _groupController.text.trim(),
        'requestedRole': _requestedRole,
        'initialFinancials': {
          'hasLoan': _hasLoan,
          'provider': _providerController.text.trim().isNotEmpty ? _providerController.text.trim() : null,
          'accountNumber': _accountNumberController.text.trim().isNotEmpty ? _accountNumberController.text.trim() : null,
          'originalAmount': double.tryParse(_originalAmountController.text.trim()),
          'outstandingBalance': double.tryParse(_outstandingBalanceController.text.trim()),
          'emiAmount': double.tryParse(_emiAmountController.text.trim()),
          'nextEmiDueDate': _nextEmiDueDateController.text.trim().isNotEmpty ? _nextEmiDueDateController.text.trim() : null,
          'totalInstallments': int.tryParse(_totalInstallmentsController.text.trim()),
          'paidInstallments': int.tryParse(_paidInstallmentsController.text.trim()),
          'hasSubsidy': _hasSubsidy,
          'subsidyAmount': double.tryParse(_subsidyAmountController.text.trim()),
        },
      });

      if (!mounted) return;

      if (response['success'] == true) {
        final regId = response['registrationId'] as String;
        final phone = response['phoneNumber'] as String;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP sent to mobile number.'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.push('/otp-verification', extra: {
          'registrationId': regId,
          'phoneNumber': phone,
        });
      } else {
        _showErrorSnackBar(response['message'] ?? 'Registration failed.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Registration'),
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
                            onPressed: _isSubmitting ? null : _handleInitiateRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Send OTP Verification'),
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
              // STEP 1: Personal Details
              Step(
                title: Text(_currentStep == 0 ? 'Personal' : ''),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.editing,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Full Name (as per records) *', _nameController, Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField('Mobile Number (10 digits) *', _mobileController, Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Alternate Mobile Number (Optional)', _altMobileController, Icons.phone_outlined, keyboardType: TextInputType.phone, isRequired: false),
                    const SizedBox(height: 16),
                    _buildTextField('Village / Area *', _villageController, Icons.location_on_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('Mandal *', _mandalController, Icons.map_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('District *', _districtController, Icons.location_city_outlined),
                    const SizedBox(height: 16),
                    _buildTextField('State', _stateController, Icons.flag_outlined, isRequired: false),
                    const SizedBox(height: 16),
                    const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _preferredLanguage,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded)),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
                      ],
                      onChanged: (val) => setState(() => _preferredLanguage = val ?? 'en'),
                    ),
                  ],
                ),
              ),

              // STEP 2: Group Details
              Step(
                title: Text(_currentStep == 1 ? 'SHG Group' : ''),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.indexed),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Existing SHG Group ID *', _groupController, Icons.group_outlined),
                    const SizedBox(height: 16),
                    const Text('Requested Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _requestedRole,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'member', child: Text('Ordinary Member')),
                        DropdownMenuItem(value: 'president', child: Text('President (Requires Approval)')),
                        DropdownMenuItem(value: 'secretary', child: Text('Secretary (Requires Approval)')),
                      ],
                      onChanged: (val) => setState(() => _requestedRole = val ?? 'member'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: Selecting President or Secretary submits a role request. Official role privileges require verification from authorised leaders.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // STEP 3: Optional Financial Details
              Step(
                title: Text(_currentStep == 2 ? 'Financial' : ''),
                isActive: _currentStep >= 2,
                state: _currentStep == 2 ? StepState.editing : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Do you currently have an SHG loan?', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Optional initial information'),
                      value: _hasLoan,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => _hasLoan = val),
                    ),
                    if (_hasLoan) ...[
                      const SizedBox(height: 12),
                      _buildTextField('Lending Institution / Provider', _providerController, Icons.account_balance_outlined, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField('Original Loan Amount (INR)', _originalAmountController, Icons.currency_rupee, keyboardType: TextInputType.number, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField('Current Outstanding Balance (INR)', _outstandingBalanceController, Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number, isRequired: false),
                      const SizedBox(height: 12),
                      _buildTextField('Monthly EMI Amount (INR)', _emiAmountController, Icons.payments_outlined, keyboardType: TextInputType.number, isRequired: false),
                    ],
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('Have you received a government subsidy?', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _hasSubsidy,
                      activeColor: AppColors.primaryPurple,
                      onChanged: (val) => setState(() => _hasSubsidy = val),
                    ),
                    if (_hasSubsidy) ...[
                      const SizedBox(height: 12),
                      _buildTextField('Subsidy Amount (INR)', _subsidyAmountController, Icons.savings_outlined, keyboardType: TextInputType.number, isRequired: false),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Self-reported financial details remain unverified until confirmed against official records by your group President or Secretary.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return 'This field is required.';
            }
            return null;
          },
        ),
      ],
    );
  }
}
