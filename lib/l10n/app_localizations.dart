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
  /// **'Enter the website address your academy gave you, or its short name.'**
  String get pickerBody;

  /// No description provided for @pickerFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Academy address'**
  String get pickerFieldLabel;

  /// No description provided for @pickerFieldHint.
  ///
  /// In en, this message translates to:
  /// **'academy.atlass.dpdns.org'**
  String get pickerFieldHint;

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
  /// **'Enter your academy\'s address.'**
  String get pickerEmptyField;

  /// No description provided for @pickerInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a website address. Check it and try again.'**
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
  /// **'{count} lessons'**
  String lessonsCount(String count);

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
