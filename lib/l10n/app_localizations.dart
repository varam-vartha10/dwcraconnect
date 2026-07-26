import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DWCRA Connect'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Empowered Women, Stronger Communities'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to DWCRA Connect'**
  String get loginTitle;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 digit number'**
  String get enterPhoneHint;

  /// No description provided for @enterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordHint;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit mobile number'**
  String get invalidMobile;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get invalidPassword;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number or password'**
  String get invalidCredentials;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get loginSuccess;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @shgGroup.
  ///
  /// In en, this message translates to:
  /// **'SHG Group'**
  String get shgGroup;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @stepPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get stepPersonal;

  /// No description provided for @stepGroup.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get stepGroup;

  /// No description provided for @stepSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get stepSecurity;

  /// No description provided for @invalidAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 12-digit Aadhaar number'**
  String get invalidAadhaar;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to'**
  String get otpSentTo;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @didNotReceiveOtp.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the OTP?'**
  String get didNotReceiveOtp;

  /// No description provided for @otpVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP Verified Successfully'**
  String get otpVerifiedSuccess;

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get invalidOtp;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @enterMobileToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to reset password'**
  String get enterMobileToReset;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password Updated Successfully'**
  String get passwordUpdated;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @activeLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get activeLoans;

  /// No description provided for @nextEmi.
  ///
  /// In en, this message translates to:
  /// **'Next EMI'**
  String get nextEmi;

  /// No description provided for @subsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get subsidy;

  /// No description provided for @lastPayment.
  ///
  /// In en, this message translates to:
  /// **'Last Payment'**
  String get lastPayment;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activities found.'**
  String get noRecentActivity;

  /// No description provided for @loanDetails.
  ///
  /// In en, this message translates to:
  /// **'Loan Details'**
  String get loanDetails;

  /// No description provided for @totalLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Amount'**
  String get totalLoanAmount;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// No description provided for @loanStatus.
  ///
  /// In en, this message translates to:
  /// **'Loan Status'**
  String get loanStatus;

  /// No description provided for @loanType.
  ///
  /// In en, this message translates to:
  /// **'Loan Type'**
  String get loanType;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interestRate;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @repaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid'**
  String get repaid;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @emiDetails.
  ///
  /// In en, this message translates to:
  /// **'EMI Details'**
  String get emiDetails;

  /// No description provided for @emiAmount.
  ///
  /// In en, this message translates to:
  /// **'EMI Amount'**
  String get emiAmount;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @remainingEmiCount.
  ///
  /// In en, this message translates to:
  /// **'Remaining EMI Count'**
  String get remainingEmiCount;

  /// No description provided for @nextEmiDate.
  ///
  /// In en, this message translates to:
  /// **'Next EMI Date'**
  String get nextEmiDate;

  /// No description provided for @repaymentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment Schedule'**
  String get repaymentSchedule;

  /// No description provided for @remainingEmis.
  ///
  /// In en, this message translates to:
  /// **'Remaining EMIs'**
  String get remainingEmis;

  /// No description provided for @timelyRepaymentTip.
  ///
  /// In en, this message translates to:
  /// **'Timely repayment helps in getting higher credit limits for your SHG group.'**
  String get timelyRepaymentTip;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get searchTransactions;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @subsidyDetails.
  ///
  /// In en, this message translates to:
  /// **'Subsidy Details'**
  String get subsidyDetails;

  /// No description provided for @schemeName.
  ///
  /// In en, this message translates to:
  /// **'Scheme Name'**
  String get schemeName;

  /// No description provided for @receivedDate.
  ///
  /// In en, this message translates to:
  /// **'Received Date'**
  String get receivedDate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @emiStatus.
  ///
  /// In en, this message translates to:
  /// **'EMI Status'**
  String get emiStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get activeStatus;

  /// No description provided for @repaidPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Repaid'**
  String repaidPercent(int percent);

  /// No description provided for @receivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received on {date}'**
  String receivedOn(String date);

  /// No description provided for @subsidyAmount.
  ///
  /// In en, this message translates to:
  /// **'Subsidy Amount'**
  String get subsidyAmount;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @emiReminder.
  ///
  /// In en, this message translates to:
  /// **'EMI Reminder'**
  String get emiReminder;

  /// No description provided for @govScheme.
  ///
  /// In en, this message translates to:
  /// **'Govt Scheme'**
  String get govScheme;

  /// No description provided for @loanUpdate.
  ///
  /// In en, this message translates to:
  /// **'Loan Update'**
  String get loanUpdate;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Information'**
  String get groupInfo;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @aadhaarMasked.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar (Masked)'**
  String get aadhaarMasked;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @leaderDashboard.
  ///
  /// In en, this message translates to:
  /// **'Leader Dashboard'**
  String get leaderDashboard;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @pendingEmi.
  ///
  /// In en, this message translates to:
  /// **'Pending EMI'**
  String get pendingEmi;

  /// No description provided for @subsidyRecords.
  ///
  /// In en, this message translates to:
  /// **'Subsidy Records'**
  String get subsidyRecords;

  /// No description provided for @groupLedger.
  ///
  /// In en, this message translates to:
  /// **'Group Ledger'**
  String get groupLedger;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @leader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get leader;

  /// No description provided for @groupAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Group Analytics'**
  String get groupAnalytics;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @repayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repayment;

  /// No description provided for @creditScore.
  ///
  /// In en, this message translates to:
  /// **'Credit Score'**
  String get creditScore;

  /// No description provided for @communityPulse.
  ///
  /// In en, this message translates to:
  /// **'Community Pulse'**
  String get communityPulse;

  /// No description provided for @monthlyThriftCollected.
  ///
  /// In en, this message translates to:
  /// **'Monthly thrift collected'**
  String get monthlyThriftCollected;

  /// No description provided for @repaymentDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Repayment discipline'**
  String get repaymentDiscipline;

  /// No description provided for @trainingCompletion.
  ///
  /// In en, this message translates to:
  /// **'Training completion'**
  String get trainingCompletion;

  /// No description provided for @welcomeLeader.
  ///
  /// In en, this message translates to:
  /// **'Welcome Leader,'**
  String get welcomeLeader;

  /// No description provided for @memberList.
  ///
  /// In en, this message translates to:
  /// **'Member List'**
  String get memberList;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members...'**
  String get searchMembers;

  /// No description provided for @memberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberId;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @memberDetails.
  ///
  /// In en, this message translates to:
  /// **'Member Details'**
  String get memberDetails;

  /// No description provided for @memberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Member Details'**
  String get memberDetailsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @totalLoanDistributed.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Distributed'**
  String get totalLoanDistributed;

  /// No description provided for @totalLoanRepaid.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Repaid'**
  String get totalLoanRepaid;

  /// No description provided for @outstandingAmount.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Amount'**
  String get outstandingAmount;

  /// No description provided for @groupRepaymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Group Repayment Progress'**
  String get groupRepaymentProgress;

  /// No description provided for @monthlyCollectionTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection Trend'**
  String get monthlyCollectionTrend;

  /// No description provided for @selectReportType.
  ///
  /// In en, this message translates to:
  /// **'Select Report Type'**
  String get selectReportType;

  /// No description provided for @monthlyCollection.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection'**
  String get monthlyCollection;

  /// No description provided for @recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export {report}'**
  String exportReport(String report);

  /// No description provided for @pdfExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF Exported Successfully'**
  String get pdfExportSuccess;

  /// No description provided for @excelExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excel Exported Successfully'**
  String get excelExportSuccess;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @enterAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmountHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loanRepayment.
  ///
  /// In en, this message translates to:
  /// **'Loan Repayment'**
  String get loanRepayment;

  /// No description provided for @markAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark Attendance'**
  String get markAttendance;

  /// No description provided for @meetingAttendance.
  ///
  /// In en, this message translates to:
  /// **'Meeting Attendance'**
  String get meetingAttendance;

  /// No description provided for @groupMeeting.
  ///
  /// In en, this message translates to:
  /// **'Group Meeting'**
  String get groupMeeting;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @shgCenter.
  ///
  /// In en, this message translates to:
  /// **'SHG Center'**
  String get shgCenter;

  /// No description provided for @groupMeetingAt.
  ///
  /// In en, this message translates to:
  /// **'{meeting} - {date}'**
  String groupMeetingAt(String meeting, String date);

  /// No description provided for @applyLoan.
  ///
  /// In en, this message translates to:
  /// **'Apply for Loan'**
  String get applyLoan;

  /// No description provided for @enterRequiredAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Required Amount'**
  String get enterRequiredAmount;

  /// No description provided for @purposeOfLoan.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Loan'**
  String get purposeOfLoan;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted Successfully'**
  String get applicationSubmitted;

  /// No description provided for @businessGrowth.
  ///
  /// In en, this message translates to:
  /// **'Business Growth'**
  String get businessGrowth;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @trainingHub.
  ///
  /// In en, this message translates to:
  /// **'Training Hub'**
  String get trainingHub;

  /// No description provided for @finLitTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Literacy 101'**
  String get finLitTitle;

  /// No description provided for @finLitDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to manage your SHG savings efficiently.'**
  String get finLitDesc;

  /// No description provided for @govSchemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes 2026'**
  String get govSchemeTitle;

  /// No description provided for @govSchemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Explore the latest benefits for women entrepreneurs.'**
  String get govSchemeDesc;

  /// No description provided for @digiMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Marketing for SHGs'**
  String get digiMarketTitle;

  /// No description provided for @digiMarketDesc.
  ///
  /// In en, this message translates to:
  /// **'How to sell your products online.'**
  String get digiMarketDesc;

  /// No description provided for @learnToGrow.
  ///
  /// In en, this message translates to:
  /// **'Learn to Grow'**
  String get learnToGrow;

  /// No description provided for @newTrainingVideos.
  ///
  /// In en, this message translates to:
  /// **'New Training Videos Available'**
  String get newTrainingVideos;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguage;

  /// No description provided for @selectLanguageToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a language to continue'**
  String get selectLanguageToContinue;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language Changed Successfully'**
  String get languageChanged;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @loanBalance.
  ///
  /// In en, this message translates to:
  /// **'Loan Balance'**
  String get loanBalance;

  /// No description provided for @savingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Savings Progress'**
  String get savingsProgress;

  /// No description provided for @communityHub.
  ///
  /// In en, this message translates to:
  /// **'Community Hub'**
  String get communityHub;

  /// No description provided for @groupMeetingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Group Meeting Tomorrow'**
  String get groupMeetingTomorrow;

  /// No description provided for @groupMeetingTomorrowDesc.
  ///
  /// In en, this message translates to:
  /// **'10:30 AM at Village Center'**
  String get groupMeetingTomorrowDesc;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @awards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get awards;

  /// No description provided for @amountSaved.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} Saved'**
  String amountSaved(String amount);

  /// No description provided for @president.
  ///
  /// In en, this message translates to:
  /// **'President'**
  String get president;

  /// No description provided for @secretary.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get secretary;

  /// No description provided for @preparingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Preparing SHG workspace'**
  String get preparingWorkspace;

  /// No description provided for @sendRemindersToAll.
  ///
  /// In en, this message translates to:
  /// **'Send Reminders to All'**
  String get sendRemindersToAll;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdue;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @newNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count} New'**
  String newNotifications(int count);

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @searchSubsidies.
  ///
  /// In en, this message translates to:
  /// **'Search subsidies...'**
  String get searchSubsidies;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loanAmount;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @shgBankLinkage.
  ///
  /// In en, this message translates to:
  /// **'SHG Bank Linkage'**
  String get shgBankLinkage;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
