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
      'اكتب عنوان موقع أكاديميتك كما أرسلته لك، أو اسمها المختصر.';

  @override
  String get pickerFieldLabel => 'عنوان الأكاديمية';

  @override
  String get pickerFieldHint => 'academy.atlass.dpdns.org';

  @override
  String get pickerOpen => 'فتح الأكاديمية';

  @override
  String get pickerRecent => 'آخر الأكاديميات';

  @override
  String get pickerRemoveRecent => 'إزالة';

  @override
  String get pickerEmptyField => 'اكتب عنوان أكاديميتك.';

  @override
  String get pickerInvalid => 'هذا لا يبدو عنوان موقع. راجعه وحاول مرة أخرى.';

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
}
