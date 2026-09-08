import 'package:claudechat/services/our_home/our_home_emote_registry.dart';
import 'package:claudechat/services/our_home/our_home_emote_triggers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 35 poses are registered — the 28 cosmetic triggers plus the 7 economy-tied ones', () {
    // work='cd', sleep='sl' are continuous states; eat/bath/drink/snack/cook
    // ('et'/'sh'/'cf'/'ch'/'ck') are momentary actions — see
    // _OurHomePageState in app.dart for where these 7 are driven from real
    // state instead of a standalone chat-keyword trigger.
    const economyTiedKeys = {'sl', 'cd', 'et', 'sh', 'cf', 'ch', 'ck'};
    final expected = {...ourHomeEmoteTriggers.keys, ...economyTiedKeys};
    expect(expected.length, 35);
    expect(ourHomeEmoteDraw.keys.toSet(), expected);
  });
}
