import 'package:atlas_mobile/l10n/app_localizations_ar.dart';
import 'package:atlas_mobile/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English singular and plural', () {
    final l = AppLocalizationsEn();
    expect(l.lessonsCount(1, '1'), '1 lesson');
    expect(l.lessonsCount(12, '12'), '12 lessons');
    expect(l.previewAssignments(1, '1'), '1 assignment');
    expect(l.previewQuizzes(2, '2'), '2 quizzes');
  });

  test('Arabic number agreement', () {
    final l = AppLocalizationsAr();
    expect(l.lessonsCount(1, '١'), 'درس واحد');
    expect(l.lessonsCount(2, '٢'), 'درسان');
    expect(l.lessonsCount(5, '٥'), '٥ دروس');
    expect(l.lessonsCount(12, '١٢'), '١٢ درسًا');
    expect(l.lessonsCount(100, '١٠٠'), '١٠٠ درس');
    expect(l.previewUnits(3, '٣'), '٣ وحدات');
    expect(l.previewQuizzes(2, '٢'), 'اختباران');
    expect(l.previewAssignments(1, '١'), 'واجب واحد');
  });
}
