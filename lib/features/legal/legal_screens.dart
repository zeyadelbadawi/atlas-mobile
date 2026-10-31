import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/config/app_env.dart';
import '../../core/legal/legal_document.dart';
import '../../design/design.dart';

/// Atlas's own policies, bundled with the app (`assets/legal`, synced from
/// the web by `tool/sync_legal.mjs`) and shown natively. Refund and cookie
/// policies join this list when the web publishes them (plan §5, W1).
enum LegalDoc {
  terms('terms'),
  privacy('privacy');

  const LegalDoc(this.id);
  final String id;

  static LegalDoc? byId(String id) =>
      values.where((d) => d.id == id).firstOrNull;

  String title(BuildContext context) => switch (this) {
    LegalDoc.terms => context.l10n.legalTerms,
    LegalDoc.privacy => context.l10n.legalPrivacy,
  };

  IconData get icon => switch (this) {
    LegalDoc.terms => LucideIcons.scrollText,
    LegalDoc.privacy => LucideIcons.shieldCheck,
  };
}

class LegalListScreen extends StatelessWidget {
  const LegalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormScreen(
      title: l.legalTitle,
      icon: LucideIcons.scrollText,
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

/// One policy, read natively: what it covers, when it changed, a contents
/// list that jumps to each section, then the sections themselves.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.doc});
  final LegalDoc doc;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  Future<LegalDocument>? _load;
  String? _lang;
  final _keys = <String, GlobalKey>{};
  final _scroll = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.languageCode;
    if (lang == _lang) return;
    _lang = lang;
    _load = LegalDocument.load(widget.doc.id, lang);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(String id) {
    final target = _keys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: AtlasMotion.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.doc.title(context))),
      body: FutureBuilder<LegalDocument>(
        future: _load,
        builder: (context, snap) {
          final doc = snap.data;
          if (doc == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return _body(context, doc);
        },
      ),
    );
  }

  Widget _body(BuildContext context, LegalDocument doc) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    for (final s in doc.sections) {
      _keys.putIfAbsent(s.id, GlobalKey.new);
    }
    return Scrollbar(
      controller: _scroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          AtlasSpace.gutter,
          AtlasSpace.s8,
          AtlasSpace.gutter,
          48 + MediaQuery.paddingOf(context).bottom,
        ),
        child: ReadableWidth(
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Entrance(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconTile(icon: widget.doc.icon, size: 56),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s16),
                Entrance(
                  order: 1,
                  child: Semantics(
                    header: true,
                    child: Text(
                      doc.title,
                      style: a.type.title1.copyWith(color: c.ink),
                    ),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s8),
                Entrance(
                  order: 2,
                  child: Text(
                    doc.summary,
                    style: a.type.body.copyWith(color: c.inkSecondary),
                  ),
                ),
                const SizedBox(height: AtlasSpace.s12),
                Entrance(
                  order: 2,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (doc.lastUpdated.isNotEmpty)
                        _Chip(l.legalLastUpdated(doc.lastUpdated)),
                      if (doc.effectiveDate.isNotEmpty)
                        _Chip(l.legalEffective(doc.effectiveDate)),
                    ],
                  ),
                ),
                SectionHeader(title: l.legalContents),
                Entrance(
                  order: 3,
                  child: SettingsGroup(
                    children: [
                      for (final s in doc.sections)
                        SettingsRow(title: s.heading, onTap: () => _jump(s.id)),
                    ],
                  ),
                ),
                for (final s in doc.sections)
                  _SectionView(key: _keys[s.id], section: s),
                const SizedBox(height: AtlasSpace.s24),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 420),
                      curve: AtlasMotion.easeInOut,
                    ),
                    icon: const Icon(LucideIcons.arrowUp, size: 18),
                    label: Text(l.legalBackToTop),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: BorderRadius.circular(AtlasRadius.sm),
      ),
      child: Text(label, style: a.type.footnote.copyWith(color: c.ink)),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({super.key, required this.section});
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final a = context.atlas;
    final c = a.colors;
    final body = a.type.body.copyWith(color: c.ink, height: 1.6);
    return Padding(
      padding: const EdgeInsets.only(top: AtlasSpace.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              section.heading,
              style: a.type.title3.copyWith(color: c.ink),
            ),
          ),
          for (final block in section.blocks) ...[
            const SizedBox(height: AtlasSpace.s12),
            switch (block) {
              LegalParagraph(:final text) => Text(text, style: body),
              LegalList(:final items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item, style: body)),
                        ],
                      ),
                    ),
                ],
              ),
              LegalDefinitions(:final items) => AtlasCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, d) in items.indexed)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: i == items.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: c.rule)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              d.term,
                              style: a.type.headline.copyWith(color: c.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.detail,
                              style: a.type.subhead.copyWith(
                                color: c.inkSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            },
          ],
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtlasLockup(
            height: 30,
            markColor: a.colors.accent,
            wordColor: a.colors.ink,
          ),
        ),
        const SizedBox(height: AtlasSpace.s16),
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
              onTap: () =>
                  _open(Uri(scheme: 'mailto', path: AppEnv.supportEmail)),
            ),
            SettingsRow(
              title: l.aboutPhone,
              icon: LucideIcons.phone,
              value: AppEnv.supportPhone,
              valueLtr: true,
              onTap: () =>
                  _open(Uri(scheme: 'tel', path: AppEnv.supportPhoneDial)),
            ),
            SettingsRow(
              title: l.aboutWhatsapp,
              icon: LucideIcons.messageCircle,
              value: AppEnv.supportPhone,
              valueLtr: true,
              onTap: () => _open(
                Uri.https('wa.me', AppEnv.supportPhoneDial.substring(1)),
              ),
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

/// Mail, dialer or WhatsApp: the system app, never an in-app browser.
Future<void> _open(Uri uri) => launchUrl(
  uri,
  mode: LaunchMode.externalApplication,
).catchError((_) => false);
