import 'package:lunar/lunar.dart';

import 'our_home_emote_triggers.dart';

/// Auto-detects whether [date] (default: today) is a festival ClaudeChat has
/// a real emote pose for, using the `lunar` package — a Dart port of the
/// same 6tail lunar-calendar family the standalone demo used via
/// lunar-javascript, so this gives real solar+lunar festival dates rather
/// than a hand-maintained year-by-year lookup table. Returns the matching
/// emote key (via the same [matchOurHomeEmoteKey] regexes the chat triggers
/// use, so the two can never drift out of sync with each other), or null if
/// today isn't one of the ~9 festivals with a real pose.
String? todaysAutoFestivalKey([DateTime? date]) {
  final now = date ?? DateTime.now();
  final solarFestivals = Solar.fromDate(now).getFestivals();
  final lunarFestivals = Lunar.fromDate(now).getFestivals();
  for (final name in [...solarFestivals, ...lunarFestivals]) {
    final key = matchOurHomeEmoteKey(name);
    if (key != null) return key;
  }
  return null;
}
