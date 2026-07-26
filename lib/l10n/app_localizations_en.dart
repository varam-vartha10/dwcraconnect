// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DWCRA Connect';

  @override
  String get tagline => 'Empowered Women, Stronger Communities';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginTitle => 'Login to DWCRA Connect';

  @override
  String get enterPhoneHint => 'Enter 10 digit number';

  @override
  String get enterPasswordHint => 'Enter your password';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get invalidMobile => 'Please enter a valid 10-digit mobile number';

  @override
  String get invalidPassword => 'Password must be at least 6 characters';

  @override
  String get invalidCredentials => 'Invalid phone number or password';

  @override
  String get loginSuccess => 'Login Successful';

  @override
  String get fullName => 'Full Name';

  @override
  String get aadhaarNumber => 'Aadhaar Number';

  @override
  String get village => 'Village';

  @override
  String get shgGroup => 'SHG Group';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get stepPersonal => 'Personal Details';

  @override
  String get stepGroup => 'Group Details';

  @override
  String get stepSecurity => 'Security';

  @override
  String get invalidAadhaar => 'Please enter a valid 12-digit Aadhaar number';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get required => 'Required';

  @override
  String get otpVerification => 'OTP Verification';

  @override
  String get otpSentTo => 'Enter the OTP sent to';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get didNotReceiveOtp => 'Didn\'t receive the OTP?';

  @override
  String get otpVerifiedSuccess => 'OTP Verified Successfully';

  @override
  String get invalidOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get enterMobileToReset => 'Enter your mobile number to reset password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get setNewPassword => 'Set New Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get passwordUpdated => 'Password Updated Successfully';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get home => 'Home';

  @override
  String get alerts => 'Alerts';

  @override
  String get profile => 'Profile';

  @override
  String get welcome => 'Welcome';

  @override
  String get namaste => 'Namaste';

  @override
  String get activeLoans => 'Active Loans';

  @override
  String get nextEmi => 'Next EMI';

  @override
  String get subsidy => 'Subsidy';

  @override
  String get lastPayment => 'Last Payment';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentActivity => 'No recent activities found.';

  @override
  String get loanDetails => 'Loan Details';

  @override
  String get totalLoanAmount => 'Total Loan Amount';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get remainingAmount => 'Remaining Amount';

  @override
  String get loanStatus => 'Loan Status';

  @override
  String get loanType => 'Loan Type';

  @override
  String get interestRate => 'Interest Rate';

  @override
  String get active => 'Active';

  @override
  String get repaid => 'Repaid';

  @override
  String get back => 'Back';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get emiDetails => 'EMI Details';

  @override
  String get emiAmount => 'EMI Amount';

  @override
  String get dueDate => 'Due Date';

  @override
  String get remainingEmiCount => 'Remaining EMI Count';

  @override
  String get nextEmiDate => 'Next EMI Date';

  @override
  String get repaymentSchedule => 'Repayment Schedule';

  @override
  String get remainingEmis => 'Remaining EMIs';

  @override
  String get timelyRepaymentTip =>
      'Timely repayment helps in getting higher credit limits for your SHG group.';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get searchTransactions => 'Search transactions...';

  @override
  String get filter => 'Filter';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get all => 'All';

  @override
  String get credit => 'Credit';

  @override
  String get debit => 'Debit';

  @override
  String get subsidyDetails => 'Subsidy Details';

  @override
  String get schemeName => 'Scheme Name';

  @override
  String get receivedDate => 'Received Date';

  @override
  String get status => 'Status';

  @override
  String get received => 'Received';

  @override
  String get pending => 'Pending';

  @override
  String get emiStatus => 'EMI Status';

  @override
  String get activeStatus => 'Active Status';

  @override
  String repaidPercent(int percent) {
    return '$percent% Repaid';
  }

  @override
  String receivedOn(String date) {
    return 'Received on $date';
  }

  @override
  String get subsidyAmount => 'Subsidy Amount';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get emiReminder => 'EMI Reminder';

  @override
  String get govScheme => 'Govt Scheme';

  @override
  String get loanUpdate => 'Loan Update';

  @override
  String get settings => 'Settings';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get groupInfo => 'Group Information';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get appVersion => 'App Version';

  @override
  String get aadhaarMasked => 'Aadhaar (Masked)';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get leaderDashboard => 'Leader Dashboard';

  @override
  String get totalMembers => 'Total Members';

  @override
  String get pendingEmi => 'Pending EMI';

  @override
  String get subsidyRecords => 'Subsidy Records';

  @override
  String get groupLedger => 'Group Ledger';

  @override
  String get reports => 'Reports';

  @override
  String get members => 'Members';

  @override
  String get member => 'Member';

  @override
  String get leader => 'Leader';

  @override
  String get groupAnalytics => 'Group Analytics';

  @override
  String get savings => 'Savings';

  @override
  String get repayment => 'Repayment';

  @override
  String get creditScore => 'Credit Score';

  @override
  String get communityPulse => 'Community Pulse';

  @override
  String get monthlyThriftCollected => 'Monthly thrift collected';

  @override
  String get repaymentDiscipline => 'Repayment discipline';

  @override
  String get trainingCompletion => 'Training completion';

  @override
  String get welcomeLeader => 'Welcome Leader,';

  @override
  String get memberList => 'Member List';

  @override
  String get searchMembers => 'Search members...';

  @override
  String get memberId => 'Member ID';

  @override
  String get name => 'Name';

  @override
  String get memberDetails => 'Member Details';

  @override
  String get memberDetailsTitle => 'Member Details';

  @override
  String get close => 'Close';

  @override
  String get totalLoanDistributed => 'Total Loan Distributed';

  @override
  String get totalLoanRepaid => 'Total Loan Repaid';

  @override
  String get outstandingAmount => 'Outstanding Amount';

  @override
  String get groupRepaymentProgress => 'Group Repayment Progress';

  @override
  String get monthlyCollectionTrend => 'Monthly Collection Trend';

  @override
  String get selectReportType => 'Select Report Type';

  @override
  String get monthlyCollection => 'Monthly Collection';

  @override
  String get recovery => 'Recovery';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String exportReport(String report) {
    return 'Export $report';
  }

  @override
  String get pdfExportSuccess => 'PDF Exported Successfully';

  @override
  String get excelExportSuccess => 'Excel Exported Successfully';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get category => 'Category';

  @override
  String get other => 'Other';

  @override
  String get enterAmountHint => 'Enter amount';

  @override
  String get save => 'Save';

  @override
  String get success => 'Success';

  @override
  String get loanRepayment => 'Loan Repayment';

  @override
  String get markAttendance => 'Mark Attendance';

  @override
  String get meetingAttendance => 'Meeting Attendance';

  @override
  String get groupMeeting => 'Group Meeting';

  @override
  String get location => 'Location';

  @override
  String get shgCenter => 'SHG Center';

  @override
  String groupMeetingAt(String meeting, String date) {
    return '$meeting - $date';
  }

  @override
  String get applyLoan => 'Apply for Loan';

  @override
  String get enterRequiredAmount => 'Enter Required Amount';

  @override
  String get purposeOfLoan => 'Purpose of Loan';

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get applicationSubmitted => 'Application Submitted Successfully';

  @override
  String get businessGrowth => 'Business Growth';

  @override
  String get emergency => 'Emergency';

  @override
  String get education => 'Education';

  @override
  String get trainingHub => 'Training Hub';

  @override
  String get finLitTitle => 'Financial Literacy 101';

  @override
  String get finLitDesc => 'Learn how to manage your SHG savings efficiently.';

  @override
  String get govSchemeTitle => 'Government Schemes 2026';

  @override
  String get govSchemeDesc =>
      'Explore the latest benefits for women entrepreneurs.';

  @override
  String get digiMarketTitle => 'Digital Marketing for SHGs';

  @override
  String get digiMarketDesc => 'How to sell your products online.';

  @override
  String get learnToGrow => 'Learn to Grow';

  @override
  String get newTrainingVideos => 'New Training Videos Available';

  @override
  String get chooseLanguage => 'Choose Your Language';

  @override
  String get selectLanguageToContinue => 'Select a language to continue';

  @override
  String get english => 'English';

  @override
  String get telugu => 'Telugu';

  @override
  String get continueBtn => 'Continue';

  @override
  String get languageChanged => 'Language Changed Successfully';

  @override
  String get june => 'June';

  @override
  String get may => 'May';

  @override
  String get april => 'April';

  @override
  String get march => 'March';

  @override
  String get loanBalance => 'Loan Balance';

  @override
  String get savingsProgress => 'Savings Progress';

  @override
  String get communityHub => 'Community Hub';

  @override
  String get groupMeetingTomorrow => 'Group Meeting Tomorrow';

  @override
  String get groupMeetingTomorrowDesc => '10:30 AM at Village Center';

  @override
  String get support => 'Support';

  @override
  String get awards => 'Awards';

  @override
  String amountSaved(String amount) {
    return '₹$amount Saved';
  }

  @override
  String get president => 'President';

  @override
  String get secretary => 'Secretary';

  @override
  String get preparingWorkspace => 'Preparing SHG workspace';

  @override
  String get sendRemindersToAll => 'Send Reminders to All';

  @override
  String get overdue => 'OVERDUE';

  @override
  String get totalPending => 'Total Pending';

  @override
  String newNotifications(int count) {
    return '$count New';
  }

  @override
  String get loans => 'Loans';

  @override
  String get searchSubsidies => 'Search subsidies...';

  @override
  String get loanAmount => 'Loan Amount';

  @override
  String get remaining => 'Remaining';

  @override
  String get shgBankLinkage => 'SHG Bank Linkage';

  @override
  String get yearly => 'Yearly';

  @override
  String get cancel => 'Cancel';

  @override
  String get changePassword => 'Change Password';
}
