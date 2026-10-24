import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design.dart';

/// Sample compositions of the design system, used for review and goldens.
/// Content is illustrative (labelled sample data), never shipped as real.
class GallerySamples {
  static bool _ar(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  static String n(BuildContext context, String latin) {
    if (!_ar(context)) return latin;
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return latin.split('').map((ch) {
      final i = int.tryParse(ch);
      return i == null ? ch : d[i];
    }).join();
  }

  static const segments = [
    ProgressSegment(minutes: 12, watched: 1),
    ProgressSegment(minutes: 18, watched: 1),
    ProgressSegment(minutes: 9, watched: 1),
    ProgressSegment(minutes: 22, watched: 0.35),
    ProgressSegment(minutes: 14),
    ProgressSegment(minutes: 16),
    ProgressSegment(minutes: 8),
    ProgressSegment(minutes: 20),
  ];
}

/// Home, as the design system composes it (phase 3 builds the real one).
class HomeSample extends StatelessWidget {
  const HomeSample({super.key, required this.academyName, this.platform});

  final String academyName;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final ar = GallerySamples._ar(context);
    String n(String s) => GallerySamples.n(context, s);
    final c = context.atlas.colors;
    final tabs = [
      AtlasTab(icon: LucideIcons.house, label: ar ? 'الرئيسية' : 'Home'),
      AtlasTab(
        icon: LucideIcons.bookOpen,
        label: ar ? 'كورساتي' : 'My courses',
      ),
      AtlasTab(
        icon: LucideIcons.bell,
        label: ar ? 'الإشعارات' : 'Notifications',
        badge: true,
      ),
      AtlasTab(icon: LucideIcons.circleUser, label: ar ? 'حسابي' : 'Account'),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: c.paper,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoverBand.home(
              academyName: academyName,
              greeting: ar ? 'أهلاً، زياد' : 'Hi, Zeyad',
            ),
            // Painted after the cover, so the panel sits over its lower edge.
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AtlasSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContinuePanel(
                      unitLabel: ar ? 'الدرس' : 'Lesson',
                      lessonNumber: n('12'),
                      lessonTitle: ar
                          ? 'النهايات من جهة واحدة'
                          : 'One-sided limits',
                      courseLine: ar
                          ? 'التفاضل والتكامل، الوحدة الثانية'
                          : 'Calculus · Unit 2',
                      segments: GallerySamples.segments,
                      timeLeft: ar ? 'باقي ${n('14')} دقيقة' : '14 min left',
                      countLabel: ar
                          ? '${n('3')} من ${n('8')} دروس'
                          : '3 of 8 lessons',
                      resumeLabel: ar ? 'استكمل الدرس' : 'Resume lesson',
                      onResume: () {},
                    ),
                    SectionHeader(
                      title: ar ? 'المطلوب قريب' : 'Due soon',
                      action: ar ? 'الكل' : 'All',
                      onAction: () {},
                    ),
                    DueRow(
                      day: n('27'),
                      weekday: ar ? 'الخميس' : 'Thu',
                      title: ar ? 'كويز الفصل الثاني' : 'Chapter 2 quiz',
                      meta: ar
                          ? 'كويز، ${n('20')} سؤال، ${n('8:00')} م'
                          : 'Quiz · 20 questions · 8:00 PM',
                      icon: LucideIcons.listChecks,
                      onTap: () {},
                    ),
                    DueRow(
                      day: n('29'),
                      weekday: ar ? 'السبت' : 'Sat',
                      title: ar
                          ? 'واجب ٢٣: تطبيقات النهايات'
                          : 'Assignment 23: limits',
                      meta: ar
                          ? 'الموعد اتغيّر، ${n('2:00')} م'
                          : 'Deadline moved · 2:00 PM',
                      icon: LucideIcons.fileText,
                      changed: true,
                      onTap: () {},
                    ),
                    SectionHeader(title: ar ? 'كورساتي' : 'My courses'),
                    CourseRow(
                      title: ar ? 'التفاضل والتكامل' : 'Calculus',
                      subtitle: ar
                          ? 'أ. أحمد سمير، ${n('20')} درس'
                          : 'Mr Ahmed Samir · 20 lessons',
                      cover: CourseCover(
                        kicker: ar ? 'الوحدة' : 'Unit',
                        mark: n('02'),
                      ),
                      segments: GallerySamples.segments,
                      status: ar
                          ? '${n('38')}٪، آخر درس امبارح'
                          : '38% · last lesson yesterday',
                      onTap: () {},
                    ),
                    CourseRow(
                      title: ar ? 'الفيزياء: الكهربية' : 'Physics: electricity',
                      subtitle: ar
                          ? 'أ. منى عادل، ${n('14')} درس'
                          : 'Ms Mona Adel · 14 lessons',
                      cover: CourseCover(
                        kicker: ar ? 'كورس' : 'Course',
                        mark: n('04'),
                      ),
                      status: ar
                          ? 'مجاني، ماسجّلتش لسه'
                          : 'Free · not joined yet',
                      onTap: () {},
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AtlasTabBar(
        tabs: tabs,
        index: 0,
        onSelect: (_) {},
        platform: platform,
      ),
    );
  }
}

/// Sign-in, as the design system composes it.
class SignInSample extends StatelessWidget {
  const SignInSample({
    super.key,
    required this.academyName,
    required this.host,
  });

  final String academyName;
  final String host;

  @override
  Widget build(BuildContext context) {
    final ar = GallerySamples._ar(context);
    final a = context.atlas;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          CoverBand.compact(academyName: academyName, host: host),
          Padding(
            padding: const EdgeInsets.all(AtlasSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ar ? 'سجّل دخولك' : 'Sign in',
                  style: a.type.title1.copyWith(color: a.colors.ink),
                ),
                const SizedBox(height: 20),
                AtlasBanner(
                  kind: AtlasBannerKind.error,
                  message: ar
                      ? 'البريد أو كلمة السر مش صح. جرّب تاني أو غيّر كلمة السر.'
                      : 'That email or password is not right. Try again or reset your password.',
                ),
                const SizedBox(height: 16),
                AtlasTextField(
                  label: ar ? 'البريد الإلكتروني' : 'Email',
                  hint: 'name@example.com',
                  ltrValue: true,
                ),
                const SizedBox(height: 16),
                AtlasTextField(
                  label: ar ? 'كلمة السر' : 'Password',
                  password: true,
                  ltrValue: true,
                  error: ar ? 'اكتب كلمة السر' : 'Enter your password',
                ),
                const SizedBox(height: 24),
                AtlasButton(
                  label: ar ? 'تسجيل الدخول' : 'Sign in',
                  onPressed: () {},
                ),
                const SizedBox(height: 8),
                AtlasButton(
                  label: ar ? 'نسيت كلمة السر؟' : 'Forgot password?',
                  style: AtlasButtonStyle.plain,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                CheckboxRow(
                  value: true,
                  onChanged: (_) {},
                  label: TextSpan(
                    text: ar ? 'عندي ١٣ سنة أو أكتر' : 'I am 13 or older',
                  ),
                ),
                CheckboxRow(
                  value: false,
                  onChanged: (_) {},
                  label: TextSpan(
                    children: [
                      TextSpan(text: ar ? 'موافق على ' : 'I agree to the '),
                      TextSpan(
                        text: ar ? 'الشروط' : 'Terms',
                        style: TextStyle(
                          color: a.colors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ar ? ' و' : ' and '),
                      TextSpan(
                        text: ar ? 'سياسة الخصوصية' : 'Privacy Policy',
                        style: TextStyle(
                          color: a.colors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CodeInput(
                  controller: TextEditingController(text: '540'),
                  autofocus: false,
                ),
                const SizedBox(height: 16),
                AtlasButton(
                  label: ar ? 'إنشاء الحساب' : 'Create account',
                  onPressed: null,
                ),
                const SizedBox(height: 8),
                AtlasButton(
                  label: ar ? 'جاري الإرسال' : 'Sending',
                  loading: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 24),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      title: ar ? 'سياسة الخصوصية' : 'Privacy policy',
                      icon: LucideIcons.lock,
                      onTap: () {},
                    ),
                    SettingsRow(
                      title: ar ? 'الإصدار' : 'Version',
                      icon: LucideIcons.info,
                      value: '1.0.0 (1)',
                      valueLtr: true,
                    ),
                    SettingsRow(
                      title: ar ? 'حذف الحساب' : 'Delete account',
                      icon: LucideIcons.trash2,
                      destructive: true,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
