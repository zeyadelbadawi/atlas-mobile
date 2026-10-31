import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Atlas'**
  String get appName;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your academy'**
  String get pickerTitle;

  /// No description provided for @pickerBody.
  ///
  /// In en, this message translates to:
  /// **'Type your academy\'s name as it appears in its link, or scan its QR code.'**
  String get pickerBody;

  /// No description provided for @pickerFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Academy name'**
  String get pickerFieldLabel;

  /// No description provided for @pickerFieldHint.
  ///
  /// In en, this message translates to:
  /// **'academy'**
  String get pickerFieldHint;

  /// No description provided for @pickerCustomDomain.
  ///
  /// In en, this message translates to:
  /// **'Your academy has its own domain?'**
  String get pickerCustomDomain;

  /// No description provided for @pickerCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Academy website address'**
  String get pickerCustomLabel;

  /// No description provided for @pickerCustomHint.
  ///
  /// In en, this message translates to:
  /// **'learn.your-academy.com'**
  String get pickerCustomHint;

  /// No description provided for @pickerAtlasName.
  ///
  /// In en, this message translates to:
  /// **'Academy on Atlas? Type just its name'**
  String get pickerAtlasName;

  /// No description provided for @catalogClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get catalogClearSearch;

  /// No description provided for @pickerNotFound.
  ///
  /// In en, this message translates to:
  /// **'No academy found at {host}. Check the name, or ask your academy for its link.'**
  String pickerNotFound(String host);

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @pickerRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from recent academies.'**
  String pickerRemoved(String name);

  /// No description provided for @pickerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open academy'**
  String get pickerOpen;

  /// No description provided for @pickerRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent academies'**
  String get pickerRecent;

  /// No description provided for @pickerRemoveRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pickerRemoveRecent;

  /// No description provided for @pickerEmptyField.
  ///
  /// In en, this message translates to:
  /// **'Type your academy\'s name.'**
  String get pickerEmptyField;

  /// No description provided for @pickerInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an academy name or a website address. Check it and try again.'**
  String get pickerInvalid;

  /// No description provided for @pickerAboutAtlas.
  ///
  /// In en, this message translates to:
  /// **'About Atlas'**
  String get pickerAboutAtlas;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmail;

  /// No description provided for @signInPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPassword;

  /// No description provided for @signInSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInSubmit;

  /// No description provided for @signInForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get signInForgot;

  /// No description provided for @signInNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to this academy?'**
  String get signInNoAccount;

  /// No description provided for @signInCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signInCreateAccount;

  /// No description provided for @signInChangeAcademy.
  ///
  /// In en, this message translates to:
  /// **'Change academy'**
  String get signInChangeAcademy;

  /// No description provided for @signInNotMember.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this academy yet. Join it with your Atlas password.'**
  String get signInNotMember;

  /// No description provided for @signInJoinAcademy.
  ///
  /// In en, this message translates to:
  /// **'Join this academy'**
  String get signInJoinAcademy;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an email like name@example.com.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get validationPasswordShort;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get validationNameRequired;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number.'**
  String get validationPhoneRequired;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get codeTitle;

  /// No description provided for @codeBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}. It works for 10 minutes.'**
  String codeBody(String email);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @codeRemember.
  ///
  /// In en, this message translates to:
  /// **'Remember this device'**
  String get codeRemember;

  /// No description provided for @codeRememberHint.
  ///
  /// In en, this message translates to:
  /// **'You won\'t need a code here next time.'**
  String get codeRememberHint;

  /// No description provided for @codeVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get codeVerify;

  /// No description provided for @codeResend.
  ///
  /// In en, this message translates to:
  /// **'Send a new code'**
  String get codeResend;

  /// No description provided for @codeResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send a new code in {seconds}s'**
  String codeResendIn(String seconds);

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way. It can take a minute.'**
  String get codeResent;

  /// No description provided for @totpTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get totpTitle;

  /// No description provided for @totpBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get totpBody;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get registerName;

  /// No description provided for @registerPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get registerPhone;

  /// No description provided for @registerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'The academy can use it to contact you about your courses.'**
  String get registerPhoneHint;

  /// No description provided for @registerPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get registerPassword;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get registerPasswordHint;

  /// No description provided for @registerAge.
  ///
  /// In en, this message translates to:
  /// **'I am 13 or older'**
  String get registerAge;

  /// No description provided for @registerAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get registerAgreePrefix;

  /// No description provided for @registerAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get registerAgreeAnd;

  /// No description provided for @registerTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get registerTerms;

  /// No description provided for @registerPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerPrivacy;

  /// No description provided for @registerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmit;

  /// No description provided for @registerNeedsConsent.
  ///
  /// In en, this message translates to:
  /// **'Confirm your age and accept the terms to continue.'**
  String get registerNeedsConsent;

  /// No description provided for @registerExisting.
  ///
  /// In en, this message translates to:
  /// **'This email already has an Atlas account. Sign in with its password.'**
  String get registerExisting;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to choose a new password.'**
  String get forgotBody;

  /// No description provided for @forgotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get forgotSubmit;

  /// No description provided for @forgotSent.
  ///
  /// In en, this message translates to:
  /// **'If {email} has an account here, a reset link is on its way. Open it on this phone or any browser.'**
  String forgotSent(String email);

  /// No description provided for @appleLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple to your account'**
  String get appleLinkTitle;

  /// No description provided for @appleLinkBody.
  ///
  /// In en, this message translates to:
  /// **'{email} already has an account. Enter its password once to sign in with Apple from now on.'**
  String appleLinkBody(String email);

  /// No description provided for @appleLinkSubmit.
  ///
  /// In en, this message translates to:
  /// **'Connect and sign in'**
  String get appleLinkSubmit;

  /// No description provided for @appleCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish creating your account'**
  String get appleCreateTitle;

  /// No description provided for @appleCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Your name and email come from Apple. Add your mobile number to finish.'**
  String get appleCreateBody;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCourses.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get tabCourses;

  /// No description provided for @tabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// No description provided for @tabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tabAccount;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountAppearance;

  /// No description provided for @accountSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get accountSystem;

  /// No description provided for @accountLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get accountLight;

  /// No description provided for @accountDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get accountDark;

  /// No description provided for @accountArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get accountArabic;

  /// No description provided for @accountEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get accountEnglish;

  /// No description provided for @accountChangeAcademy.
  ///
  /// In en, this message translates to:
  /// **'Change academy'**
  String get accountChangeAcademy;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of {academy} on this phone?'**
  String accountSignOutConfirm(String academy);

  /// No description provided for @accountLegal.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get accountLegal;

  /// No description provided for @accountAbout.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get accountAbout;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get legalTitle;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTerms;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacy;

  /// No description provided for @legalRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get legalRefund;

  /// No description provided for @legalCookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get legalCookie;

  /// No description provided for @legalContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get legalContents;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String legalLastUpdated(String date);

  /// No description provided for @legalEffective.
  ///
  /// In en, this message translates to:
  /// **'Effective: {date}'**
  String legalEffective(String date);

  /// No description provided for @legalBackToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get legalBackToTop;

  /// No description provided for @legalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This page didn\'t load. Check your connection and try again.'**
  String get legalLoadFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Atlas is the platform your academy uses for its courses. This app shows the courses you are enrolled in and free courses you can join. It sells nothing.'**
  String get aboutBody;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get aboutCompany;

  /// No description provided for @aboutLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get aboutLegalName;

  /// No description provided for @aboutAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get aboutAddress;

  /// No description provided for @aboutAddressValue.
  ///
  /// In en, this message translates to:
  /// **'6th of October City, Giza, Egypt'**
  String get aboutAddressValue;

  /// No description provided for @aboutEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutEmail;

  /// No description provided for @aboutWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get aboutWhatsapp;

  /// No description provided for @aboutPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get aboutPhone;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Atlas to continue'**
  String get updateTitle;

  /// No description provided for @updateBody.
  ///
  /// In en, this message translates to:
  /// **'This version no longer works with your academy. The update keeps your sign-in and progress.'**
  String get updateBody;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Atlas is being updated'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be back shortly. Your progress is saved.'**
  String get maintenanceBody;

  /// No description provided for @signedInTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in'**
  String get signedInTitle;

  /// No description provided for @signedInBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}.'**
  String signedInBody(String name);

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume lesson'**
  String get homeResume;

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Start the course'**
  String get homeStart;

  /// No description provided for @homeDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get homeDueSoon;

  /// No description provided for @homeAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'From your academy'**
  String get homeAnnouncements;

  /// No description provided for @homeMyCourses.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get homeMyCourses;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Courses you join at {academy} appear here.'**
  String homeEmptyBody(String academy);

  /// No description provided for @homeAllDone.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date. Pick a course to review.'**
  String get homeAllDone;

  /// No description provided for @unitLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get unitLesson;

  /// No description provided for @unitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get unitQuiz;

  /// No description provided for @unitAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get unitAssignment;

  /// No description provided for @unitLive.
  ///
  /// In en, this message translates to:
  /// **'Live session'**
  String get unitLive;

  /// No description provided for @countOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String countOf(String done, String total);

  /// No description provided for @lessonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} lesson} other{{n} lessons}}'**
  String lessonsCount(int count, String n);

  /// No description provided for @percentDone.
  ///
  /// In en, this message translates to:
  /// **'{percent}% done'**
  String percentDone(String percent);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String minutesLeft(String minutes);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutes(String minutes);

  /// No description provided for @dueAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment due {time}'**
  String dueAssignment(String time);

  /// No description provided for @dueLive.
  ///
  /// In en, this message translates to:
  /// **'Live session {time}'**
  String dueLive(String time);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @coursesTitle.
  ///
  /// In en, this message translates to:
  /// **'My courses'**
  String get coursesTitle;

  /// No description provided for @coursesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get coursesAll;

  /// No description provided for @coursesInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get coursesInProgress;

  /// No description provided for @coursesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get coursesCompleted;

  /// No description provided for @coursesNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get coursesNotStarted;

  /// No description provided for @coursesNoneInFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get coursesNoneInFilter;

  /// No description provided for @courseUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit {number}'**
  String courseUnit(String number);

  /// No description provided for @courseContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get courseContinue;

  /// No description provided for @courseReview.
  ///
  /// In en, this message translates to:
  /// **'Review from the start'**
  String get courseReview;

  /// No description provided for @courseCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Course complete'**
  String get courseCompletedTitle;

  /// No description provided for @courseCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You finished every required lesson.'**
  String get courseCompletedBody;

  /// No description provided for @courseCertificatePending.
  ///
  /// In en, this message translates to:
  /// **'Your certificate is being prepared.'**
  String get courseCertificatePending;

  /// No description provided for @courseAccessEnded.
  ///
  /// In en, this message translates to:
  /// **'Your access to this course has ended.'**
  String get courseAccessEnded;

  /// No description provided for @lockPrevious.
  ///
  /// In en, this message translates to:
  /// **'Finish the previous item first'**
  String get lockPrevious;

  /// No description provided for @lockScheduled.
  ///
  /// In en, this message translates to:
  /// **'Opens {date}'**
  String lockScheduled(String date);

  /// No description provided for @lockNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not open yet'**
  String get lockNotStarted;

  /// No description provided for @lockAccessEnded.
  ///
  /// In en, this message translates to:
  /// **'Access ended'**
  String get lockAccessEnded;

  /// No description provided for @lockQuizNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Pass the quiz before this'**
  String get lockQuizNotPassed;

  /// No description provided for @itemOnWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open on the academy website'**
  String get itemOnWebsite;

  /// No description provided for @lessonMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get lessonMarkDone;

  /// No description provided for @lessonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get lessonDone;

  /// No description provided for @lessonNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String lessonNext(String title);

  /// No description provided for @lessonBackToCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to the course'**
  String get lessonBackToCourse;

  /// No description provided for @lessonWatchFirst.
  ///
  /// In en, this message translates to:
  /// **'Watch {percent}% of the video to mark it done.'**
  String lessonWatchFirst(String percent);

  /// No description provided for @lessonResources.
  ///
  /// In en, this message translates to:
  /// **'Lesson files'**
  String get lessonResources;

  /// No description provided for @lessonOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get lessonOpenFile;

  /// No description provided for @lessonOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get lessonOpenLink;

  /// No description provided for @lessonVideoOnWeb.
  ///
  /// In en, this message translates to:
  /// **'This video plays on the academy website for now.'**
  String get lessonVideoOnWeb;

  /// No description provided for @lessonOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get lessonOpenWebsite;

  /// No description provided for @playerRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop screen recording to keep watching.'**
  String get playerRecording;

  /// No description provided for @playerPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// No description provided for @playerBack10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get playerBack10;

  /// No description provided for @playerForward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get playerForward10;

  /// No description provided for @playerFailed.
  ///
  /// In en, this message translates to:
  /// **'This video couldn\'t play. Check your connection and try again.'**
  String get playerFailed;

  /// No description provided for @takeoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Watching on another device'**
  String get takeoverTitle;

  /// No description provided for @takeoverBody.
  ///
  /// In en, this message translates to:
  /// **'{device} is using your lessons now. Continue here instead? The other device will stop.'**
  String takeoverBody(String device);

  /// No description provided for @takeoverUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Another device'**
  String get takeoverUnknownDevice;

  /// No description provided for @takeoverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue here'**
  String get takeoverConfirm;

  /// No description provided for @deviceLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Device limit reached'**
  String get deviceLimitTitle;

  /// No description provided for @deviceLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Remove a device you no longer use, then open the lesson again.'**
  String get deviceLimitBody;

  /// No description provided for @deviceLimitManage.
  ///
  /// In en, this message translates to:
  /// **'Manage devices'**
  String get deviceLimitManage;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get devicesTitle;

  /// No description provided for @devicesBody.
  ///
  /// In en, this message translates to:
  /// **'You can learn on up to {count} devices.'**
  String devicesBody(String count);

  /// No description provided for @devicesThis.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get devicesThis;

  /// No description provided for @devicesLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last used {time}'**
  String devicesLastSeen(String time);

  /// No description provided for @devicesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get devicesRemove;

  /// No description provided for @devicesRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {device}? It will need a free slot to play lessons again.'**
  String devicesRemoveConfirm(String device);

  /// No description provided for @accountDevices.
  ///
  /// In en, this message translates to:
  /// **'My devices'**
  String get accountDevices;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// No description provided for @offlineBody.
  ///
  /// In en, this message translates to:
  /// **'Check your Wi-Fi or mobile data, then try again.'**
  String get offlineBody;

  /// No description provided for @loadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this'**
  String get loadFailedTitle;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'This didn\'t load. Check your connection and try again.'**
  String get loadFailed;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeGreeting(String name);

  /// No description provided for @coursesCover.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get coursesCover;

  /// No description provided for @quizInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get quizInstructions;

  /// No description provided for @quizInstructionsDefault.
  ///
  /// In en, this message translates to:
  /// **'Answer every question, then submit your attempt.'**
  String get quizInstructionsDefault;

  /// No description provided for @quizFactQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get quizFactQuestions;

  /// No description provided for @quizFactTime.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get quizFactTime;

  /// No description provided for @quizNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get quizNoTimeLimit;

  /// No description provided for @quizFactAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get quizFactAttempts;

  /// No description provided for @quizAttemptsOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used'**
  String quizAttemptsOf(String used, String total);

  /// No description provided for @quizAttemptsUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{used} used, unlimited'**
  String quizAttemptsUnlimited(String used);

  /// No description provided for @quizFactPassing.
  ///
  /// In en, this message translates to:
  /// **'Passing score'**
  String get quizFactPassing;

  /// No description provided for @quizPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String quizPercent(String value);

  /// No description provided for @quizFactOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get quizFactOpens;

  /// No description provided for @quizFactDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get quizFactDue;

  /// No description provided for @quizFactCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get quizFactCloses;

  /// No description provided for @quizFactCounts.
  ///
  /// In en, this message translates to:
  /// **'Which attempt counts'**
  String get quizFactCounts;

  /// No description provided for @quizPolicyHighest.
  ///
  /// In en, this message translates to:
  /// **'Your highest score'**
  String get quizPolicyHighest;

  /// No description provided for @quizPolicyLatest.
  ///
  /// In en, this message translates to:
  /// **'Your latest attempt'**
  String get quizPolicyLatest;

  /// No description provided for @quizPolicyFirst.
  ///
  /// In en, this message translates to:
  /// **'Your first attempt'**
  String get quizPolicyFirst;

  /// No description provided for @quizPolicyAverage.
  ///
  /// In en, this message translates to:
  /// **'The average of your attempts'**
  String get quizPolicyAverage;

  /// No description provided for @quizTimerNote.
  ///
  /// In en, this message translates to:
  /// **'The clock starts when you press Start and keeps running even if you close the app. When it reaches zero, the answers you have saved are submitted automatically.'**
  String get quizTimerNote;

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get quizStart;

  /// No description provided for @quizResume.
  ///
  /// In en, this message translates to:
  /// **'Resume quiz'**
  String get quizResume;

  /// No description provided for @quizAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No attempts left} =1{1 attempt left} other{{n} attempts left}}'**
  String quizAttemptsLeft(int count, String n);

  /// No description provided for @quizIntegrityTitle.
  ///
  /// In en, this message translates to:
  /// **'What is recorded during this quiz'**
  String get quizIntegrityTitle;

  /// No description provided for @quizIntegrityRecorded.
  ///
  /// In en, this message translates to:
  /// **'While the quiz is open, these are recorded with the time they happened: leaving the app (for another app or the home screen) and coming back, and a connection check once a minute. Your reviewer sees them with plain explanations — they are prompts for a conversation, not proof of anything.'**
  String get quizIntegrityRecorded;

  /// No description provided for @quizIntegrityMonitor.
  ///
  /// In en, this message translates to:
  /// **'You will not be interrupted. The record is shown to your reviewer with your attempt.'**
  String get quizIntegrityMonitor;

  /// No description provided for @quizIntegrityWarn.
  ///
  /// In en, this message translates to:
  /// **'You will be warned each time one is recorded. The limit is {n}; reaching it flags the attempt for review.'**
  String quizIntegrityWarn(String n);

  /// No description provided for @quizIntegrityStrict.
  ///
  /// In en, this message translates to:
  /// **'You will be warned each time one is recorded. When {n} have been recorded, the quiz is submitted automatically with the answers you have saved.'**
  String quizIntegrityStrict(String n);

  /// No description provided for @quizIntegrityFullscreen.
  ///
  /// In en, this message translates to:
  /// **'The app shows the quiz on the whole screen. Leaving the app is recorded.'**
  String get quizIntegrityFullscreen;

  /// No description provided for @quizIntegrityHonest.
  ///
  /// In en, this message translates to:
  /// **'Atlas never uses your camera or microphone, never records your screen or what you type, and sees nothing outside this quiz. Nothing is blocked.'**
  String get quizIntegrityHonest;

  /// No description provided for @quizIntegrityAck.
  ///
  /// In en, this message translates to:
  /// **'I understand what is recorded during this quiz.'**
  String get quizIntegrityAck;

  /// No description provided for @quizQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String quizQuestionOf(String current, String total);

  /// No description provided for @quizPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get quizPrevious;

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// No description provided for @quizSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit attempt'**
  String get quizSubmit;

  /// No description provided for @quizSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this attempt?'**
  String get quizSubmitTitle;

  /// No description provided for @quizSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be able to change your answers after submitting.'**
  String get quizSubmitBody;

  /// No description provided for @quizSubmitUnanswered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question is still unanswered (question {numbers}). Unanswered questions count as incorrect. You won\'t be able to change your answers after submitting.} other{{n} questions are still unanswered (questions {numbers}). Unanswered questions count as incorrect. You won\'t be able to change your answers after submitting.}}'**
  String quizSubmitUnanswered(int count, String numbers, String n);

  /// No description provided for @quizSubmitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get quizSubmitConfirm;

  /// No description provided for @quizKeepAnswering.
  ///
  /// In en, this message translates to:
  /// **'Keep answering'**
  String get quizKeepAnswering;

  /// No description provided for @quizSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get quizSaving;

  /// No description provided for @quizOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — will retry'**
  String get quizOffline;

  /// No description provided for @quizUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get quizUnsaved;

  /// No description provided for @quizSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quizSaved;

  /// No description provided for @quizNotSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get quizNotSavedYet;

  /// No description provided for @quizAnswered.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} answered'**
  String quizAnswered(String answered, String total);

  /// No description provided for @quizTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get quizTimeLeft;

  /// No description provided for @quizTimerHidden.
  ///
  /// In en, this message translates to:
  /// **'Timed — the clock is hidden'**
  String get quizTimerHidden;

  /// No description provided for @quizHurry.
  ///
  /// In en, this message translates to:
  /// **'Finish up'**
  String get quizHurry;

  /// No description provided for @quizAnnounceMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute left} other{{n} minutes left}}'**
  String quizAnnounceMinutes(int count, String n);

  /// No description provided for @quizAnnounceSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n} seconds left'**
  String quizAnnounceSeconds(String n);

  /// No description provided for @quizYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get quizYourAnswer;

  /// No description provided for @quizTypeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer'**
  String get quizTypeAnswer;

  /// No description provided for @quizShortHint.
  ///
  /// In en, this message translates to:
  /// **'A short answer. Capitalisation does not matter.'**
  String get quizShortHint;

  /// No description provided for @quizEssayHint.
  ///
  /// In en, this message translates to:
  /// **'This question is graded by a reviewer.'**
  String get quizEssayHint;

  /// No description provided for @quizPoints.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 point} other{{n} points}}'**
  String quizPoints(int count, String n);

  /// No description provided for @quizChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one answer'**
  String get quizChooseOne;

  /// No description provided for @quizChooseAll.
  ///
  /// In en, this message translates to:
  /// **'Choose all that apply'**
  String get quizChooseAll;

  /// No description provided for @quizFlag.
  ///
  /// In en, this message translates to:
  /// **'Mark for review'**
  String get quizFlag;

  /// No description provided for @quizUnflag.
  ///
  /// In en, this message translates to:
  /// **'Remove mark'**
  String get quizUnflag;

  /// No description provided for @quizNavItem.
  ///
  /// In en, this message translates to:
  /// **'Question {number}, {state}'**
  String quizNavItem(String number, String state);

  /// No description provided for @quizStateAnswered.
  ///
  /// In en, this message translates to:
  /// **'answered'**
  String get quizStateAnswered;

  /// No description provided for @quizStateUnanswered.
  ///
  /// In en, this message translates to:
  /// **'not answered'**
  String get quizStateUnanswered;

  /// No description provided for @quizStateFlagged.
  ///
  /// In en, this message translates to:
  /// **'marked for review'**
  String get quizStateFlagged;

  /// No description provided for @quizEventTitle.
  ///
  /// In en, this message translates to:
  /// **'An event was recorded'**
  String get quizEventTitle;

  /// No description provided for @quizEventWarn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event has been recorded on this attempt. Stay in the app until you submit.} other{{n} events have been recorded on this attempt. Stay in the app until you submit.}}'**
  String quizEventWarn(int count, String n);

  /// No description provided for @quizEventStrict.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max} events recorded. When the limit is reached, the quiz is submitted automatically.'**
  String quizEventStrict(String n, String max);

  /// No description provided for @quizEventDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Another event was recorded'**
  String get quizEventDialogTitle;

  /// No description provided for @quizEventDialogWarn.
  ///
  /// In en, this message translates to:
  /// **'Your reviewer will see the record alongside your answers.'**
  String get quizEventDialogWarn;

  /// No description provided for @quizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue quiz'**
  String get quizContinue;

  /// No description provided for @quizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your result'**
  String get quizResultTitle;

  /// No description provided for @quizPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get quizPassed;

  /// No description provided for @quizFailed.
  ///
  /// In en, this message translates to:
  /// **'Not passed'**
  String get quizFailed;

  /// No description provided for @quizPointsOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} points'**
  String quizPointsOf(String earned, String total);

  /// No description provided for @quizPassingLine.
  ///
  /// In en, this message translates to:
  /// **'Passing score {score}%'**
  String quizPassingLine(String score);

  /// No description provided for @quizCounted.
  ///
  /// In en, this message translates to:
  /// **'Counted score: {score}%'**
  String quizCounted(String score);

  /// No description provided for @quizScoreWithheldDue.
  ///
  /// In en, this message translates to:
  /// **'Your score will be shown after the due date.'**
  String get quizScoreWithheldDue;

  /// No description provided for @quizScoreWithheldAttempts.
  ///
  /// In en, this message translates to:
  /// **'Your score will be shown once you have used all your attempts.'**
  String get quizScoreWithheldAttempts;

  /// No description provided for @quizScoreWithheldNever.
  ///
  /// In en, this message translates to:
  /// **'This quiz does not show scores.'**
  String get quizScoreWithheldNever;

  /// No description provided for @quizScoreWithheldSoon.
  ///
  /// In en, this message translates to:
  /// **'Your score is being prepared.'**
  String get quizScoreWithheldSoon;

  /// No description provided for @quizAnswersWithheld.
  ///
  /// In en, this message translates to:
  /// **'Correct answers are not shown for this attempt yet.'**
  String get quizAnswersWithheld;

  /// No description provided for @quizSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Attempt submitted'**
  String get quizSubmittedTitle;

  /// No description provided for @quizTimeRanOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Time ran out'**
  String get quizTimeRanOutTitle;

  /// No description provided for @quizTimeRanOut.
  ///
  /// In en, this message translates to:
  /// **'Time ran out. Your answers were submitted automatically.'**
  String get quizTimeRanOut;

  /// No description provided for @quizAutoIntegrityTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted automatically'**
  String get quizAutoIntegrityTitle;

  /// No description provided for @quizAutoIntegrity.
  ///
  /// In en, this message translates to:
  /// **'The quiz was submitted because the recorded-event limit was reached. The answers you had saved were graded as they were.'**
  String get quizAutoIntegrity;

  /// No description provided for @quizInvalidatedTitle.
  ///
  /// In en, this message translates to:
  /// **'This attempt was voided'**
  String get quizInvalidatedTitle;

  /// No description provided for @quizInvalidated.
  ///
  /// In en, this message translates to:
  /// **'A reviewer voided this attempt. It no longer counts, and the attempt has been given back to you.'**
  String get quizInvalidated;

  /// No description provided for @quizAwaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get quizAwaitingTitle;

  /// No description provided for @quizAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Some questions are graded by a reviewer. Your score appears once they have finished.'**
  String get quizAwaiting;

  /// No description provided for @quizLate.
  ///
  /// In en, this message translates to:
  /// **'Submitted after the due date'**
  String get quizLate;

  /// No description provided for @quizVerdictCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizVerdictCorrect;

  /// No description provided for @quizVerdictIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get quizVerdictIncorrect;

  /// No description provided for @quizVerdictPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get quizVerdictPending;

  /// No description provided for @quizVerdictRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get quizVerdictRecorded;

  /// No description provided for @quizNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get quizNotAnswered;

  /// No description provided for @quizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get quizCorrectAnswer;

  /// No description provided for @quizAcceptedAnswers.
  ///
  /// In en, this message translates to:
  /// **'Accepted answers'**
  String get quizAcceptedAnswers;

  /// No description provided for @quizExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get quizExplanation;

  /// No description provided for @quizReviewLesson.
  ///
  /// In en, this message translates to:
  /// **'Review the lesson'**
  String get quizReviewLesson;

  /// No description provided for @quizReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get quizReviewTitle;

  /// No description provided for @quizHistory.
  ///
  /// In en, this message translates to:
  /// **'Your attempts'**
  String get quizHistory;

  /// No description provided for @quizAttemptN.
  ///
  /// In en, this message translates to:
  /// **'Attempt {number}'**
  String quizAttemptN(String number);

  /// No description provided for @quizRetake.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get quizRetake;

  /// No description provided for @quizNoMoreAttempts.
  ///
  /// In en, this message translates to:
  /// **'No more attempts available'**
  String get quizNoMoreAttempts;

  /// No description provided for @quizNextActivity.
  ///
  /// In en, this message translates to:
  /// **'Continue to the next activity'**
  String get quizNextActivity;

  /// No description provided for @quizBackToCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to the course'**
  String get quizBackToCourse;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved. The timer keeps running while you\'re away.'**
  String get quizLeaveBody;

  /// No description provided for @quizLeaveTimedOff.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved. You can resume later.'**
  String get quizLeaveTimedOff;

  /// No description provided for @quizLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get quizLeave;

  /// No description provided for @quizStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get quizStay;

  /// No description provided for @assignmentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get assignmentInstructions;

  /// No description provided for @assignmentNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'The academy hasn\'t added instructions.'**
  String get assignmentNoInstructions;

  /// No description provided for @assignmentDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get assignmentDue;

  /// No description provided for @assignmentNoDue.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get assignmentNoDue;

  /// No description provided for @assignmentLate.
  ///
  /// In en, this message translates to:
  /// **'After the due date'**
  String get assignmentLate;

  /// No description provided for @assignmentLateBlock.
  ///
  /// In en, this message translates to:
  /// **'Submissions are not accepted'**
  String get assignmentLateBlock;

  /// No description provided for @assignmentLateAccept.
  ///
  /// In en, this message translates to:
  /// **'Accepted and marked late'**
  String get assignmentLateAccept;

  /// No description provided for @assignmentResubmission.
  ///
  /// In en, this message translates to:
  /// **'Resubmitting'**
  String get assignmentResubmission;

  /// No description provided for @assignmentResubmitAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed until it is graded'**
  String get assignmentResubmitAllowed;

  /// No description provided for @assignmentResubmitNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get assignmentResubmitNotAllowed;

  /// No description provided for @assignmentResponse.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get assignmentResponse;

  /// No description provided for @assignmentResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer here'**
  String get assignmentResponseHint;

  /// No description provided for @assignmentCharsLeft.
  ///
  /// In en, this message translates to:
  /// **'{used} / {max}'**
  String assignmentCharsLeft(String used, String max);

  /// No description provided for @assignmentAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get assignmentAttachment;

  /// No description provided for @assignmentAttachmentHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. A photo or a PDF, up to 10 MB.'**
  String get assignmentAttachmentHelp;

  /// No description provided for @assignmentTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get assignmentTakePhoto;

  /// No description provided for @assignmentChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get assignmentChoosePhoto;

  /// No description provided for @assignmentChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a PDF'**
  String get assignmentChooseFile;

  /// No description provided for @assignmentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get assignmentUploading;

  /// No description provided for @assignmentRemoveAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get assignmentRemoveAttachment;

  /// No description provided for @assignmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The attachment must be smaller than 10 MB.'**
  String get assignmentTooLarge;

  /// No description provided for @assignmentBadType.
  ///
  /// In en, this message translates to:
  /// **'The attachment must be a PDF or an image (JPG, PNG, GIF or WebP).'**
  String get assignmentBadType;

  /// No description provided for @assignmentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The attachment didn\'t upload. Try again.'**
  String get assignmentUploadFailed;

  /// No description provided for @assignmentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit assignment'**
  String get assignmentSubmit;

  /// No description provided for @assignmentResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get assignmentResubmit;

  /// No description provided for @assignmentEditSubmission.
  ///
  /// In en, this message translates to:
  /// **'Change my submission'**
  String get assignmentEditSubmission;

  /// No description provided for @assignmentSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit this assignment?'**
  String get assignmentSubmitTitle;

  /// No description provided for @assignmentResubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace your submission?'**
  String get assignmentResubmitTitle;

  /// No description provided for @assignmentSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'Your reviewer will see exactly what is in the form now.'**
  String get assignmentSubmitBody;

  /// No description provided for @assignmentSubmitLateBody.
  ///
  /// In en, this message translates to:
  /// **'The due date has passed, so this submission will be marked late. Your reviewer will see exactly what is in the form now.'**
  String get assignmentSubmitLateBody;

  /// No description provided for @assignmentKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get assignmentKeepEditing;

  /// No description provided for @assignmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write an answer or add an attachment first.'**
  String get assignmentEmpty;

  /// No description provided for @assignmentDraftSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving draft…'**
  String get assignmentDraftSaving;

  /// No description provided for @assignmentDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get assignmentDraftSaved;

  /// No description provided for @assignmentDraftFailed.
  ///
  /// In en, this message translates to:
  /// **'Draft not saved — check your connection'**
  String get assignmentDraftFailed;

  /// No description provided for @assignmentDraftUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get assignmentDraftUnsaved;

  /// No description provided for @assignmentConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'This draft changed on another device'**
  String get assignmentConflictTitle;

  /// No description provided for @assignmentConflictBody.
  ///
  /// In en, this message translates to:
  /// **'Choose which version to keep.'**
  String get assignmentConflictBody;

  /// No description provided for @assignmentKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep this version'**
  String get assignmentKeepMine;

  /// No description provided for @assignmentUseTheirs.
  ///
  /// In en, this message translates to:
  /// **'Use the other version'**
  String get assignmentUseTheirs;

  /// No description provided for @assignmentPastDueTitle.
  ///
  /// In en, this message translates to:
  /// **'The due date has passed'**
  String get assignmentPastDueTitle;

  /// No description provided for @assignmentPastDueBlocked.
  ///
  /// In en, this message translates to:
  /// **'This assignment no longer accepts submissions.'**
  String get assignmentPastDueBlocked;

  /// No description provided for @assignmentPastDueAccepted.
  ///
  /// In en, this message translates to:
  /// **'You can still submit. Your submission will be marked late.'**
  String get assignmentPastDueAccepted;

  /// No description provided for @assignmentYourSubmission.
  ///
  /// In en, this message translates to:
  /// **'Your submission'**
  String get assignmentYourSubmission;

  /// No description provided for @assignmentSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String assignmentSubmittedAt(String date);

  /// No description provided for @assignmentSubmittedLate.
  ///
  /// In en, this message translates to:
  /// **'Submitted late'**
  String get assignmentSubmittedLate;

  /// No description provided for @assignmentNoText.
  ///
  /// In en, this message translates to:
  /// **'No written answer.'**
  String get assignmentNoText;

  /// No description provided for @assignmentOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Open attachment'**
  String get assignmentOpenAttachment;

  /// No description provided for @assignmentStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get assignmentStepSubmitted;

  /// No description provided for @assignmentStepGrading.
  ///
  /// In en, this message translates to:
  /// **'Being graded'**
  String get assignmentStepGrading;

  /// No description provided for @assignmentStepGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get assignmentStepGraded;

  /// No description provided for @assignmentAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your reviewer to grade it.'**
  String get assignmentAwaiting;

  /// No description provided for @assignmentScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String assignmentScore(String score);

  /// No description provided for @assignmentGradedNoScore.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get assignmentGradedNoScore;

  /// No description provided for @assignmentFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get assignmentFeedback;

  /// No description provided for @assignmentGradedAt.
  ///
  /// In en, this message translates to:
  /// **'Graded {date}'**
  String assignmentGradedAt(String date);

  /// No description provided for @assignmentResubmitClosed.
  ///
  /// In en, this message translates to:
  /// **'Resubmitting isn\'t available for this assignment.'**
  String get assignmentResubmitClosed;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'My results'**
  String get resultsTitle;

  /// No description provided for @resultsCoursesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Courses completed'**
  String get resultsCoursesCompleted;

  /// No description provided for @resultsQuizzesPassed.
  ///
  /// In en, this message translates to:
  /// **'Quizzes passed'**
  String get resultsQuizzesPassed;

  /// No description provided for @resultsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average quiz score'**
  String get resultsAverage;

  /// No description provided for @resultsNoScores.
  ///
  /// In en, this message translates to:
  /// **'No scores yet'**
  String get resultsNoScores;

  /// No description provided for @resultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get resultsEmptyTitle;

  /// No description provided for @resultsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once you submit a quiz or an assignment, your scores appear here.'**
  String get resultsEmptyBody;

  /// No description provided for @resultsAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get resultsAwaiting;

  /// No description provided for @resultsHasFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback available'**
  String get resultsHasFeedback;

  /// No description provided for @resultsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get resultsRecent;

  /// No description provided for @resultsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get resultsSeeAll;

  /// No description provided for @certificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'My certificates'**
  String get certificatesTitle;

  /// No description provided for @certificatesOff.
  ///
  /// In en, this message translates to:
  /// **'This academy doesn\'t issue certificates.'**
  String get certificatesOff;

  /// No description provided for @certificatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get certificatesEmptyTitle;

  /// No description provided for @certificatesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a course that awards one and your certificate appears here.'**
  String get certificatesEmptyBody;

  /// No description provided for @certificateSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get certificateSerial;

  /// No description provided for @certificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String certificateIssued(String date);

  /// No description provided for @certificateScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}%'**
  String certificateScore(String score);

  /// No description provided for @certificateRevoked.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get certificateRevoked;

  /// No description provided for @certificateRevokedOn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn {date}'**
  String certificateRevokedOn(String date);

  /// No description provided for @certificateRevokedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String certificateRevokedReason(String reason);

  /// No description provided for @certificateCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get certificateCode;

  /// No description provided for @certificateCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get certificateCopyCode;

  /// No description provided for @certificateCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get certificateCopied;

  /// No description provided for @certificateShare.
  ///
  /// In en, this message translates to:
  /// **'Share verification link'**
  String get certificateShare;

  /// No description provided for @certificateShareText.
  ///
  /// In en, this message translates to:
  /// **'My certificate for {course}: {link}'**
  String certificateShareText(String course, String link);

  /// No description provided for @certificateDownload.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get certificateDownload;

  /// No description provided for @certificatePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your certificate…'**
  String get certificatePreparing;

  /// No description provided for @certificatePreparingHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes under a minute.'**
  String get certificatePreparingHint;

  /// No description provided for @certificateRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get certificateRefresh;

  /// No description provided for @certificateFailed.
  ///
  /// In en, this message translates to:
  /// **'The certificate file couldn\'t be prepared. The academy has been told; try again later.'**
  String get certificateFailed;

  /// No description provided for @courseCertificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Your certificate is ready.'**
  String get courseCertificateIssued;

  /// No description provided for @courseOpenCertificates.
  ///
  /// In en, this message translates to:
  /// **'View certificate'**
  String get courseOpenCertificates;

  /// No description provided for @accountLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get accountLearning;

  /// No description provided for @notificationOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notificationOpen;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAll;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Grades, certificates, announcements and reminders from your academy appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// No description provided for @notificationsFallback.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification.'**
  String get notificationsFallback;

  /// No description provided for @notificationsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get notificationsLoadMore;

  /// No description provided for @pushCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Know when your work is graded'**
  String get pushCardTitle;

  /// No description provided for @pushCardBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to hear about grades, certificates, announcements and due dates, even when the app is closed.'**
  String get pushCardBody;

  /// No description provided for @pushCardAction.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get pushCardAction;

  /// No description provided for @pushCardLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pushCardLater;

  /// No description provided for @pushDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Atlas. You can turn them on in your phone\'s Settings.'**
  String get pushDenied;

  /// No description provided for @announcementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsTitle;

  /// No description provided for @announcementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get announcementsEmpty;

  /// No description provided for @announcementBy.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String announcementBy(String name);

  /// No description provided for @announcementCourse.
  ///
  /// In en, this message translates to:
  /// **'Course announcement'**
  String get announcementCourse;

  /// No description provided for @announcementAcademy.
  ///
  /// In en, this message translates to:
  /// **'Academy announcement'**
  String get announcementAcademy;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer in the course.'**
  String get itemNotFound;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettings;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfile;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password and sign-ins'**
  String get accountSecurity;

  /// No description provided for @accountNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get accountNotifications;

  /// No description provided for @accountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get accountPrivacy;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get profileNameHint;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get profileNameRequired;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileEmailNote.
  ///
  /// In en, this message translates to:
  /// **'Your email is your sign-in and can\'t be changed here.'**
  String get profileEmailNote;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profilePhone;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get profileSaved;

  /// No description provided for @profileEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileEmailVerified;

  /// No description provided for @profileEmailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get profileEmailUnverified;

  /// No description provided for @profileVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Send verification email'**
  String get profileVerifyEmail;

  /// No description provided for @profileVerifySent.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Open it on this phone to verify your email.'**
  String profileVerifySent(String email);

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Password and sign-ins'**
  String get securityTitle;

  /// No description provided for @securityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securityChangePassword;

  /// No description provided for @securityCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Type your current password.'**
  String get securityCurrentRequired;

  /// No description provided for @securityCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get securityCurrentPassword;

  /// No description provided for @securityNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get securityNewPassword;

  /// No description provided for @securityConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get securityConfirmPassword;

  /// No description provided for @securityPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get securityPasswordRule;

  /// No description provided for @securityPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get securityPasswordMismatch;

  /// No description provided for @securityPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get securityPasswordTooShort;

  /// No description provided for @securityPasswordChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get securityPasswordChangedTitle;

  /// No description provided for @securityPasswordChangedBody.
  ///
  /// In en, this message translates to:
  /// **'For your security you\'ve been signed out everywhere, including this phone. Sign in with your new password.'**
  String get securityPasswordChangedBody;

  /// No description provided for @securitySessions.
  ///
  /// In en, this message translates to:
  /// **'Where you\'re signed in'**
  String get securitySessions;

  /// No description provided for @securityThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get securityThisDevice;

  /// No description provided for @securityLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {time}'**
  String securityLastActive(String time);

  /// No description provided for @securitySignOutSession.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get securitySignOutSession;

  /// No description provided for @securitySignOutOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all other sessions'**
  String get securitySignOutOthers;

  /// No description provided for @securitySignOutOthersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out everywhere except this phone?'**
  String get securitySignOutOthersConfirm;

  /// No description provided for @securitySignOutSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of {device}?'**
  String securitySignOutSessionConfirm(String device);

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsPush.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this phone'**
  String get notificationSettingsPush;

  /// No description provided for @notificationSettingsPushOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationSettingsPushOn;

  /// No description provided for @notificationSettingsPushOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationSettingsPushOff;

  /// No description provided for @notificationSettingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Emails about your learning'**
  String get notificationSettingsEmail;

  /// No description provided for @notificationSettingsEmailHelp.
  ///
  /// In en, this message translates to:
  /// **'Grades, announcements and reminders by email. Security and account emails are always sent.'**
  String get notificationSettingsEmailHelp;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get privacyTitle;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage'**
  String get privacyAnalytics;

  /// No description provided for @privacyAnalyticsHelp.
  ///
  /// In en, this message translates to:
  /// **'Which screens are used and when lessons, quizzes and assignments are finished, without your name, email or answers. It helps us improve the app.'**
  String get privacyAnalyticsHelp;

  /// No description provided for @privacyExport.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get privacyExport;

  /// No description provided for @privacyExportHelp.
  ///
  /// In en, this message translates to:
  /// **'We prepare a copy of your Atlas data. You\'ll get an email when it\'s ready, then download it here.'**
  String get privacyExportHelp;

  /// No description provided for @privacyExportRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested {date}'**
  String privacyExportRequested(String date);

  /// No description provided for @privacyExportReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to download until {date}'**
  String privacyExportReady(String date);

  /// No description provided for @privacyExportDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get privacyExportDownload;

  /// No description provided for @privacyExportShare.
  ///
  /// In en, this message translates to:
  /// **'Save or share the file'**
  String get privacyExportShare;

  /// No description provided for @privacyDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get privacyDeleteAccount;

  /// No description provided for @privacyDeleteHelp.
  ///
  /// In en, this message translates to:
  /// **'Deletes your Atlas account in every academy: your courses, progress, results and certificates. This can\'t be undone.'**
  String get privacyDeleteHelp;

  /// No description provided for @privacyDeleteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This account manages an academy, so it can\'t be deleted from the app. Ask for deletion from the Atlas website.'**
  String get privacyDeleteNotAllowed;

  /// No description provided for @privacyNeedsVerifiedEmail.
  ///
  /// In en, this message translates to:
  /// **'To protect your account we send a code to your email first, so it needs to be verified. Verify it from your profile.'**
  String get privacyNeedsVerifiedEmail;

  /// No description provided for @privacyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we emailed you'**
  String get privacyCodeTitle;

  /// No description provided for @privacyCodeBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String privacyCodeBody(String email);

  /// No description provided for @privacyCodeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get privacyCodeContinue;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your Atlas account in every academy. Your progress, results and certificates will be gone, and this can\'t be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteConfirmType.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteConfirmType;

  /// No description provided for @deleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteConfirmAction;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get deleteDone;

  /// No description provided for @academiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your academies'**
  String get academiesTitle;

  /// No description provided for @academiesCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get academiesCurrent;

  /// No description provided for @academiesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add another academy'**
  String get academiesAdd;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Free courses'**
  String get catalogTitle;

  /// No description provided for @catalogBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse free courses'**
  String get catalogBrowse;

  /// No description provided for @catalogBrowseBody.
  ///
  /// In en, this message translates to:
  /// **'Join any of {academy}\'s free courses and start right away.'**
  String catalogBrowseBody(String academy);

  /// No description provided for @catalogSearch.
  ///
  /// In en, this message translates to:
  /// **'Search free courses'**
  String get catalogSearch;

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'This academy has no free courses right now.'**
  String get catalogEmpty;

  /// No description provided for @catalogNoResults.
  ///
  /// In en, this message translates to:
  /// **'No free courses match your search.'**
  String get catalogNoResults;

  /// No description provided for @catalogFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get catalogFree;

  /// No description provided for @catalogLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get catalogLoadMore;

  /// No description provided for @catalogJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get catalogJoined;

  /// No description provided for @previewJoin.
  ///
  /// In en, this message translates to:
  /// **'Join for free'**
  String get previewJoin;

  /// No description provided for @previewOpen.
  ///
  /// In en, this message translates to:
  /// **'Open course'**
  String get previewOpen;

  /// No description provided for @previewJoinedToast.
  ///
  /// In en, this message translates to:
  /// **'You joined {course}.'**
  String previewJoinedToast(String course);

  /// No description provided for @previewAbout.
  ///
  /// In en, this message translates to:
  /// **'About this course'**
  String get previewAbout;

  /// No description provided for @previewOutcomes.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll learn'**
  String get previewOutcomes;

  /// No description provided for @previewRequirements.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get previewRequirements;

  /// No description provided for @previewContent.
  ///
  /// In en, this message translates to:
  /// **'Course content'**
  String get previewContent;

  /// No description provided for @previewCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate on completion'**
  String get previewCertificate;

  /// No description provided for @previewUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} unit} other{{n} units}}'**
  String previewUnits(int count, String n);

  /// No description provided for @previewQuizzes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} quiz} other{{n} quizzes}}'**
  String previewQuizzes(int count, String n);

  /// No description provided for @previewAssignments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{n} assignment} other{{n} assignments}}'**
  String previewAssignments(int count, String n);

  /// No description provided for @previewHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String previewHours(String hours, String minutes);

  /// No description provided for @previewNotFree.
  ///
  /// In en, this message translates to:
  /// **'This course isn\'t free. You can join it from the academy\'s website.'**
  String get previewNotFree;

  /// No description provided for @previewNotFound.
  ///
  /// In en, this message translates to:
  /// **'This course isn\'t available. It may have been unpublished.'**
  String get previewNotFound;

  /// No description provided for @enrollLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This academy isn\'t taking new students right now. Contact the academy.'**
  String get enrollLimitReached;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelAll.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get levelAll;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'This link couldn\'t be opened. Check your connection and try again.'**
  String get linkOpenFailed;

  /// No description provided for @linkSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Open {academy}?'**
  String linkSwitchTitle(String academy);

  /// No description provided for @linkSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'This link is for {academy}. You stay signed in to {current} and can switch back from Account.'**
  String linkSwitchBody(String academy, String current);

  /// No description provided for @linkSwitchOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get linkSwitchOpen;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @verifyWorking.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email…'**
  String get verifyWorking;

  /// No description provided for @verifyDone.
  ///
  /// In en, this message translates to:
  /// **'Your email is verified.'**
  String get verifyDone;

  /// No description provided for @verifyInvalid.
  ///
  /// In en, this message translates to:
  /// **'This verification link isn\'t valid. Send a new one from your profile.'**
  String get verifyInvalid;

  /// No description provided for @verifyOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to profile'**
  String get verifyOpenProfile;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account at {academy}.'**
  String resetBody(String academy);

  /// No description provided for @resetChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the link…'**
  String get resetChecking;

  /// No description provided for @resetSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get resetSubmit;

  /// No description provided for @resetInvalid.
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired or was already used.'**
  String get resetInvalid;

  /// No description provided for @resetRequestNew.
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get resetRequestNew;

  /// No description provided for @resetDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your new password. You\'ve been signed out on every device.'**
  String get resetDoneBody;

  /// No description provided for @pickerScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get pickerScan;

  /// No description provided for @qrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the academy\'s code'**
  String get qrTitle;

  /// No description provided for @qrHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the academy\'s QR code.'**
  String get qrHint;

  /// No description provided for @qrTorch.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get qrTorch;

  /// No description provided for @qrOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get qrOpenSettings;

  /// No description provided for @qrTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type the academy\'s name'**
  String get qrTypeInstead;

  /// No description provided for @qrNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Atlas needs the camera to scan the code. Allow it in your phone\'s settings, or type the academy\'s address instead.'**
  String get qrNoPermission;

  /// No description provided for @qrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available right now. Type the academy\'s address instead.'**
  String get qrUnavailable;

  /// No description provided for @qrNotAcademy.
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t an academy address.'**
  String get qrNotAcademy;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get tasksTodo;

  /// No description provided for @tasksAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting grading'**
  String get tasksAwaiting;

  /// No description provided for @tasksGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get tasksGraded;

  /// No description provided for @tasksEmptyTodo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do right now.'**
  String get tasksEmptyTodo;

  /// No description provided for @tasksEmptyAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing is awaiting grading.'**
  String get tasksEmptyAwaiting;

  /// No description provided for @tasksEmptyGraded.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been graded yet.'**
  String get tasksEmptyGraded;

  /// No description provided for @tasksNone.
  ///
  /// In en, this message translates to:
  /// **'Your courses have no quizzes or assignments yet.'**
  String get tasksNone;

  /// No description provided for @tasksInProgress.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get tasksInProgress;

  /// No description provided for @tasksDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get tasksDraft;

  /// No description provided for @tasksRetry.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get tasksRetry;

  /// No description provided for @tasksDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String tasksDue(String date);

  /// No description provided for @tasksSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String tasksSubmitted(String date);

  /// No description provided for @tasksAwaitingShort.
  ///
  /// In en, this message translates to:
  /// **'Awaiting'**
  String get tasksAwaitingShort;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
