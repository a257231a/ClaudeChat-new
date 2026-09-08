import 'package:claudechat/services/our_home/our_home_festivals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixed-date solar festivals resolve to their emote key', () {
    expect(todaysAutoFestivalKey(DateTime(2026, 1, 1)), 'fw'); // 元旦节
    expect(todaysAutoFestivalKey(DateTime(2026, 2, 14)), 'vd'); // 情人节
    expect(todaysAutoFestivalKey(DateTime(2026, 12, 25)), 'xm'); // 圣诞节
    expect(
      todaysAutoFestivalKey(DateTime(2026, 11, 1)),
      'hw',
    ); // 万圣节
  });

  test('an ordinary date matches nothing', () {
    expect(todaysAutoFestivalKey(DateTime(2026, 7, 20)), isNull);
  });

  test('lunar new year (2026-02-17) resolves to 春节', () {
    // 2026-02-17 is lunar new year's day per the standard 6tail lunar
    // calendar data this package is a Dart port of — a real calendar
    // computation, not a hand-maintained guess.
    expect(todaysAutoFestivalKey(DateTime(2026, 2, 17)), 'sp');
  });
}
