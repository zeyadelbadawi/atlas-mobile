import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/config/app_env.dart';
import '../../design/design.dart';

/// Atlas's own policies, served by the web on Atlas's host (Arabic under
/// `/ar/...`). Refund and cookie policies join this list when the web
/// publishes them (plan §5, W1).
enum LegalDoc {
  terms('terms', '/terms'),
  privacy('privacy', '/privacy-policy');

  const LegalDoc(this.id, this.path);
  final String id;
  final String path;

  static LegalDoc? byId(String id) =>
      values.where((d) => d.id == id).firstOrNull;

  Uri url(String languageCode) =>
      Uri.https(AppEnv.platformHost, languageCode == 'ar' ? '/ar$path' : path);

  String title(BuildContext context) => switch (this) {
    LegalDoc.terms => context.l10n.legalTerms,
    LegalDoc.privacy => context.l10n.legalPrivacy,
  };
}

class LegalListScreen extends StatelessWidget {
  const LegalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormScreen(
      title: l.legalTitle,
      children: [
        SettingsGroup(
          children: [
            SettingsRow(
              title: l.legalTerms,
              icon: LucideIcons.scrollText,
              onTap: () => context.push('/legal/terms'),
            ),
            SettingsRow(
              title: l.legalPrivacy,
              icon: LucideIcons.shieldCheck,
              onTap: () => context.push('/legal/privacy'),
            ),
            SettingsRow(
              title: l.aboutTitle,
              icon: LucideIcons.info,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
      ],
    );
  }
}

/// One policy, rendered from the web page so app and web never disagree.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.doc});
  final LegalDoc doc;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  WebViewController? _controller;
  bool _loading = true, _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final url = widget.doc.url(context.languageCode);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(context.atlas.colors.paper)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) =>
              mounted ? setState(() => _loading = false) : null,
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _failed = true);
          },
          // Stay on Atlas's host; anything else is not part of the policy.
          onNavigationRequest: (r) =>
              Uri.parse(r.url).host == AppEnv.platformHost
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(url);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc.title(context))),
      body: _failed
          ? Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: Column(
                children: [
                  AtlasBanner(
                    kind: AtlasBannerKind.error,
                    message: l.legalLoadFailed,
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  AtlasButton(
                    label: l.commonRetry,
                    style: AtlasButtonStyle.tonal,
                    onPressed: () {
                      setState(() {
                        _failed = false;
                        _loading = true;
                      });
                      _controller!.reload();
                    },
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
    );
  }
}

/// Business details (App Store and Play require them) and the version.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final v = ref.watch(appVersionProvider);
    return FormScreen(
      title: l.aboutTitle,
      children: [
        Text(
          l.aboutBody,
          style: a.type.body.copyWith(color: a.colors.inkSecondary),
        ),
        SectionHeader(title: l.aboutCompany),
        SettingsGroup(
          children: [
            SettingsRow(
              title: l.aboutLegalName,
              icon: LucideIcons.building2,
              value: AppEnv.legalName,
            ),
            SettingsRow(
              title: l.aboutAddress,
              icon: LucideIcons.mapPin,
              value: l.aboutAddressValue,
            ),
            SettingsRow(
              title: l.aboutEmail,
              icon: LucideIcons.mail,
              value: AppEnv.supportEmail,
              valueLtr: true,
            ),
            SettingsRow(
              title: l.aboutPhone,
              icon: LucideIcons.phone,
              value: AppEnv.supportPhone,
              valueLtr: true,
            ),
            SettingsRow(
              title: l.aboutVersion,
              icon: LucideIcons.info,
              value: '${v.version} (${v.build})',
              valueLtr: true,
            ),
          ],
        ),
        const SizedBox(height: AtlasSpace.s24),
        SettingsGroup(
          children: [
            SettingsRow(
              title: l.legalTerms,
              icon: LucideIcons.scrollText,
              onTap: () => context.push('/legal/terms'),
            ),
            SettingsRow(
              title: l.legalPrivacy,
              icon: LucideIcons.shieldCheck,
              onTap: () => context.push('/legal/privacy'),
            ),
          ],
        ),
      ],
    );
  }
}
