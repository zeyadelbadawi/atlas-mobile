import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/deep_links.dart';
import '../../app/providers.dart';
import '../../app/ui_helpers.dart';
import '../../core/academy/academy.dart';
import '../../design/design.dart';

/// First screen: the learner finds their academy by its address or short
/// name, or reopens a recent one. Atlas's own palette (no academy yet).
class AcademyPickerScreen extends ConsumerStatefulWidget {
  const AcademyPickerScreen({super.key});

  @override
  ConsumerState<AcademyPickerScreen> createState() =>
      _AcademyPickerScreenState();
}

class _AcademyPickerScreenState extends ConsumerState<AcademyPickerScreen> {
  final _field = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _open([Academy? recent]) async {
    final l = context.l10n;
    final dir = ref.read(academyDirectoryProvider);
    String? host = recent?.host;
    if (host == null) {
      if (_field.text.trim().isEmpty) {
        return setState(() => _error = l.pickerEmptyField);
      }
      host = dir.hostFor(_field.text);
      if (host == null) return setState(() => _error = l.pickerInvalid);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final academy = await dir.resolve(host);
      if (!mounted) return;
      // A full link (a course, a reset link…) opens that screen next.
      final link = recent == null
          ? parseAcademyLink(Uri.tryParse(_field.text.trim()) ?? Uri())
          : null;
      if (link != null) ref.read(deepLinkProvider.notifier).queue(link);
      await ref.read(sessionProvider.notifier).chooseAcademy(academy);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorText(ref, context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    final value = await context.push<String>('/picker/scan');
    if (value == null || !mounted) return;
    final dir = ref.read(academyDirectoryProvider);
    final uri = Uri.tryParse(value);
    final host = uri != null && uri.hasScheme ? uri.host : dir.hostFor(value);
    if (host == null || host.isEmpty || !host.contains('.')) {
      return setState(() => _error = context.l10n.qrNotAcademy);
    }
    _field.text = value;
    await _open();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = context.atlas;
    final store = ref.watch(academyStoreProvider);
    final recent = store.recent;
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoverBand.home(
              academyName: l.appName,
              greeting: l.pickerTitle,
              overlap: 0,
              form: true,
            ),
            Padding(
              padding: const EdgeInsets.all(AtlasSpace.gutter),
              child: ReadableWidth(
                form: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.pickerBody,
                      style: a.type.body.copyWith(color: a.colors.inkSecondary),
                    ),
                    const SizedBox(height: AtlasSpace.s20),
                    AtlasTextField(
                      label: l.pickerFieldLabel,
                      controller: _field,
                      hint: l.pickerFieldHint,
                      ltrValue: true,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      autofillHints: const [AutofillHints.url],
                      error: _error,
                      onSubmitted: (_) => _open(),
                    ),
                    const SizedBox(height: AtlasSpace.s16),
                    AtlasButton(
                      label: l.pickerOpen,
                      loading: _busy,
                      onPressed: _busy ? null : _open,
                    ),
                    const SizedBox(height: AtlasSpace.s8),
                    AtlasButton(
                      label: l.pickerScan,
                      icon: LucideIcons.scanQrCode,
                      style: AtlasButtonStyle.plain,
                      onPressed: _busy ? null : _scan,
                    ),
                    if (recent.isNotEmpty) ...[
                      SectionHeader(title: l.pickerRecent),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AtlasRadius.lg),
                        child: Column(
                          children: [
                            for (final academy in recent)
                              Dismissible(
                                key: ValueKey(academy.host),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: a.colors.danger,
                                  alignment: AlignmentDirectional.centerEnd,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    l.pickerRemoveRecent,
                                    style: a.type.headline.copyWith(
                                      color: a.colors.raised,
                                    ),
                                  ),
                                ),
                                onDismissed: (_) async {
                                  await store.removeRecent(academy);
                                  setState(() {});
                                },
                                child: AcademyRow(
                                  name: academy.name,
                                  host: academy.host,
                                  color: AcademyPalette.fromHslString(
                                    academy.primaryColor,
                                  ).cover,
                                  logo: NetworkImage(
                                    academy.logoUrl.toString(),
                                  ),
                                  onTap: _busy ? null : () => _open(academy),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AtlasSpace.s32),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AtlasSpace.s8,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/about'),
                          child: Text(l.pickerAboutAtlas),
                        ),
                        TextButton(
                          onPressed: () => context.push('/legal/privacy'),
                          child: Text(l.legalPrivacy),
                        ),
                        TextButton(
                          onPressed: () => context.push('/legal/terms'),
                          child: Text(l.legalTerms),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
