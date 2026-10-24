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

  @override
  String get quizInstructions => 'Instructions';

  @override
  String get quizInstructionsDefault =>
      'Answer every question, then submit your attempt.';

  @override
  String get quizFactQuestions => 'Questions';

  @override
  String get quizFactTime => 'Time limit';

  @override
  String get quizNoTimeLimit => 'No time limit';

  @override
  String get quizFactAttempts => 'Attempts';

  @override
  String quizAttemptsOf(String used, String total) {
    return '$used of $total used';
  }

  @override
  String quizAttemptsUnlimited(String used) {
    return '$used used, unlimited';
  }

  @override
  String get quizFactPassing => 'Passing score';

  @override
  String quizPercent(String value) {
    return '$value%';
  }

  @override
  String get quizFactOpens => 'Opens';

  @override
  String get quizFactDue => 'Due';

  @override
  String get quizFactCloses => 'Closes';

  @override
  String get quizFactCounts => 'Which attempt counts';

  @override
  String get quizPolicyHighest => 'Your highest score';

  @override
  String get quizPolicyLatest => 'Your latest attempt';

  @override
  String get quizPolicyFirst => 'Your first attempt';

  @override
  String get quizPolicyAverage => 'The average of your attempts';

  @override
  String get quizTimerNote =>
      'The clock starts when you press Start and keeps running even if you close the app. When it reaches zero, the answers you have saved are submitted automatically.';

  @override
  String get quizStart => 'Start quiz';

  @override
  String get quizResume => 'Resume quiz';

  @override
  String quizAttemptsLeft(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n attempts left',
      one: '1 attempt left',
      zero: 'No attempts left',
    );
    return '$_temp0';
  }

  @override
  String get quizIntegrityTitle => 'What is recorded during this quiz';

  @override
  String get quizIntegrityRecorded =>
      'While the quiz is open, these are recorded with the time they happened: leaving the app (for another app or the home screen) and coming back, and a connection check once a minute. Your reviewer sees them with plain explanations — they are prompts for a conversation, not proof of anything.';

  @override
  String get quizIntegrityMonitor =>
      'You will not be interrupted. The record is shown to your reviewer with your attempt.';

  @override
  String quizIntegrityWarn(String n) {
    return 'You will be warned each time one is recorded. The limit is $n; reaching it flags the attempt for review.';
  }

  @override
  String quizIntegrityStrict(String n) {
    return 'You will be warned each time one is recorded. When $n have been recorded, the quiz is submitted automatically with the answers you have saved.';
  }

  @override
  String get quizIntegrityFullscreen =>
      'The app shows the quiz on the whole screen. Leaving the app is recorded.';

  @override
  String get quizIntegrityHonest =>
      'Atlas never uses your camera or microphone, never records your screen or what you type, and sees nothing outside this quiz. Nothing is blocked.';

  @override
  String get quizIntegrityAck =>
      'I understand what is recorded during this quiz.';

  @override
  String quizQuestionOf(String current, String total) {
    return 'Question $current of $total';
  }

  @override
  String get quizPrevious => 'Previous';

  @override
  String get quizNext => 'Next';

  @override
  String get quizSubmit => 'Submit attempt';

  @override
  String get quizSubmitTitle => 'Submit this attempt?';

  @override
  String get quizSubmitBody =>
      'You won\'t be able to change your answers after submitting.';

  @override
  String quizSubmitUnanswered(int count, String numbers, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$n questions are still unanswered (questions $numbers). Unanswered questions count as incorrect. You won\'t be able to change your answers after submitting.',
      one:
          '1 question is still unanswered (question $numbers). Unanswered questions count as incorrect. You won\'t be able to change your answers after submitting.',
    );
    return '$_temp0';
  }

  @override
  String get quizSubmitConfirm => 'Submit';

  @override
  String get quizKeepAnswering => 'Keep answering';

  @override
  String get quizSaving => 'Saving…';

  @override
  String get quizOffline => 'Offline — will retry';

  @override
  String get quizUnsaved => 'Unsaved changes';

  @override
  String get quizSaved => 'Saved';

  @override
  String get quizNotSavedYet => 'Nothing saved yet';

  @override
  String quizAnswered(String answered, String total) {
    return '$answered of $total answered';
  }

  @override
  String get quizTimeLeft => 'Time left';

  @override
  String get quizTimerHidden => 'Timed — the clock is hidden';

  @override
  String get quizHurry => 'Finish up';

  @override
  String quizAnnounceMinutes(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n minutes left',
      one: '1 minute left',
    );
    return '$_temp0';
  }

  @override
  String quizAnnounceSeconds(String n) {
    return '$n seconds left';
  }

  @override
  String get quizYourAnswer => 'Your answer';

  @override
  String get quizTypeAnswer => 'Type your answer';

  @override
  String get quizShortHint => 'A short answer. Capitalisation does not matter.';

  @override
  String get quizEssayHint => 'This question is graded by a reviewer.';

  @override
  String quizPoints(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get quizChooseOne => 'Choose one answer';

  @override
  String get quizChooseAll => 'Choose all that apply';

  @override
  String get quizFlag => 'Mark for review';

  @override
  String get quizUnflag => 'Remove mark';

  @override
  String quizNavItem(String number, String state) {
    return 'Question $number, $state';
  }

  @override
  String get quizStateAnswered => 'answered';

  @override
  String get quizStateUnanswered => 'not answered';

  @override
  String get quizStateFlagged => 'marked for review';

  @override
  String get quizEventTitle => 'An event was recorded';

  @override
  String quizEventWarn(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$n events have been recorded on this attempt. Stay in the app until you submit.',
      one: '1 event has been recorded on this attempt. Stay in the app until you submit.',
    );
    return '$_temp0';
  }

  @override
  String quizEventStrict(String n, String max) {
    return '$n of $max events recorded. When the limit is reached, the quiz is submitted automatically.';
  }

  @override
  String get quizEventDialogTitle => 'Another event was recorded';

  @override
  String get quizEventDialogWarn =>
      'Your reviewer will see the record alongside your answers.';

  @override
  String get quizContinue => 'Continue quiz';

  @override
  String get quizResultTitle => 'Your result';

  @override
  String get quizPassed => 'Passed';

  @override
  String get quizFailed => 'Not passed';

  @override
  String quizPointsOf(String earned, String total) {
    return '$earned of $total points';
  }

  @override
  String quizPassingLine(String score) {
    return 'Passing score $score%';
  }

  @override
  String quizCounted(String score) {
    return 'Counted score: $score%';
  }

  @override
  String get quizScoreWithheldDue =>
      'Your score will be shown after the due date.';

  @override
  String get quizScoreWithheldAttempts =>
      'Your score will be shown once you have used all your attempts.';

  @override
  String get quizScoreWithheldNever => 'This quiz does not show scores.';

  @override
  String get quizScoreWithheldSoon => 'Your score is being prepared.';

  @override
  String get quizAnswersWithheld =>
      'Correct answers are not shown for this attempt yet.';

  @override
  String get quizSubmittedTitle => 'Attempt submitted';

  @override
  String get quizTimeRanOutTitle => 'Time ran out';

  @override
  String get quizTimeRanOut =>
      'Time ran out. Your answers were submitted automatically.';

  @override
  String get quizAutoIntegrityTitle => 'Submitted automatically';

  @override
  String get quizAutoIntegrity =>
      'The quiz was submitted because the recorded-event limit was reached. The answers you had saved were graded as they were.';

  @override
  String get quizInvalidatedTitle => 'This attempt was voided';

  @override
  String get quizInvalidated =>
      'A reviewer voided this attempt. It no longer counts, and the attempt has been given back to you.';

  @override
  String get quizAwaitingTitle => 'Awaiting grading';

  @override
  String get quizAwaiting =>
      'Some questions are graded by a reviewer. Your score appears once they have finished.';

  @override
  String get quizLate => 'Submitted after the due date';

  @override
  String get quizVerdictCorrect => 'Correct';

  @override
  String get quizVerdictIncorrect => 'Incorrect';

  @override
  String get quizVerdictPending => 'Awaiting grading';

  @override
  String get quizVerdictRecorded => 'Recorded';

  @override
  String get quizNotAnswered => 'Not answered';

  @override
  String get quizCorrectAnswer => 'Correct answer';

  @override
  String get quizAcceptedAnswers => 'Accepted answers';

  @override
  String get quizExplanation => 'Explanation';

  @override
  String get quizReviewLesson => 'Review the lesson';

  @override
  String get quizReviewTitle => 'Your answers';

  @override
  String get quizHistory => 'Your attempts';

  @override
  String quizAttemptN(String number) {
    return 'Attempt $number';
  }

  @override
  String get quizRetake => 'Try again';

  @override
  String get quizNoMoreAttempts => 'No more attempts available';

  @override
  String get quizNextActivity => 'Continue to the next activity';

  @override
  String get quizBackToCourse => 'Back to the course';

  @override
  String get quizLeaveTitle => 'Leave the quiz?';

  @override
  String get quizLeaveBody =>
      'Your answers are saved. The timer keeps running while you\'re away.';

  @override
  String get quizLeaveTimedOff =>
      'Your answers are saved. You can resume later.';

  @override
  String get quizLeave => 'Leave';

  @override
  String get quizStay => 'Stay';

  @override
  String get assignmentInstructions => 'Instructions';

  @override
  String get assignmentNoInstructions =>
      'The academy hasn\'t added instructions.';

  @override
  String get assignmentDue => 'Due';

  @override
  String get assignmentNoDue => 'No due date';

  @override
  String get assignmentLate => 'After the due date';

  @override
  String get assignmentLateBlock => 'Submissions are not accepted';

  @override
  String get assignmentLateAccept => 'Accepted and marked late';

  @override
  String get assignmentResubmission => 'Resubmitting';

  @override
  String get assignmentResubmitAllowed => 'Allowed until it is graded';

  @override
  String get assignmentResubmitNotAllowed => 'Not allowed';

  @override
  String get assignmentResponse => 'Your answer';

  @override
  String get assignmentResponseHint => 'Write your answer here';

  @override
  String assignmentCharsLeft(String used, String max) {
    return '$used / $max';
  }

  @override
  String get assignmentAttachment => 'Attachment';

  @override
  String get assignmentAttachmentHelp =>
      'Optional. A photo or a PDF, up to 10 MB.';

  @override
  String get assignmentTakePhoto => 'Take a photo';

  @override
  String get assignmentChoosePhoto => 'Choose a photo';

  @override
  String get assignmentChooseFile => 'Choose a PDF';

  @override
  String get assignmentUploading => 'Uploading…';

  @override
  String get assignmentRemoveAttachment => 'Remove';

  @override
  String get assignmentTooLarge => 'The attachment must be smaller than 10 MB.';

  @override
  String get assignmentBadType =>
      'The attachment must be a PDF or an image (JPG, PNG, GIF or WebP).';

  @override
  String get assignmentUploadFailed =>
      'The attachment didn\'t upload. Try again.';

  @override
  String get assignmentSubmit => 'Submit assignment';

  @override
  String get assignmentResubmit => 'Resubmit';

  @override
  String get assignmentEditSubmission => 'Change my submission';

  @override
  String get assignmentSubmitTitle => 'Submit this assignment?';

  @override
  String get assignmentResubmitTitle => 'Replace your submission?';

  @override
  String get assignmentSubmitBody =>
      'Your reviewer will see exactly what is in the form now.';

  @override
  String get assignmentSubmitLateBody =>
      'The due date has passed, so this submission will be marked late. Your reviewer will see exactly what is in the form now.';

  @override
  String get assignmentKeepEditing => 'Keep editing';

  @override
  String get assignmentEmpty => 'Write an answer or add an attachment first.';

  @override
  String get assignmentDraftSaving => 'Saving draft…';

  @override
  String get assignmentDraftSaved => 'Draft saved';

  @override
  String get assignmentDraftFailed => 'Draft not saved — check your connection';

  @override
  String get assignmentDraftUnsaved => 'Unsaved changes';

  @override
  String get assignmentConflictTitle => 'This draft changed on another device';

  @override
  String get assignmentConflictBody => 'Choose which version to keep.';

  @override
  String get assignmentKeepMine => 'Keep this version';

  @override
  String get assignmentUseTheirs => 'Use the other version';

  @override
  String get assignmentPastDueTitle => 'The due date has passed';

  @override
  String get assignmentPastDueBlocked =>
      'This assignment no longer accepts submissions.';

  @override
  String get assignmentPastDueAccepted =>
      'You can still submit. Your submission will be marked late.';

  @override
  String get assignmentYourSubmission => 'Your submission';

  @override
  String assignmentSubmittedAt(String date) {
    return 'Submitted $date';
  }

  @override
  String get assignmentSubmittedLate => 'Submitted late';

  @override
  String get assignmentNoText => 'No written answer.';

  @override
  String get assignmentOpenAttachment => 'Open attachment';

  @override
  String get assignmentStepSubmitted => 'Submitted';

  @override
  String get assignmentStepGrading => 'Being graded';

  @override
  String get assignmentStepGraded => 'Graded';

  @override
  String get assignmentAwaiting => 'Waiting for your reviewer to grade it.';

  @override
  String assignmentScore(String score) {
    return 'Score: $score';
  }

  @override
  String get assignmentGradedNoScore => 'Graded';

  @override
  String get assignmentFeedback => 'Feedback';

  @override
  String assignmentGradedAt(String date) {
    return 'Graded $date';
  }

  @override
  String get assignmentResubmitClosed =>
      'Resubmitting isn\'t available for this assignment.';

  @override
  String get resultsTitle => 'My results';

  @override
  String get resultsCoursesCompleted => 'Courses completed';

  @override
  String get resultsQuizzesPassed => 'Quizzes passed';

  @override
  String get resultsAverage => 'Average quiz score';

  @override
  String get resultsNoScores => 'No scores yet';

  @override
  String get resultsEmptyTitle => 'No results yet';

  @override
  String get resultsEmptyBody =>
      'Once you submit a quiz or an assignment, your scores appear here.';

  @override
  String get resultsAwaiting => 'Awaiting grading';

  @override
  String get resultsHasFeedback => 'Feedback available';

  @override
  String get resultsRecent => 'Recent results';

  @override
  String get resultsSeeAll => 'All results';

  @override
  String get certificatesTitle => 'My certificates';

  @override
  String get certificatesOff => 'This academy doesn\'t issue certificates.';

  @override
  String get certificatesEmptyTitle => 'No certificates yet';

  @override
  String get certificatesEmptyBody =>
      'Finish a course that awards one and your certificate appears here.';

  @override
  String get certificateSerial => 'Serial';

  @override
  String certificateIssued(String date) {
    return 'Issued $date';
  }

  @override
  String certificateScore(String score) {
    return 'Score $score%';
  }

  @override
  String get certificateRevoked => 'Withdrawn';

  @override
  String certificateRevokedOn(String date) {
    return 'Withdrawn $date';
  }

  @override
  String certificateRevokedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get certificateCode => 'Verification code';

  @override
  String get certificateCopyCode => 'Copy code';

  @override
  String get certificateCopied => 'Copied';

  @override
  String get certificateShare => 'Share verification link';

  @override
  String certificateShareText(String course, String link) {
    return 'My certificate for $course: $link';
  }

  @override
  String get certificateDownload => 'Open PDF';

  @override
  String get certificatePreparing => 'Preparing your certificate…';

  @override
  String get certificatePreparingHint => 'This usually takes under a minute.';

  @override
  String get certificateRefresh => 'Refresh';

  @override
  String get certificateFailed =>
      'The certificate file couldn\'t be prepared. The academy has been told; try again later.';

  @override
  String get courseCertificateIssued => 'Your certificate is ready.';

  @override
  String get courseOpenCertificates => 'View certificate';

  @override
  String get accountLearning => 'Learning';
}
