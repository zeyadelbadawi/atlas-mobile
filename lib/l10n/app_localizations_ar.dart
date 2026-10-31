// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أطلس';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDone => 'تم';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonOr => 'أو';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get pickerTitle => 'ابحث عن أكاديميتك';

  @override
  String get pickerBody =>
      'اكتب اسم أكاديميتك كما يظهر في رابطها، أو امسح رمز QR.';

  @override
  String get pickerFieldLabel => 'اسم الأكاديمية';

  @override
  String get pickerFieldHint => 'academy';

  @override
  String get pickerCustomDomain => 'لأكاديميتك دومين خاص؟';

  @override
  String get pickerCustomLabel => 'عنوان موقع الأكاديمية';

  @override
  String get pickerCustomHint => 'learn.your-academy.com';

  @override
  String get pickerAtlasName => 'أكاديميتك على أطلس؟ اكتب اسمها فقط';

  @override
  String get catalogClearSearch => 'مسح البحث';

  @override
  String pickerNotFound(String host) {
    return 'لم نجد أكاديمية على $host. راجع الاسم، أو اطلب رابط الأكاديمية منها.';
  }

  @override
  String get pickerOpen => 'فتح الأكاديمية';

  @override
  String get pickerRecent => 'آخر الأكاديميات';

  @override
  String get pickerRemoveRecent => 'إزالة';

  @override
  String get pickerEmptyField => 'اكتب اسم أكاديميتك.';

  @override
  String get pickerInvalid =>
      'هذا لا يبدو اسم أكاديمية أو عنوان موقع. راجعه وحاول مرة أخرى.';

  @override
  String get pickerAboutAtlas => 'عن أطلس';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInEmail => 'البريد الإلكتروني';

  @override
  String get signInPassword => 'كلمة المرور';

  @override
  String get signInSubmit => 'تسجيل الدخول';

  @override
  String get signInForgot => 'نسيت كلمة المرور؟';

  @override
  String get signInNoAccount => 'جديد في هذه الأكاديمية؟';

  @override
  String get signInCreateAccount => 'إنشاء حساب';

  @override
  String get signInChangeAcademy => 'تغيير الأكاديمية';

  @override
  String get signInNotMember =>
      'ليس لديك وصول إلى هذه الأكاديمية بعد. انضم إليها بكلمة مرور حسابك في أطلس.';

  @override
  String get signInJoinAcademy => 'الانضمام إلى الأكاديمية';

  @override
  String get validationEmailRequired => 'اكتب بريدك الإلكتروني.';

  @override
  String get validationEmailInvalid =>
      'اكتب بريدًا صحيحًا مثل name@example.com.';

  @override
  String get validationPasswordRequired => 'اكتب كلمة المرور.';

  @override
  String get validationPasswordShort => 'استخدم ٨ أحرف على الأقل.';

  @override
  String get validationNameRequired => 'اكتب اسمك الكامل.';

  @override
  String get validationPhoneRequired => 'اكتب رقم هاتفك المحمول.';

  @override
  String get codeTitle => 'تحقّق من بريدك';

  @override
  String codeBody(String email) {
    return 'أرسلنا رمزًا من ٦ أرقام إلى $email. صالح لمدة ١٠ دقائق.';
  }

  @override
  String get codeLabel => 'الرمز';

  @override
  String get codeRemember => 'تذكّر هذا الجهاز';

  @override
  String get codeRememberHint =>
      'لن تحتاج إلى رمز على هذا الجهاز في المرة القادمة.';

  @override
  String get codeVerify => 'تأكيد';

  @override
  String get codeResend => 'إرسال رمز جديد';

  @override
  String codeResendIn(String seconds) {
    return 'إرسال رمز جديد بعد $seconds ث';
  }

  @override
  String get codeResent => 'تم إرسال رمز جديد. قد يستغرق دقيقة.';

  @override
  String get totpTitle => 'التحقق بخطوتين';

  @override
  String get totpBody => 'اكتب الرمز المكوّن من ٦ أرقام من تطبيق المصادقة.';

  @override
  String get registerTitle => 'إنشاء حسابك';

  @override
  String get registerName => 'الاسم الكامل';

  @override
  String get registerPhone => 'رقم الهاتف المحمول';

  @override
  String get registerPhoneHint =>
      'قد تستخدمه الأكاديمية للتواصل معك بخصوص كورساتك.';

  @override
  String get registerPassword => 'كلمة المرور';

  @override
  String get registerPasswordHint => '٨ أحرف على الأقل.';

  @override
  String get registerAge => 'عمري ١٣ سنة أو أكثر';

  @override
  String get registerAgreePrefix => 'أوافق على ';

  @override
  String get registerAgreeAnd => ' و';

  @override
  String get registerTerms => 'شروط الخدمة';

  @override
  String get registerPrivacy => 'سياسة الخصوصية';

  @override
  String get registerSubmit => 'إنشاء الحساب';

  @override
  String get registerNeedsConsent => 'أكّد عمرك ووافق على الشروط للمتابعة.';

  @override
  String get registerExisting =>
      'هذا البريد مرتبط بحساب في أطلس بالفعل. سجّل الدخول بكلمة مروره.';

  @override
  String get registerHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get forgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotBody => 'سنرسل إلى بريدك رابطًا لاختيار كلمة مرور جديدة.';

  @override
  String get forgotSubmit => 'إرسال الرابط';

  @override
  String forgotSent(String email) {
    return 'إذا كان للبريد $email حساب هنا، فسيصلك رابط إعادة التعيين. افتحه من هذا الهاتف أو من أي متصفح.';
  }

  @override
  String get appleLinkTitle => 'ربط Apple بحسابك';

  @override
  String appleLinkBody(String email) {
    return 'البريد $email مرتبط بحساب بالفعل. اكتب كلمة مروره مرة واحدة لتسجّل الدخول باستخدام Apple بعد ذلك.';
  }

  @override
  String get appleLinkSubmit => 'ربط وتسجيل الدخول';

  @override
  String get appleCreateTitle => 'أكمل إنشاء حسابك';

  @override
  String get appleCreateBody =>
      'اسمك وبريدك من Apple. أضف رقم هاتفك المحمول للإكمال.';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabCourses => 'كورساتي';

  @override
  String get tabNotifications => 'الإشعارات';

  @override
  String get tabAccount => 'حسابي';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get accountAppearance => 'المظهر';

  @override
  String get accountSystem => 'تلقائي';

  @override
  String get accountLight => 'فاتح';

  @override
  String get accountDark => 'داكن';

  @override
  String get accountArabic => 'العربية';

  @override
  String get accountEnglish => 'English';

  @override
  String get accountChangeAcademy => 'تغيير الأكاديمية';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String accountSignOutConfirm(String academy) {
    return 'تسجيل الخروج من $academy على هذا الهاتف؟';
  }

  @override
  String get accountLegal => 'السياسات';

  @override
  String get accountAbout => 'عن التطبيق';

  @override
  String get legalTitle => 'السياسات';

  @override
  String get legalTerms => 'شروط الخدمة';

  @override
  String get legalPrivacy => 'سياسة الخصوصية';

  @override
  String get legalRefund => 'سياسة الاسترداد';

  @override
  String get legalCookie => 'سياسة ملفات تعريف الارتباط';

  @override
  String get legalContents => 'المحتويات';

  @override
  String legalLastUpdated(String date) {
    return 'آخر تحديث: $date';
  }

  @override
  String legalEffective(String date) {
    return 'سارية من: $date';
  }

  @override
  String get legalBackToTop => 'العودة للأعلى';

  @override
  String get legalLoadFailed =>
      'لم يتم تحميل الصفحة. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get aboutTitle => 'عن التطبيق';

  @override
  String get aboutBody =>
      'أطلس هو المنصة التي تستخدمها أكاديميتك لكورساتها. يعرض هذا التطبيق الكورسات المسجّل فيها والكورسات المجانية التي يمكنك الانضمام إليها، ولا يبيع أي شيء.';

  @override
  String get aboutCompany => 'الشركة';

  @override
  String get aboutLegalName => 'الاسم القانوني';

  @override
  String get aboutAddress => 'العنوان';

  @override
  String get aboutAddressValue => 'مدينة ٦ أكتوبر، الجيزة، مصر';

  @override
  String get aboutEmail => 'البريد الإلكتروني';

  @override
  String get aboutWhatsapp => 'واتساب';

  @override
  String get aboutPhone => 'الهاتف';

  @override
  String get aboutVersion => 'الإصدار';

  @override
  String get updateTitle => 'حدّث أطلس للمتابعة';

  @override
  String get updateBody =>
      'هذا الإصدار لم يعد يعمل مع أكاديميتك. التحديث يحتفظ بتسجيل دخولك وتقدّمك.';

  @override
  String get updateButton => 'تحديث';

  @override
  String get maintenanceTitle => 'أطلس قيد التحديث';

  @override
  String get maintenanceBody => 'سنعود قريبًا. تقدّمك محفوظ.';

  @override
  String get signedInTitle => 'تم تسجيل الدخول';

  @override
  String signedInBody(String name) {
    return 'أهلًا بك يا $name.';
  }

  @override
  String get homeContinue => 'استكمل';

  @override
  String get homeResume => 'استكمل الدرس';

  @override
  String get homeStart => 'ابدأ الكورس';

  @override
  String get homeDueSoon => 'المطلوب قريبًا';

  @override
  String get homeAnnouncements => 'من أكاديميتك';

  @override
  String get homeMyCourses => 'كورساتي';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeEmptyTitle => 'لا توجد كورسات بعد';

  @override
  String homeEmptyBody(String academy) {
    return 'تظهر هنا الكورسات التي تنضم إليها في $academy.';
  }

  @override
  String get homeAllDone => 'أنهيت كل ما هو مطلوب. اختر كورسًا للمراجعة.';

  @override
  String get unitLesson => 'الدرس';

  @override
  String get unitQuiz => 'الاختبار';

  @override
  String get unitAssignment => 'الواجب';

  @override
  String get unitLive => 'جلسة مباشرة';

  @override
  String countOf(String done, String total) {
    return '$done من $total';
  }

  @override
  String lessonsCount(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n درس',
      many: '$n درسًا',
      few: '$n دروس',
      two: 'درسان',
      one: 'درس واحد',
    );
    return '$_temp0';
  }

  @override
  String percentDone(String percent) {
    return 'تم $percent٪';
  }

  @override
  String minutesLeft(String minutes) {
    return 'باقي $minutes دقيقة';
  }

  @override
  String minutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String dueAssignment(String time) {
    return 'تسليم الواجب $time';
  }

  @override
  String dueLive(String time) {
    return 'جلسة مباشرة $time';
  }

  @override
  String get overdue => 'متأخر';

  @override
  String get coursesTitle => 'كورساتي';

  @override
  String get coursesAll => 'الكل';

  @override
  String get coursesInProgress => 'جارية';

  @override
  String get coursesCompleted => 'مكتملة';

  @override
  String get coursesNotStarted => 'لم يبدأ';

  @override
  String get coursesNoneInFilter => 'لا يوجد شيء هنا.';

  @override
  String courseUnit(String number) {
    return 'الوحدة $number';
  }

  @override
  String get courseContinue => 'استكمل';

  @override
  String get courseReview => 'راجع من البداية';

  @override
  String get courseCompletedTitle => 'أكملت الكورس';

  @override
  String get courseCompletedBody => 'أنهيت كل الدروس المطلوبة.';

  @override
  String get courseCertificatePending => 'يتم تجهيز شهادتك.';

  @override
  String get courseAccessEnded => 'انتهى وصولك إلى هذا الكورس.';

  @override
  String get lockPrevious => 'أكمل العنصر السابق أولًا';

  @override
  String lockScheduled(String date) {
    return 'يُفتح $date';
  }

  @override
  String get lockNotStarted => 'لم يُفتح بعد';

  @override
  String get lockAccessEnded => 'انتهى الوصول';

  @override
  String get lockQuizNotPassed => 'اجتز الكويز قبل هذا';

  @override
  String get itemOnWebsite => 'افتحه على موقع الأكاديمية';

  @override
  String get lessonMarkDone => 'أكملت الدرس';

  @override
  String get lessonDone => 'تم';

  @override
  String lessonNext(String title) {
    return 'التالي: $title';
  }

  @override
  String get lessonBackToCourse => 'العودة إلى الكورس';

  @override
  String lessonWatchFirst(String percent) {
    return 'شاهد $percent٪ من الفيديو لتتمكن من إكماله.';
  }

  @override
  String get lessonResources => 'ملفات الدرس';

  @override
  String get lessonOpenFile => 'فتح الملف';

  @override
  String get lessonOpenLink => 'فتح الرابط';

  @override
  String get lessonVideoOnWeb =>
      'يُعرض هذا الفيديو على موقع الأكاديمية حاليًا.';

  @override
  String get lessonOpenWebsite => 'فتح الموقع';

  @override
  String get playerRecording => 'أوقف تسجيل الشاشة لمتابعة المشاهدة.';

  @override
  String get playerPlay => 'تشغيل';

  @override
  String get playerPause => 'إيقاف مؤقت';

  @override
  String get playerBack10 => 'رجوع ١٠ ثوانٍ';

  @override
  String get playerForward10 => 'تقديم ١٠ ثوانٍ';

  @override
  String get playerFailed =>
      'تعذّر تشغيل الفيديو. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get takeoverTitle => 'المشاهدة على جهاز آخر';

  @override
  String takeoverBody(String device) {
    return 'يستخدم $device دروسك الآن. هل تريد المتابعة هنا بدلًا منه؟ سيتوقف الجهاز الآخر.';
  }

  @override
  String get takeoverUnknownDevice => 'جهاز آخر';

  @override
  String get takeoverConfirm => 'المتابعة هنا';

  @override
  String get deviceLimitTitle => 'وصلت إلى الحد الأقصى للأجهزة';

  @override
  String get deviceLimitBody =>
      'أزل جهازًا لم تعد تستخدمه، ثم افتح الدرس مرة أخرى.';

  @override
  String get deviceLimitManage => 'إدارة الأجهزة';

  @override
  String get devicesTitle => 'أجهزتي';

  @override
  String devicesBody(String count) {
    return 'يمكنك التعلّم على $count أجهزة كحد أقصى.';
  }

  @override
  String get devicesThis => 'هذا الجهاز';

  @override
  String devicesLastSeen(String time) {
    return 'آخر استخدام $time';
  }

  @override
  String get devicesRemove => 'إزالة';

  @override
  String devicesRemoveConfirm(String device) {
    return 'إزالة $device؟ سيحتاج إلى مكان متاح لتشغيل الدروس مرة أخرى.';
  }

  @override
  String get accountDevices => 'أجهزتي';

  @override
  String get offlineTitle => 'لا يوجد اتصال بالإنترنت';

  @override
  String get offlineBody =>
      'تحقّق من اتصال الواي فاي أو بيانات الهاتف، ثم أعد المحاولة.';

  @override
  String get loadFailedTitle => 'تعذّر التحميل';

  @override
  String get loadFailed => 'لم يتم التحميل. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String homeGreeting(String name) {
    return 'أهلًا، $name';
  }

  @override
  String get coursesCover => 'كورس';

  @override
  String get quizInstructions => 'التعليمات';

  @override
  String get quizInstructionsDefault => 'أجب عن كل الأسئلة، ثم أرسل محاولتك.';

  @override
  String get quizFactQuestions => 'الأسئلة';

  @override
  String get quizFactTime => 'الوقت المحدد';

  @override
  String get quizNoTimeLimit => 'بلا وقت محدد';

  @override
  String get quizFactAttempts => 'المحاولات';

  @override
  String quizAttemptsOf(String used, String total) {
    return '$used من $total مستخدمة';
  }

  @override
  String quizAttemptsUnlimited(String used) {
    return '$used مستخدمة، بلا حد';
  }

  @override
  String get quizFactPassing => 'درجة النجاح';

  @override
  String quizPercent(String value) {
    return '$value٪';
  }

  @override
  String get quizFactOpens => 'يُفتح في';

  @override
  String get quizFactDue => 'موعد التسليم';

  @override
  String get quizFactCloses => 'يُغلق في';

  @override
  String get quizFactCounts => 'المحاولة التي تُحتسب';

  @override
  String get quizPolicyHighest => 'أعلى نتيجة لك';

  @override
  String get quizPolicyLatest => 'آخر محاولة لك';

  @override
  String get quizPolicyFirst => 'أول محاولة لك';

  @override
  String get quizPolicyAverage => 'متوسط محاولاتك';

  @override
  String get quizTimerNote =>
      'يبدأ العدّ عند الضغط على «ابدأ» ويستمر حتى لو أغلقت التطبيق. عند وصوله إلى الصفر تُرسَل الإجابات التي حفظتها تلقائيًا.';

  @override
  String get quizStart => 'ابدأ الاختبار';

  @override
  String get quizResume => 'استئناف الاختبار';

  @override
  String quizAttemptsLeft(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n محاولة متبقية',
      many: '$n محاولة متبقية',
      few: '$n محاولات متبقية',
      two: 'محاولتان متبقيتان',
      one: 'محاولة واحدة متبقية',
      zero: 'لا توجد محاولات متبقية',
    );
    return '$_temp0';
  }

  @override
  String get quizIntegrityTitle => 'ما يُسجَّل أثناء هذا الاختبار';

  @override
  String get quizIntegrityRecorded =>
      'أثناء فتح الاختبار يُسجَّل ما يلي مع وقت حدوثه: الخروج من التطبيق (إلى تطبيق آخر أو الشاشة الرئيسية) والعودة إليه، وفحص للاتصال مرة كل دقيقة. يرى المراجِع ذلك مع تفسيرات واضحة، وهي مدخل للحوار وليست دليلًا على أي شيء.';

  @override
  String get quizIntegrityMonitor =>
      'لن تتم مقاطعتك. يُعرض السجل على المراجِع مع محاولتك.';

  @override
  String quizIntegrityWarn(String n) {
    return 'سيتم تنبيهك في كل مرة يُسجَّل فيها حدث. الحد هو $n، وعند بلوغه تُعلَّم المحاولة للمراجعة.';
  }

  @override
  String quizIntegrityStrict(String n) {
    return 'سيتم تنبيهك في كل مرة يُسجَّل فيها حدث. عند تسجيل $n أحداث يُرسَل الاختبار تلقائيًا بالإجابات التي حفظتها.';
  }

  @override
  String get quizIntegrityFullscreen =>
      'يعرض التطبيق الاختبار على الشاشة كاملة، ويُسجَّل الخروج من التطبيق.';

  @override
  String get quizIntegrityHonest =>
      'لا يستخدم أطلس الكاميرا أو الميكروفون أبدًا، ولا يسجّل شاشتك أو ما تكتبه، ولا يرى شيئًا خارج هذا الاختبار. لا يُمنع أي شيء.';

  @override
  String get quizIntegrityAck => 'أفهم ما يُسجَّل أثناء هذا الاختبار.';

  @override
  String quizQuestionOf(String current, String total) {
    return 'السؤال $current من $total';
  }

  @override
  String get quizPrevious => 'السابق';

  @override
  String get quizNext => 'التالي';

  @override
  String get quizSubmit => 'إرسال المحاولة';

  @override
  String get quizSubmitTitle => 'إرسال هذه المحاولة؟';

  @override
  String get quizSubmitBody => 'لن تتمكن من تغيير إجاباتك بعد الإرسال.';

  @override
  String quizSubmitUnanswered(int count, String numbers, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ما زال $n سؤال دون إجابة (الأسئلة $numbers). تُحتسب الأسئلة غير المُجابة إجابات خاطئة. لن تتمكن من تغيير إجاباتك بعد الإرسال.',
      few:
          'ما زالت $n أسئلة دون إجابة (الأسئلة $numbers). تُحتسب الأسئلة غير المُجابة إجابات خاطئة. لن تتمكن من تغيير إجاباتك بعد الإرسال.',
      two:
          'ما زال هناك سؤالان دون إجابة (السؤالان $numbers). تُحتسب الأسئلة غير المُجابة إجابات خاطئة. لن تتمكن من تغيير إجاباتك بعد الإرسال.',
      one:
          'ما زال هناك سؤال واحد دون إجابة (السؤال $numbers). تُحتسب الأسئلة غير المُجابة إجابات خاطئة. لن تتمكن من تغيير إجاباتك بعد الإرسال.',
    );
    return '$_temp0';
  }

  @override
  String get quizSubmitConfirm => 'إرسال';

  @override
  String get quizKeepAnswering => 'متابعة الإجابة';

  @override
  String get quizSaving => 'جارٍ الحفظ…';

  @override
  String get quizOffline => 'غير متصل، ستتم إعادة المحاولة';

  @override
  String get quizUnsaved => 'تغييرات غير محفوظة';

  @override
  String get quizSaved => 'تم الحفظ';

  @override
  String get quizNotSavedYet => 'لم يُحفظ شيء بعد';

  @override
  String quizAnswered(String answered, String total) {
    return 'تمت الإجابة عن $answered من $total';
  }

  @override
  String get quizTimeLeft => 'الوقت المتبقي';

  @override
  String get quizTimerHidden => 'محدد بوقت، والعدّاد مخفي';

  @override
  String get quizHurry => 'أنهِ الآن';

  @override
  String quizAnnounceMinutes(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $n دقيقة',
      few: 'بقيت $n دقائق',
      two: 'بقيت دقيقتان',
      one: 'بقيت دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String quizAnnounceSeconds(String n) {
    return 'بقيت $n ثانية';
  }

  @override
  String get quizYourAnswer => 'إجابتك';

  @override
  String get quizTypeAnswer => 'اكتب إجابتك';

  @override
  String get quizShortHint => 'إجابة قصيرة. لا يهم حجم الأحرف.';

  @override
  String get quizEssayHint => 'يقيّم هذا السؤال مراجِع.';

  @override
  String quizPoints(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n نقطة',
      few: '$n نقاط',
      two: 'نقطتان',
      one: 'نقطة واحدة',
      zero: 'بلا نقاط',
    );
    return '$_temp0';
  }

  @override
  String get quizChooseOne => 'اختر إجابة واحدة';

  @override
  String get quizChooseAll => 'اختر كل ما ينطبق';

  @override
  String get quizFlag => 'تعليم للمراجعة';

  @override
  String get quizUnflag => 'إلغاء التعليم';

  @override
  String quizNavItem(String number, String state) {
    return 'السؤال $number، $state';
  }

  @override
  String get quizStateAnswered => 'تمت الإجابة';

  @override
  String get quizStateUnanswered => 'دون إجابة';

  @override
  String get quizStateFlagged => 'مُعلَّم للمراجعة';

  @override
  String get quizEventTitle => 'تم تسجيل حدث';

  @override
  String quizEventWarn(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تسجيل $n حدث في هذه المحاولة. ابقَ في التطبيق حتى الإرسال.',
      few: 'تم تسجيل $n أحداث في هذه المحاولة. ابقَ في التطبيق حتى الإرسال.',
      two: 'تم تسجيل حدثين في هذه المحاولة. ابقَ في التطبيق حتى الإرسال.',
      one: 'تم تسجيل حدث واحد في هذه المحاولة. ابقَ في التطبيق حتى الإرسال.',
    );
    return '$_temp0';
  }

  @override
  String quizEventStrict(String n, String max) {
    return 'تم تسجيل $n من $max أحداث. عند بلوغ الحد يُرسَل الاختبار تلقائيًا.';
  }

  @override
  String get quizEventDialogTitle => 'تم تسجيل حدث آخر';

  @override
  String get quizEventDialogWarn => 'سيرى المراجِع السجل إلى جانب إجاباتك.';

  @override
  String get quizContinue => 'متابعة الاختبار';

  @override
  String get quizResultTitle => 'نتيجتك';

  @override
  String get quizPassed => 'ناجح';

  @override
  String get quizFailed => 'غير ناجح';

  @override
  String quizPointsOf(String earned, String total) {
    return '$earned من $total نقطة';
  }

  @override
  String quizPassingLine(String score) {
    return 'درجة النجاح $score٪';
  }

  @override
  String quizCounted(String score) {
    return 'النتيجة المحتسبة: $score٪';
  }

  @override
  String get quizScoreWithheldDue => 'تظهر نتيجتك بعد موعد التسليم.';

  @override
  String get quizScoreWithheldAttempts =>
      'تظهر نتيجتك بعد استخدام كل محاولاتك.';

  @override
  String get quizScoreWithheldNever => 'لا يعرض هذا الاختبار النتائج.';

  @override
  String get quizScoreWithheldSoon => 'يجري تجهيز نتيجتك.';

  @override
  String get quizAnswersWithheld =>
      'لا تظهر الإجابات الصحيحة لهذه المحاولة بعد.';

  @override
  String get quizSubmittedTitle => 'تم إرسال المحاولة';

  @override
  String get quizTimeRanOutTitle => 'انتهى الوقت';

  @override
  String get quizTimeRanOut => 'انتهى الوقت. تم إرسال إجاباتك تلقائيًا.';

  @override
  String get quizAutoIntegrityTitle => 'تم الإرسال تلقائيًا';

  @override
  String get quizAutoIntegrity =>
      'تم إرسال الاختبار لبلوغ حد الأحداث المسجَّلة. قُيِّمت الإجابات التي حفظتها كما هي.';

  @override
  String get quizInvalidatedTitle => 'أُلغيت هذه المحاولة';

  @override
  String get quizInvalidated =>
      'ألغى مراجِع هذه المحاولة. لم تعد تُحتسب، وأُعيدت المحاولة إليك.';

  @override
  String get quizAwaitingTitle => 'بانتظار التقييم';

  @override
  String get quizAwaiting =>
      'بعض الأسئلة يقيّمها مراجِع. تظهر نتيجتك عند انتهائه.';

  @override
  String get quizLate => 'أُرسلت بعد موعد التسليم';

  @override
  String get quizVerdictCorrect => 'صحيحة';

  @override
  String get quizVerdictIncorrect => 'خاطئة';

  @override
  String get quizVerdictPending => 'بانتظار التقييم';

  @override
  String get quizVerdictRecorded => 'مسجَّلة';

  @override
  String get quizNotAnswered => 'دون إجابة';

  @override
  String get quizCorrectAnswer => 'الإجابة الصحيحة';

  @override
  String get quizAcceptedAnswers => 'الإجابات المقبولة';

  @override
  String get quizExplanation => 'الشرح';

  @override
  String get quizReviewLesson => 'راجع الدرس';

  @override
  String get quizReviewTitle => 'إجاباتك';

  @override
  String get quizHistory => 'محاولاتك';

  @override
  String quizAttemptN(String number) {
    return 'المحاولة $number';
  }

  @override
  String get quizRetake => 'إعادة المحاولة';

  @override
  String get quizNoMoreAttempts => 'لا توجد محاولات إضافية متاحة';

  @override
  String get quizNextActivity => 'المتابعة إلى النشاط التالي';

  @override
  String get quizBackToCourse => 'العودة إلى الكورس';

  @override
  String get quizLeaveTitle => 'الخروج من الاختبار؟';

  @override
  String get quizLeaveBody => 'إجاباتك محفوظة. يستمر العدّاد أثناء غيابك.';

  @override
  String get quizLeaveTimedOff => 'إجاباتك محفوظة. يمكنك الاستئناف لاحقًا.';

  @override
  String get quizLeave => 'خروج';

  @override
  String get quizStay => 'البقاء';

  @override
  String get assignmentInstructions => 'التعليمات';

  @override
  String get assignmentNoInstructions => 'لم تُضف الأكاديمية تعليمات.';

  @override
  String get assignmentDue => 'موعد التسليم';

  @override
  String get assignmentNoDue => 'بلا موعد تسليم';

  @override
  String get assignmentLate => 'بعد موعد التسليم';

  @override
  String get assignmentLateBlock => 'لا يُقبل التسليم';

  @override
  String get assignmentLateAccept => 'يُقبل ويُعلَّم بأنه متأخر';

  @override
  String get assignmentResubmission => 'إعادة التسليم';

  @override
  String get assignmentResubmitAllowed => 'مسموحة حتى التقييم';

  @override
  String get assignmentResubmitNotAllowed => 'غير مسموحة';

  @override
  String get assignmentResponse => 'إجابتك';

  @override
  String get assignmentResponseHint => 'اكتب إجابتك هنا';

  @override
  String assignmentCharsLeft(String used, String max) {
    return '$used / $max';
  }

  @override
  String get assignmentAttachment => 'المرفق';

  @override
  String get assignmentAttachmentHelp =>
      'اختياري. صورة أو ملف PDF، بحد أقصى ١٠ ميجابايت.';

  @override
  String get assignmentTakePhoto => 'التقاط صورة';

  @override
  String get assignmentChoosePhoto => 'اختيار صورة';

  @override
  String get assignmentChooseFile => 'اختيار ملف PDF';

  @override
  String get assignmentUploading => 'جارٍ الرفع…';

  @override
  String get assignmentRemoveAttachment => 'إزالة';

  @override
  String get assignmentTooLarge => 'يجب أن يكون حجم المرفق أقل من ١٠ ميجابايت.';

  @override
  String get assignmentBadType =>
      'يجب أن يكون المرفق ملف PDF أو صورة (JPG أو PNG أو GIF أو WebP).';

  @override
  String get assignmentUploadFailed => 'فشل رفع المرفق. حاول مرة أخرى.';

  @override
  String get assignmentSubmit => 'تسليم الواجب';

  @override
  String get assignmentResubmit => 'إعادة التسليم';

  @override
  String get assignmentEditSubmission => 'تعديل التسليم';

  @override
  String get assignmentSubmitTitle => 'تسليم هذا الواجب؟';

  @override
  String get assignmentResubmitTitle => 'استبدال تسليمك؟';

  @override
  String get assignmentSubmitBody => 'سيرى المراجِع ما في النموذج الآن تمامًا.';

  @override
  String get assignmentSubmitLateBody =>
      'انقضى موعد التسليم، لذا سيُعلَّم هذا التسليم بأنه متأخر. سيرى المراجِع ما في النموذج الآن تمامًا.';

  @override
  String get assignmentKeepEditing => 'متابعة التحرير';

  @override
  String get assignmentEmpty => 'اكتب إجابة أو أضف مرفقًا أولًا.';

  @override
  String get assignmentDraftSaving => 'جارٍ حفظ المسودة…';

  @override
  String get assignmentDraftSaved => 'تم حفظ المسودة';

  @override
  String get assignmentDraftFailed => 'لم تُحفظ المسودة، تحقّق من اتصالك';

  @override
  String get assignmentDraftUnsaved => 'تغييرات غير محفوظة';

  @override
  String get assignmentConflictTitle => 'تغيّرت هذه المسودة على جهاز آخر';

  @override
  String get assignmentConflictBody => 'اختر النسخة التي تريد الاحتفاظ بها.';

  @override
  String get assignmentKeepMine => 'الاحتفاظ بهذه النسخة';

  @override
  String get assignmentUseTheirs => 'استخدام النسخة الأخرى';

  @override
  String get assignmentPastDueTitle => 'انقضى موعد التسليم';

  @override
  String get assignmentPastDueBlocked => 'لم يعد هذا الواجب يقبل التسليم.';

  @override
  String get assignmentPastDueAccepted =>
      'ما زال بإمكانك التسليم. سيُعلَّم تسليمك بأنه متأخر.';

  @override
  String get assignmentYourSubmission => 'تسليمك';

  @override
  String assignmentSubmittedAt(String date) {
    return 'سُلِّم $date';
  }

  @override
  String get assignmentSubmittedLate => 'سُلِّم متأخرًا';

  @override
  String get assignmentNoText => 'لا توجد إجابة مكتوبة.';

  @override
  String get assignmentOpenAttachment => 'فتح المرفق';

  @override
  String get assignmentStepSubmitted => 'تم التسليم';

  @override
  String get assignmentStepGrading => 'قيد التقييم';

  @override
  String get assignmentStepGraded => 'تم التقييم';

  @override
  String get assignmentAwaiting => 'بانتظار تقييم المراجِع.';

  @override
  String assignmentScore(String score) {
    return 'الدرجة: $score';
  }

  @override
  String get assignmentGradedNoScore => 'تم التقييم';

  @override
  String get assignmentFeedback => 'الملاحظات';

  @override
  String assignmentGradedAt(String date) {
    return 'قُيِّم $date';
  }

  @override
  String get assignmentResubmitClosed => 'إعادة التسليم غير متاحة لهذا الواجب.';

  @override
  String get resultsTitle => 'نتائجي';

  @override
  String get resultsCoursesCompleted => 'الكورسات المكتملة';

  @override
  String get resultsQuizzesPassed => 'الاختبارات المجتازة';

  @override
  String get resultsAverage => 'متوسط درجات الاختبارات';

  @override
  String get resultsNoScores => 'لا توجد درجات بعد';

  @override
  String get resultsEmptyTitle => 'لا توجد نتائج بعد';

  @override
  String get resultsEmptyBody =>
      'بمجرد إرسالك اختبارًا أو واجبًا ستظهر درجاتك هنا.';

  @override
  String get resultsAwaiting => 'بانتظار التصحيح';

  @override
  String get resultsHasFeedback => 'تتوفّر ملاحظات';

  @override
  String get resultsRecent => 'آخر النتائج';

  @override
  String get resultsSeeAll => 'كل النتائج';

  @override
  String get certificatesTitle => 'شهاداتي';

  @override
  String get certificatesOff => 'لا تصدر هذه الأكاديمية شهادات.';

  @override
  String get certificatesEmptyTitle => 'لا توجد شهادات بعد';

  @override
  String get certificatesEmptyBody =>
      'أكمل كورسًا يمنح شهادة وستظهر شهادتك هنا.';

  @override
  String get certificateSerial => 'الرقم التسلسلي';

  @override
  String certificateIssued(String date) {
    return 'صدرت $date';
  }

  @override
  String certificateScore(String score) {
    return 'الدرجة $score٪';
  }

  @override
  String get certificateRevoked => 'مسحوبة';

  @override
  String certificateRevokedOn(String date) {
    return 'سُحبت $date';
  }

  @override
  String certificateRevokedReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get certificateCode => 'رمز التحقق';

  @override
  String get certificateCopyCode => 'نسخ الرمز';

  @override
  String get certificateCopied => 'تم النسخ';

  @override
  String get certificateShare => 'مشاركة رابط التحقق';

  @override
  String certificateShareText(String course, String link) {
    return 'شهادتي في $course: $link';
  }

  @override
  String get certificateDownload => 'فتح ملف PDF';

  @override
  String get certificatePreparing => 'يجري تجهيز شهادتك…';

  @override
  String get certificatePreparingHint => 'يستغرق ذلك عادةً أقل من دقيقة.';

  @override
  String get certificateRefresh => 'تحديث';

  @override
  String get certificateFailed =>
      'تعذّر تجهيز ملف الشهادة. أُبلغت الأكاديمية؛ حاول لاحقًا.';

  @override
  String get courseCertificateIssued => 'شهادتك جاهزة.';

  @override
  String get courseOpenCertificates => 'عرض الشهادة';

  @override
  String get accountLearning => 'التعلّم';

  @override
  String get notificationOpen => 'فتح';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsMarkAll => 'تعليم الكل كمقروء';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات';

  @override
  String get notificationsEmptyBody =>
      'تظهر هنا الدرجات والشهادات والإعلانات والتذكيرات من أكاديميتك.';

  @override
  String get notificationsUnread => 'غير مقروء';

  @override
  String get notificationsFallback => 'لديك إشعار جديد.';

  @override
  String get notificationsLoadMore => 'عرض المزيد';

  @override
  String get pushCardTitle => 'اعرف فور تقييم عملك';

  @override
  String get pushCardBody =>
      'فعّل الإشعارات لتصلك الدرجات والشهادات والإعلانات ومواعيد التسليم، حتى والتطبيق مغلق.';

  @override
  String get pushCardAction => 'تفعيل الإشعارات';

  @override
  String get pushCardLater => 'ليس الآن';

  @override
  String get pushDenied =>
      'الإشعارات متوقفة لتطبيق أطلس. يمكنك تفعيلها من إعدادات هاتفك.';

  @override
  String get announcementsTitle => 'الإعلانات';

  @override
  String get announcementsEmpty => 'لا توجد إعلانات بعد.';

  @override
  String announcementBy(String name) {
    return 'من $name';
  }

  @override
  String get announcementCourse => 'إعلان كورس';

  @override
  String get announcementAcademy => 'إعلان الأكاديمية';

  @override
  String get itemNotFound => 'لم يعد هذا العنصر موجودًا في الكورس.';

  @override
  String get accountSettings => 'الإعدادات';

  @override
  String get accountProfile => 'الملف الشخصي';

  @override
  String get accountSecurity => 'كلمة المرور وتسجيلات الدخول';

  @override
  String get accountNotifications => 'الإشعارات';

  @override
  String get accountPrivacy => 'الخصوصية والبيانات';

  @override
  String get profileName => 'الاسم';

  @override
  String get profileNameHint => 'اسمك بالكامل';

  @override
  String get profileNameRequired => 'اكتب اسمك.';

  @override
  String get profileEmail => 'البريد الإلكتروني';

  @override
  String get profileEmailNote =>
      'بريدك الإلكتروني هو وسيلة دخولك ولا يمكن تغييره من هنا.';

  @override
  String get profilePhone => 'رقم الموبايل';

  @override
  String get profileSave => 'حفظ';

  @override
  String get profileSaved => 'تم الحفظ.';

  @override
  String get profileEmailVerified => 'موثّق';

  @override
  String get profileEmailUnverified => 'غير موثّق';

  @override
  String get profileVerifyEmail => 'إرسال رسالة التوثيق';

  @override
  String profileVerifySent(String email) {
    return 'أرسلنا رابطًا إلى $email. افتحه على هذا الهاتف لتأكيد بريدك الإلكتروني.';
  }

  @override
  String get securityTitle => 'كلمة المرور وتسجيلات الدخول';

  @override
  String get securityChangePassword => 'تغيير كلمة المرور';

  @override
  String get securityCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get securityNewPassword => 'كلمة المرور الجديدة';

  @override
  String get securityConfirmPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get securityPasswordRule => '٨ أحرف على الأقل.';

  @override
  String get securityPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get securityPasswordTooShort => 'استخدم ٨ أحرف على الأقل.';

  @override
  String get securityPasswordChangedTitle => 'تم تغيير كلمة المرور';

  @override
  String get securityPasswordChangedBody =>
      'لأمانك تم تسجيل خروجك من كل الأجهزة، ومنها هذا الهاتف. سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get securitySessions => 'أين سجّلت الدخول';

  @override
  String get securityThisDevice => 'هذا الهاتف';

  @override
  String securityLastActive(String time) {
    return 'آخر نشاط $time';
  }

  @override
  String get securitySignOutSession => 'تسجيل الخروج';

  @override
  String get securitySignOutOthers => 'تسجيل الخروج من كل الجلسات الأخرى';

  @override
  String get securitySignOutOthersConfirm =>
      'تسجيل الخروج من كل مكان عدا هذا الهاتف؟';

  @override
  String securitySignOutSessionConfirm(String device) {
    return 'تسجيل الخروج من $device؟';
  }

  @override
  String get notificationSettingsTitle => 'الإشعارات';

  @override
  String get notificationSettingsPush => 'الإشعارات على هذا الهاتف';

  @override
  String get notificationSettingsPushOn => 'مفعّلة';

  @override
  String get notificationSettingsPushOff => 'متوقفة';

  @override
  String get notificationSettingsEmail => 'رسائل البريد عن تعلّمك';

  @override
  String get notificationSettingsEmailHelp =>
      'الدرجات والإعلانات والتذكيرات بالبريد. رسائل الأمان والحساب تُرسل دائمًا.';

  @override
  String get privacyTitle => 'الخصوصية والبيانات';

  @override
  String get privacyAnalytics => 'مشاركة بيانات استخدام مجهولة';

  @override
  String get privacyAnalyticsHelp =>
      'أي الشاشات تُستخدم ومتى تُنهى الدروس والاختبارات والواجبات، دون اسمك أو بريدك أو إجاباتك. يساعدنا ذلك على تحسين التطبيق.';

  @override
  String get privacyExport => 'تنزيل بياناتي';

  @override
  String get privacyExportHelp =>
      'نجهّز نسخة من بياناتك في أطلس. ستصلك رسالة عند جاهزيتها، ثم تنزّلها من هنا.';

  @override
  String privacyExportRequested(String date) {
    return 'طُلب $date';
  }

  @override
  String privacyExportReady(String date) {
    return 'جاهز للتنزيل حتى $date';
  }

  @override
  String get privacyExportDownload => 'تنزيل';

  @override
  String get privacyExportShare => 'حفظ الملف أو مشاركته';

  @override
  String get privacyDeleteAccount => 'حذف حسابي';

  @override
  String get privacyDeleteHelp =>
      'يحذف حسابك في أطلس في كل الأكاديميات: كورساتك وتقدّمك ونتائجك وشهاداتك. لا يمكن التراجع عن ذلك.';

  @override
  String get privacyDeleteNotAllowed =>
      'هذا الحساب يدير أكاديمية، لذا لا يمكن حذفه من التطبيق. اطلب الحذف من موقع أطلس.';

  @override
  String get privacyNeedsVerifiedEmail =>
      'لحماية حسابك نرسل رمزًا إلى بريدك أولًا، لذا يجب أن يكون موثّقًا. وثّقه من ملفك الشخصي.';

  @override
  String get privacyCodeTitle => 'أدخل الرمز الذي أرسلناه إلى بريدك';

  @override
  String privacyCodeBody(String email) {
    return 'أرسلنا رمزًا من ٦ أرقام إلى $email.';
  }

  @override
  String get privacyCodeContinue => 'متابعة';

  @override
  String get deleteConfirmTitle => 'حذف حسابك؟';

  @override
  String get deleteConfirmBody =>
      'سيُحذف حسابك في أطلس في كل الأكاديميات. سيضيع تقدّمك ونتائجك وشهاداتك، ولا يمكن التراجع عن ذلك.';

  @override
  String get deleteConfirmType => 'اكتب DELETE للتأكيد';

  @override
  String get deleteConfirmAction => 'حذف الحساب';

  @override
  String get deleteDone => 'تم حذف حسابك.';

  @override
  String get academiesTitle => 'أكاديمياتك';

  @override
  String get academiesCurrent => 'الحالية';

  @override
  String get academiesAdd => 'إضافة أكاديمية أخرى';

  @override
  String get catalogTitle => 'الكورسات المجانية';

  @override
  String get catalogBrowse => 'تصفّح الكورسات المجانية';

  @override
  String catalogBrowseBody(String academy) {
    return 'انضم إلى أي كورس مجاني في $academy وابدأ فورًا.';
  }

  @override
  String get catalogSearch => 'ابحث في الكورسات المجانية';

  @override
  String get catalogEmpty => 'لا توجد كورسات مجانية في هذه الأكاديمية حاليًا.';

  @override
  String get catalogNoResults => 'لا توجد كورسات مجانية تطابق بحثك.';

  @override
  String get catalogFree => 'مجاني';

  @override
  String get catalogLoadMore => 'عرض المزيد';

  @override
  String get catalogJoined => 'منضم';

  @override
  String get previewJoin => 'انضم مجانًا';

  @override
  String get previewOpen => 'افتح الكورس';

  @override
  String previewJoinedToast(String course) {
    return 'انضممت إلى $course.';
  }

  @override
  String get previewAbout => 'عن الكورس';

  @override
  String get previewOutcomes => 'ما ستتعلّمه';

  @override
  String get previewRequirements => 'قبل أن تبدأ';

  @override
  String get previewContent => 'محتوى الكورس';

  @override
  String get previewCertificate => 'شهادة عند الإتمام';

  @override
  String previewUnits(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n وحدة',
      many: '$n وحدة',
      few: '$n وحدات',
      two: 'وحدتان',
      one: 'وحدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String previewQuizzes(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n اختبار',
      many: '$n اختبارًا',
      few: '$n اختبارات',
      two: 'اختباران',
      one: 'اختبار واحد',
    );
    return '$_temp0';
  }

  @override
  String previewAssignments(int count, String n) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$n واجب',
      many: '$n واجبًا',
      few: '$n واجبات',
      two: 'واجبان',
      one: 'واجب واحد',
    );
    return '$_temp0';
  }

  @override
  String previewHours(String hours, String minutes) {
    return '$hours س $minutes د';
  }

  @override
  String get previewNotFree =>
      'هذا الكورس ليس مجانيًا. يمكنك الانضمام إليه من موقع الأكاديمية.';

  @override
  String get previewNotFound => 'هذا الكورس غير متاح. ربما أُلغي نشره.';

  @override
  String get enrollLimitReached =>
      'لا تستقبل هذه الأكاديمية طلابًا جددًا حاليًا. تواصل مع الأكاديمية.';

  @override
  String get levelBeginner => 'مبتدئ';

  @override
  String get levelIntermediate => 'متوسط';

  @override
  String get levelAdvanced => 'متقدّم';

  @override
  String get levelAll => 'كل المستويات';

  @override
  String get linkOpenFailed =>
      'تعذّر فتح هذا الرابط. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String linkSwitchTitle(String academy) {
    return 'فتح $academy؟';
  }

  @override
  String linkSwitchBody(String academy, String current) {
    return 'هذا الرابط خاص بـ$academy. ستبقى مسجّلًا في $current ويمكنك العودة إليها من حسابي.';
  }

  @override
  String get linkSwitchOpen => 'فتح';

  @override
  String get verifyTitle => 'تأكيد البريد الإلكتروني';

  @override
  String get verifyWorking => 'جارٍ تأكيد بريدك الإلكتروني…';

  @override
  String get verifyDone => 'تم تأكيد بريدك الإلكتروني.';

  @override
  String get verifyInvalid =>
      'رابط التأكيد هذا غير صالح. أرسل رابطًا جديدًا من ملفك الشخصي.';

  @override
  String get verifyOpenProfile => 'الانتقال إلى الملف الشخصي';

  @override
  String get resetTitle => 'اختر كلمة مرور جديدة';

  @override
  String resetBody(String academy) {
    return 'أدخل كلمة مرور جديدة لحسابك في $academy.';
  }

  @override
  String get resetChecking => 'جارٍ التحقق من الرابط…';

  @override
  String get resetSubmit => 'حفظ كلمة المرور الجديدة';

  @override
  String get resetInvalid =>
      'انتهت صلاحية رابط إعادة التعيين هذا أو استُخدم من قبل.';

  @override
  String get resetRequestNew => 'اطلب رابطًا جديدًا';

  @override
  String get resetDoneBody =>
      'سجّل الدخول بكلمة المرور الجديدة. تم تسجيل خروجك من كل الأجهزة.';

  @override
  String get pickerScan => 'مسح رمز QR';

  @override
  String get qrTitle => 'امسح رمز الأكاديمية';

  @override
  String get qrHint => 'وجّه الكاميرا إلى رمز QR الخاص بالأكاديمية.';

  @override
  String get qrTorch => 'الكشاف';

  @override
  String get qrNoPermission =>
      'يحتاج Atlas إلى الكاميرا لمسح الرمز. اسمح بها من إعدادات هاتفك، أو اكتب عنوان الأكاديمية بدلًا من ذلك.';

  @override
  String get qrUnavailable =>
      'الكاميرا غير متاحة حاليًا. اكتب عنوان الأكاديمية بدلًا من ذلك.';

  @override
  String get qrNotAcademy => 'هذا الرمز ليس عنوان أكاديمية.';

  @override
  String get tabTasks => 'المهام';

  @override
  String get tasksTitle => 'المهام';

  @override
  String get tasksTodo => 'مطلوبة';

  @override
  String get tasksAwaiting => 'بانتظار التصحيح';

  @override
  String get tasksGraded => 'مصحّحة';

  @override
  String get tasksEmptyTodo => 'لا يوجد مطلوب منك الآن.';

  @override
  String get tasksEmptyAwaiting => 'لا توجد مهام بانتظار التصحيح.';

  @override
  String get tasksEmptyGraded => 'لم تُصحَّح أي مهمة بعد.';

  @override
  String get tasksNone => 'لا توجد اختبارات أو واجبات في كورساتك بعد.';

  @override
  String get tasksInProgress => 'بدأته';

  @override
  String get tasksDraft => 'مسودة';

  @override
  String get tasksRetry => 'لم يكتمل التسليم';

  @override
  String tasksDue(String date) {
    return 'التسليم $date';
  }

  @override
  String tasksSubmitted(String date) {
    return 'سُلّم $date';
  }

  @override
  String get tasksAwaitingShort => 'للتصحيح';
}
