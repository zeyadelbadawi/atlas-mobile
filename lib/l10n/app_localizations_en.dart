// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Atlas';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOr => 'or';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get pickerTitle => 'Find your academy';

  @override
  String get pickerBody =>
      'Enter the website address your academy gave you, or its short name.';

  @override
  String get pickerFieldLabel => 'Academy address';

  @override
  String get pickerFieldHint => 'academy.atlass.dpdns.org';

  @override
  String get pickerOpen => 'Open academy';

  @override
  String get pickerRecent => 'Recent academies';

  @override
  String get pickerRemoveRecent => 'Remove';

  @override
  String get pickerEmptyField => 'Enter your academy\'s address.';

  @override
  String get pickerInvalid =>
      'That doesn\'t look like a website address. Check it and try again.';

  @override
  String get pickerAboutAtlas => 'About Atlas';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInEmail => 'Email';

  @override
  String get signInPassword => 'Password';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get signInForgot => 'Forgot password?';

  @override
  String get signInNoAccount => 'New to this academy?';

  @override
  String get signInCreateAccount => 'Create an account';

  @override
  String get signInChangeAcademy => 'Change academy';

  @override
  String get signInNotMember =>
      'You don\'t have access to this academy yet. Join it with your Atlas password.';

  @override
  String get signInJoinAcademy => 'Join this academy';

  @override
  String get validationEmailRequired => 'Enter your email.';

  @override
  String get validationEmailInvalid => 'Enter an email like name@example.com.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get validationPasswordShort => 'Use at least 8 characters.';

  @override
  String get validationNameRequired => 'Enter your full name.';

  @override
  String get validationPhoneRequired => 'Enter your mobile number.';

  @override
  String get codeTitle => 'Check your email';

  @override
  String codeBody(String email) {
    return 'We sent a 6-digit code to $email. It works for 10 minutes.';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get codeRemember => 'Remember this device';

  @override
  String get codeRememberHint => 'You won\'t need a code here next time.';

  @override
  String get codeVerify => 'Verify';

  @override
  String get codeResend => 'Send a new code';

  @override
  String codeResendIn(String seconds) {
    return 'Send a new code in ${seconds}s';
  }

  @override
  String get codeResent => 'A new code is on its way. It can take a minute.';

  @override
  String get totpTitle => 'Two-step verification';

  @override
  String get totpBody => 'Enter the 6-digit code from your authenticator app.';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerName => 'Full name';

  @override
  String get registerPhone => 'Mobile number';

  @override
  String get registerPhoneHint =>
      'The academy can use it to contact you about your courses.';

  @override
  String get registerPassword => 'Password';

  @override
  String get registerPasswordHint => 'At least 8 characters.';

  @override
  String get registerAge => 'I am 13 or older';

  @override
  String get registerAgreePrefix => 'I agree to the ';

  @override
  String get registerAgreeAnd => ' and the ';

  @override
  String get registerTerms => 'Terms of Service';

  @override
  String get registerPrivacy => 'Privacy Policy';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerNeedsConsent =>
      'Confirm your age and accept the terms to continue.';

  @override
  String get registerExisting =>
      'This email already has an Atlas account. Sign in with its password.';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotBody => 'We\'ll email you a link to choose a new password.';

  @override
  String get forgotSubmit => 'Send link';

  @override
  String forgotSent(String email) {
    return 'If $email has an account here, a reset link is on its way. Open it on this phone or any browser.';
  }

  @override
  String get appleLinkTitle => 'Connect Apple to your account';

  @override
  String appleLinkBody(String email) {
    return '$email already has an account. Enter its password once to sign in with Apple from now on.';
  }

  @override
  String get appleLinkSubmit => 'Connect and sign in';

  @override
  String get appleCreateTitle => 'Finish creating your account';

  @override
  String get appleCreateBody =>
      'Your name and email come from Apple. Add your mobile number to finish.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCourses => 'My courses';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabAccount => 'Account';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountLanguage => 'Language';

  @override
  String get accountAppearance => 'Appearance';

  @override
  String get accountSystem => 'Automatic';

  @override
  String get accountLight => 'Light';

  @override
  String get accountDark => 'Dark';

  @override
  String get accountArabic => 'العربية';

  @override
  String get accountEnglish => 'English';

  @override
  String get accountChangeAcademy => 'Change academy';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String accountSignOutConfirm(String academy) {
    return 'Sign out of $academy on this phone?';
  }

  @override
  String get accountLegal => 'Policies';

  @override
  String get accountAbout => 'About the app';

  @override
  String get legalTitle => 'Policies';

  @override
  String get legalTerms => 'Terms of Service';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalRefund => 'Refund Policy';

  @override
  String get legalCookie => 'Cookie Policy';

  @override
  String get legalLoadFailed =>
      'This page didn\'t load. Check your connection and try again.';

  @override
  String get aboutTitle => 'About the app';

  @override
  String get aboutBody =>
      'Atlas is the platform your academy uses for its courses. This app shows the courses you are enrolled in and free courses you can join. It sells nothing.';

  @override
  String get aboutCompany => 'Company';

  @override
  String get aboutLegalName => 'Legal name';

  @override
  String get aboutAddress => 'Address';

  @override
  String get aboutAddressValue => '6th of October City, Giza, Egypt';

  @override
  String get aboutEmail => 'Email';

  @override
  String get aboutPhone => 'Phone';

  @override
  String get aboutVersion => 'Version';

  @override
  String get updateTitle => 'Update Atlas to continue';

  @override
  String get updateBody =>
      'This version no longer works with your academy. The update keeps your sign-in and progress.';

  @override
  String get updateButton => 'Update';

  @override
  String get maintenanceTitle => 'Atlas is being updated';

  @override
  String get maintenanceBody =>
      'We\'ll be back shortly. Your progress is saved.';

  @override
  String get signedInTitle => 'You\'re signed in';

  @override
  String signedInBody(String name) {
    return 'Welcome, $name.';
  }

  @override
  String get homeContinue => 'Continue';

  @override
  String get homeResume => 'Resume lesson';

  @override
  String get homeStart => 'Start the course';

  @override
  String get homeDueSoon => 'Due soon';

  @override
  String get homeAnnouncements => 'From your academy';

  @override
  String get homeMyCourses => 'My courses';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmptyTitle => 'No courses yet';

  @override
  String homeEmptyBody(String academy) {
    return 'Courses you join at $academy appear here.';
  }

  @override
  String get homeAllDone => 'You\'re up to date. Pick a course to review.';

  @override
  String get unitLesson => 'Lesson';

  @override
  String get unitQuiz => 'Quiz';

  @override
  String get unitAssignment => 'Assignment';

  @override
  String get unitLive => 'Live session';

  @override
  String countOf(String done, String total) {
    return '$done of $total';
  }

  @override
  String lessonsCount(String count) {
    return '$count lessons';
  }

  @override
  String percentDone(String percent) {
    return '$percent% done';
  }

  @override
  String minutesLeft(String minutes) {
    return '$minutes min left';
  }

  @override
  String minutes(String minutes) {
    return '$minutes min';
  }

  @override
  String dueAssignment(String time) {
    return 'Assignment due $time';
  }

  @override
  String dueLive(String time) {
    return 'Live session $time';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String get coursesTitle => 'My courses';

  @override
  String get coursesAll => 'All';

  @override
  String get coursesInProgress => 'In progress';

  @override
  String get coursesCompleted => 'Completed';

  @override
  String get coursesNotStarted => 'Not started';

  @override
  String get coursesNoneInFilter => 'Nothing here.';

  @override
  String courseUnit(String number) {
    return 'Unit $number';
  }

  @override
  String get courseContinue => 'Continue';

  @override
  String get courseReview => 'Review from the start';

  @override
  String get courseCompletedTitle => 'Course complete';

  @override
  String get courseCompletedBody => 'You finished every required lesson.';

  @override
  String get courseCertificatePending => 'Your certificate is being prepared.';

  @override
  String get courseAccessEnded => 'Your access to this course has ended.';

  @override
  String get lockPrevious => 'Finish the previous item first';

  @override
  String lockScheduled(String date) {
    return 'Opens $date';
  }

  @override
  String get lockNotStarted => 'Not open yet';

  @override
  String get lockAccessEnded => 'Access ended';

  @override
  String get lockQuizNotPassed => 'Pass the quiz before this';

  @override
  String get itemOnWebsite => 'Open on the academy website';

  @override
  String get lessonMarkDone => 'Mark as done';

  @override
  String get lessonDone => 'Done';

  @override
  String lessonNext(String title) {
    return 'Next: $title';
  }

  @override
  String get lessonBackToCourse => 'Back to the course';

  @override
  String lessonWatchFirst(String percent) {
    return 'Watch $percent% of the video to mark it done.';
  }

  @override
  String get lessonResources => 'Lesson files';

  @override
  String get lessonOpenFile => 'Open file';

  @override
  String get lessonOpenLink => 'Open link';

  @override
  String get lessonVideoOnWeb =>
      'This video plays on the academy website for now.';

  @override
  String get lessonOpenWebsite => 'Open website';

  @override
  String get playerRecording => 'Stop screen recording to keep watching.';

  @override
  String get playerFailed =>
      'This video couldn\'t play. Check your connection and try again.';

  @override
  String get takeoverTitle => 'Watching on another device';

  @override
  String takeoverBody(String device) {
    return '$device is using your lessons now. Continue here instead? The other device will stop.';
  }

  @override
  String get takeoverUnknownDevice => 'Another device';

  @override
  String get takeoverConfirm => 'Continue here';

  @override
  String get deviceLimitTitle => 'Device limit reached';

  @override
  String get deviceLimitBody =>
      'Remove a device you no longer use, then open the lesson again.';

  @override
  String get deviceLimitManage => 'Manage devices';

  @override
  String get devicesTitle => 'My devices';

  @override
  String devicesBody(String count) {
    return 'You can learn on up to $count devices.';
  }

  @override
  String get devicesThis => 'This device';

  @override
  String devicesLastSeen(String time) {
    return 'Last used $time';
  }

  @override
  String get devicesRemove => 'Remove';

  @override
  String devicesRemoveConfirm(String device) {
    return 'Remove $device? It will need a free slot to play lessons again.';
  }

  @override
  String get accountDevices => 'My devices';

  @override
  String get loadFailed =>
      'This didn\'t load. Check your connection and try again.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get coursesCover => 'Course';
}
