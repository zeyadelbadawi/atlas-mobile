import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/push.dart';
import '../../app/learning_providers.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/learning/assessment_models.dart';
import '../../design/design.dart';
import '../learning/learning_ui.dart';
import '../quiz/assessment_widgets.dart';

/// The learner's certificates. Three honest states: the academy issues
/// none (said plainly, so an empty list never reads as "you earned none"),
/// none earned yet, or the cards — withdrawn ones included with their
/// reason. A download is never a stored link: "Open PDF" asks for a fresh
/// signed one at that moment.
class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final value = ref.watch(certificatesProvider);
    return ScrollTitleScaffold(
      title: l.certificatesTitle,
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.refresh(certificatesProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AtlasSpace.gutter,
            0,
            AtlasSpace.gutter,
            48,
          ),
          children: [
            ReadableWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.certificatesTitle,
                      style: a.type.title1.copyWith(color: c.ink),
                    ),
                  ),
                  const SizedBox(height: AtlasSpace.s16),
                  AsyncBody<LearnerCertificates>(
                    value: value,
                    onRetry: () => ref.invalidate(certificatesProvider),
                    data: (list) {
                      if (list.items.isEmpty) {
                        return _Empty(
                          title: list.enabled
                              ? l.certificatesEmptyTitle
                              : l.certificatesOff,
                          body: list.enabled ? l.certificatesEmptyBody : null,
                        );
                      }
                      return Column(
                        children: [
                          for (final cert in list.items)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AtlasSpace.s16,
                              ),
                              child: Entrance(
                                order: list.items.indexOf(cert),
                                child: CertificateCard(certificate: cert),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, this.body});
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: LucideIcons.award, title: title, body: body);
}

class CertificateCard extends ConsumerStatefulWidget {
  const CertificateCard({super.key, required this.certificate});
  final Certificate certificate;

  @override
  ConsumerState<CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends ConsumerState<CertificateCard> {
  bool _opening = false, _copied = false;
  String? _error;

  Uri _verifyUrl() {
    final host = ref.read(sessionProvider).academy!.host;
    return Uri.https(host, '/verify/${widget.certificate.verificationCode}');
  }

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final link = await ref
          .read(assessmentRepositoryProvider)
          .certificateDownload(widget.certificate.id);
      ref.read(analyticsProvider).event('certificate_open');
      await launchUrl(Uri.parse(link.url), mode: LaunchMode.inAppBrowserView);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: widget.certificate.codeDisplay),
    );
    if (mounted) setState(() => _copied = true);
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: context.l10n.certificateShareText(
          widget.certificate.courseTitle,
          _verifyUrl().toString(),
        ),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final c = a.colors;
    final cert = widget.certificate;
    final d = context.digits;
    final live = !cert.revoked;
    final band = c.brightness == Brightness.light
        ? AtlasBrand.navy600
        : AtlasBrand.navy800;
    final onBand = live ? Colors.white : c.ink;
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(AtlasRadius.xl),
        border: Border.all(color: c.rule),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Atlas Navy with a gold seal: a certificate is one of the few
          // gold moments in the app.
          Container(
            decoration: BoxDecoration(
              color: live ? band : c.sunken,
              border: live
                  ? const Border(
                      bottom: BorderSide(color: AtlasBrand.gold, width: 3),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (live)
                  PositionedDirectional(
                    end: -36,
                    bottom: -56,
                    child: ExcludeSemantics(
                      child: AtlasMark(
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: live ? AtlasBrand.gold : c.rule,
                          ),
                          child: Icon(
                            LucideIcons.award,
                            size: 26,
                            color: live ? AtlasBrand.onGold : c.inkTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cert.courseTitle,
                              textDirection: contentDirection(
                                context,
                                cert.courseTitle,
                              ),
                              style: a.type.title3.copyWith(color: onBand),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cert.nameOnCertificate,
                              style: a.type.subhead.copyWith(
                                color: live
                                    ? AtlasBrand.navy100
                                    : c.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (cert.revoked)
                      StatusPill(
                        label: l.certificateRevoked,
                        tone: PillTone.danger,
                      ),
                    Text(
                      [
                        if (cert.issuedAt != null)
                          l.certificateIssued(
                            shortDate(context, cert.issuedAt!),
                          ),
                        if (cert.overallScore != null)
                          l.certificateScore(
                            d('${cert.overallScore!.round()}'),
                          ),
                      ].join(context.sep),
                      style: a.type.footnote.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
                if (cert.revoked) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (cert.revokedAt != null)
                        l.certificateRevokedOn(
                          shortDate(context, cert.revokedAt!),
                        ),
                      if (cert.revokeReason?.isNotEmpty ?? false)
                        l.certificateRevokedReason(cert.revokeReason!),
                    ].join(context.sep),
                    style: a.type.subhead.copyWith(color: c.ink),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  l.certificateCode,
                  style: a.type.footnote.copyWith(color: c.inkSecondary),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  // Copied with the button beside it.
                  child: Text(
                    cert.codeDisplay,
                    style: a.type.title2.copyWith(
                      color: c.ink,
                      letterSpacing: 1.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  '${l.certificateSerial}: ${cert.serial}',
                  style: a.type.caption.copyWith(color: c.inkTertiary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: _copy,
                      icon: Icon(
                        _copied ? LucideIcons.check : LucideIcons.copy,
                        size: 18,
                      ),
                      label: Text(
                        _copied ? l.certificateCopied : l.certificateCopyCode,
                      ),
                    ),
                    if (!cert.revoked)
                      Builder(
                        builder: (b) => TextButton.icon(
                          onPressed: () => _share(b),
                          icon: const Icon(LucideIcons.share2, size: 18),
                          label: Text(l.certificateShare),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cert.revoked)
                  const SizedBox.shrink()
                else if (cert.renderStatus == 'pending')
                  Row(
                    children: [
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${l.certificatePreparing} ${l.certificatePreparingHint}',
                          style: a.type.subhead.copyWith(color: c.ink),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(certificatesProvider),
                        child: Text(l.certificateRefresh),
                      ),
                    ],
                  )
                else if (cert.renderStatus == 'failed')
                  AtlasBanner(
                    kind: AtlasBannerKind.error,
                    message: l.certificateFailed,
                  )
                else
                  AtlasButton(
                    label: l.certificateDownload,
                    icon: LucideIcons.fileDown,
                    loading: _opening,
                    onPressed: _opening ? null : _open,
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  AtlasBanner(kind: AtlasBannerKind.error, message: _error!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
