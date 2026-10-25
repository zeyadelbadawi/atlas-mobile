import 'package:atlas_mobile/app/web_paths.dart';
import 'package:atlas_mobile/core/notifications/notification_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web learner links open the matching app screen', () {
    expect(
      appPathForWebLink('/my/courses/c1/activities/q1'),
      '/course/c1/item/q1',
    );
    expect(
      appPathForWebLink('https://falcon.atlas.test/ar/my/courses/c1/learn/l2'),
      '/course/c1/lesson/l2',
    );
    expect(appPathForWebLink('/my/courses/c1'), '/course/c1');
    expect(
      appPathForWebLink('https://falcon.atlas.test/ar/my/certificates'),
      '/account/certificates',
    );
    expect(appPathForWebLink('/my-courses'), '/courses');
    expect(appPathForWebLink('/my/devices?x=1'), '/account/devices');
    // Nothing for it in the app (e.g. purchases): the feed, not a dead end.
    expect(appPathForWebLink('/my/purchases'), '/notifications');
    expect(appPathForWebLink(null), '/notifications');
  });

  test('notification texts fill values and use Arabic digits', () {
    final catalog = NotificationCatalog({
      'en': {
        'events': {
          'graded': {'title': 'Graded: {{title}} ({{score}})'},
        },
      },
      'ar': {
        'events': {
          'graded': {'title': 'تم التقييم: {{title}} ({{score}})'},
        },
      },
    });
    String digits(String s) => s.replaceAll('9', '٩');
    expect(
      catalog.text('notifications:events.graded.title', 'ar', {
        'title': 'واجب',
        'score': 9,
      }, digits),
      'تم التقييم: واجب (٩)',
    );
    expect(
      catalog.text('notifications:events.graded.title', 'en', {
        'title': 'HW',
        'score': 9.5,
      }),
      'Graded: HW (9.5)',
    );
    expect(catalog.text('notifications:events.unknown.title', 'en'), isNull);
  });
}
