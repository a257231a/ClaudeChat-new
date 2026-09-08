import 'package:claudechat/services/our_home/our_home_actions.dart';
import 'package:claudechat/services/our_home/our_home_emote_triggers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every cosmetic emote key matches a real sample phrase', () {
    const samples = <String, String>{
      'lm': '想听歌',
      'rd': '去看书吧',
      'gt': '弹吉他',
      'pt': '画画',
      'wt': '该浇花了',
      'ph': '拍照',
      'gm': '打游戏',
      'ex': '锻炼一下',
      'bd': '今天生日',
      'fw': '放烟花',
      'xm': '圣诞快乐',
      'hp': '好开心',
      'ag': '气死了',
      'dc': '跳舞',
      'sg': '唱歌',
      'sp': '春节到了',
      'ma': '中秋节',
      'db': '端午安康',
      'hw': '万圣节',
      'lf': '元宵节',
      'vd': '情人节',
      'qx': '七夕',
      'jj': '好着急',
      'hu': '受伤了',
      'dz': '打瞌睡',
      'ty': '玩玩具',
      'tv': '看电视',
      'jg': '杂耍',
    };
    expect(samples.keys.toSet(), ourHomeEmoteTriggers.keys.toSet());
    for (final entry in samples.entries) {
      expect(
        matchOurHomeEmoteKey(entry.value),
        entry.key,
        reason: '"${entry.value}" should match emote "${entry.key}"',
      );
    }
  });

  test('mood-delta table only covers keys that actually exist', () {
    // 'sl' (sleep) is the one mood-delta entry driven by a real economy
    // action (startSleep/OurHomeState.settleSleepWake) rather than a
    // standalone chat-keyword trigger — see _OurHomePageState's
    // sleep-is-continuous handling in app.dart.
    const economyTied = {'sl'};
    for (final key in ourHomeEmoteMoodDelta.keys) {
      if (economyTied.contains(key)) continue;
      expect(
        ourHomeEmoteTriggers.containsKey(key),
        isTrue,
        reason: '$key has a mood delta but no trigger entry',
      );
    }
  });

  test('cosmetic emote keywords never collide with economy action keywords', () {
    for (final entry in ourHomeEmoteTriggers.entries) {
      final sample = _firstAlternative(entry.value.pattern);
      expect(
        matchOurHomeAction(sample),
        isNull,
        reason:
            '"$sample" (meant to trigger emote "${entry.key}") also matches an economy action',
      );
    }
  });

  test('unmatched free text returns null', () {
    expect(matchOurHomeEmoteKey('今天天气不错'), isNull);
  });
}

/// Pulls the first `|`-separated alternative out of a trigger's regex source
/// (e.g. "听歌|音乐" -> "听歌") so the collision test has a concrete phrase
/// to feed into the economy-action matcher.
String _firstAlternative(String pattern) => pattern.split('|').first;
