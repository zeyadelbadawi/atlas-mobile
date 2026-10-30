/// Build-time settings. Override with `--dart-define`.
abstract final class AppEnv {
  /// Atlas's own host: academy lookup, mobile config, Atlas's policies.
  static const platformHost = String.fromEnvironment(
    'ATLAS_PLATFORM_HOST',
    defaultValue: 'atlass.dpdns.org',
  );

  /// Version strings of the policies the app shows at sign-up, recorded with
  /// the consent (B4). Bump when the web's Terms / Privacy Policy change
  /// ("Last updated" on the web page).
  static const termsVersion = 'terms-2026-10-09';
  static const privacyVersion = 'privacy-2026-10-30';

  /// Business details for the About screen (App Store / Play requirement).
  static const legalName = 'Atlas';
  static const supportEmail = 'info@atlas.com';

  /// Shown as is; [supportPhoneDial] is what the dialer and WhatsApp get.
  static const supportPhone = '+20\u00A0100\u00A0051\u00A00491';
  static const supportPhoneDial = '+201000510491';
}
