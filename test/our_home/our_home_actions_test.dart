import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:claudechat/services/our_home/economy_data.dart';
import 'package:claudechat/services/our_home/our_home_actions.dart';
import 'package:claudechat/services/our_home/our_home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

OurHomeEconomyData loadRealData() {
  final file = File('assets/our_home/economy.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return OurHomeEconomyData.fromJson(json);
}

Future<OurHomeState> freshState(OurHomeEconomyData data, {int? seed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return OurHomeState(
    data: data,
    prefs: prefs,
    random: seed == null ? null : math.Random(seed),
  );
}

void main() {
  final data = loadRealData();

  test('adventure/library/mystery/escape/outing each start the right long activity', () async {
    final adventure = await freshState(data);
    await performOurHomeAction(adventure, 'adventure');
    expect(adventure.longActivity?.kind, 'adventure');

    final library = await freshState(data);
    await performOurHomeAction(library, 'library');
    expect(library.longActivity?.kind, 'outing');
    expect(library.longActivity?.meta['variant'], 'library');

    final street = await freshState(data);
    await performOurHomeAction(street, 'street');
    expect(street.longActivity?.kind, 'outing');
    expect(street.longActivity?.meta['variant'], 'street');

    final mystery = await freshState(data, seed: 1);
    await performOurHomeAction(mystery, 'mystery');
    expect(mystery.longActivity?.meta['variant'], 'mystery');
    expect(mystery.longActivity?.meta['mysteryShowed'], isA<int>());

    final escape = await freshState(data);
    await performOurHomeAction(escape, 'escape');
    expect(escape.longActivity?.meta['variant'], 'escape');

    final outing = await freshState(data);
    await performOurHomeAction(outing, 'outing');
    expect(outing.longActivity?.kind, 'outing');
    // 'library' is deliberately excluded from the random pool — it's
    // explicit-command-only (see OurHomeState._outingVariants).
    expect(
      outing.longActivity?.meta['variant'],
      anyOf('street', 'mystery', 'escape'),
    );
  });

  group('give_money', () {
    test('awards the daily amount once, then refuses same-day', () async {
      final state = await freshState(data);
      final coinsBefore = state.coins;
      final first = await performOurHomeAction(state, 'give_money');
      expect(first.ok, isTrue);
      expect(state.coins, coinsBefore + OurHomeState.dailyGiftAmount);

      final second = await performOurHomeAction(state, 'give_money');
      expect(second.ok, isFalse);
      expect(state.coins, coinsBefore + OurHomeState.dailyGiftAmount);
    });

    test('works even while busy, unlike every other action', () async {
      final state = await freshState(data);
      await performOurHomeAction(state, 'sleep');
      expect(state.longActivity, isNotNull);

      final result = await performOurHomeAction(state, 'give_money');
      expect(result.ok, isTrue);
      // sleep is untouched — give_money doesn't interrupt anything
      expect(state.longActivity?.kind, 'sleep');
    });
  });

  test('busy guard blocks a second away trip until the first resolves', () async {
    final state = await freshState(data);
    await performOurHomeAction(state, 'shop');
    expect(state.longActivity?.kind, 'shop');

    final blocked = await performOurHomeAction(state, 'adventure');
    expect(blocked.ok, isFalse);
    expect(state.longActivity?.kind, 'shop'); // unchanged
  });

  test(
    'come_home while genuinely away rolls fail/angry/grudging instead of always refusing',
    () async {
      var sawRefusal = false;
      var sawSuccess = false;
      for (var i = 0; i < 60; i++) {
        final state = await freshState(data);
        await performOurHomeAction(state, 'shop');
        final moodBefore = state.mood;
        final result = await performOurHomeAction(state, 'come_home');
        if (result.ok) {
          sawSuccess = true;
          expect(state.longActivity, isNull); // angry/grudging both leave
          expect(state.mood, isNot(moodBefore)); // -8 or -2 applied
        } else {
          sawRefusal = true;
          expect(state.longActivity, isNotNull); // fail — still away
        }
      }
      // 30% fail / 70% succeed split — 60 trials makes both outcomes
      // overwhelmingly likely to appear at least once.
      expect(sawRefusal, isTrue);
      expect(sawSuccess, isTrue);
    },
  );

  test('come_home wakes the pet early while sleeping (no mood bonus)', () async {
    final state = await freshState(data);
    await performOurHomeAction(state, 'sleep');
    final moodBefore = state.mood;
    final result = await performOurHomeAction(state, 'come_home');
    expect(result.ok, isTrue);
    expect(state.longActivity, isNull);
    expect(state.mood, moodBefore); // no restore bonus for a cut-short nap
  });

  group('rollInterrupt', () {
    test('always resolves to one of the 3 documented outcomes', () {
      final random = math.Random(9);
      for (var i = 0; i < 500; i++) {
        expect(
          rollInterrupt(random),
          anyOf(
            InterruptOutcome.fail,
            InterruptOutcome.angry,
            InterruptOutcome.grudging,
          ),
        );
      }
    });

    test('roughly a 30/35/35 split over many trials', () {
      final random = math.Random(10);
      final counts = <InterruptOutcome, int>{};
      const trials = 5000;
      for (var i = 0; i < trials; i++) {
        final outcome = rollInterrupt(random);
        counts[outcome] = (counts[outcome] ?? 0) + 1;
      }
      expect(counts[InterruptOutcome.fail]! / trials, closeTo(0.3, 0.05));
      expect(counts[InterruptOutcome.angry]! / trials, closeTo(0.35, 0.05));
      expect(counts[InterruptOutcome.grudging]! / trials, closeTo(0.35, 0.05));
    });
  });

  test('hobbyEmoteKeys matches the demo\'s 16-key HOBBY_KEYS list exactly', () {
    expect(hobbyEmoteKeys, {
      'lm', 'rd', 'gt', 'pt', 'ph', 'wt', 'cf', 'sg',
      'ex', 'gm', 'dc', 'ck', 'ty', 'tv', 'ch', 'jg',
    });
  });

  group('costume commands', () {
    test('matches hat/wizard/newyear/clear and nothing else', () {
      expect(matchOurHomeCostumeCommand('戴上小帽子'), 'hat');
      expect(matchOurHomeCostumeCommand('变成法师'), 'wizard');
      expect(matchOurHomeCostumeCommand('换上新年套装'), 'newyear');
      expect(matchOurHomeCostumeCommand('摘掉帽子'), 'clear');
      expect(matchOurHomeCostumeCommand('今天天气不错'), isNull);
    });
  });

  group('describeOurHomeStatus (first-person voice)', () {
    test('sleep/work/shop/adventure/outing each match the demo\'s exact wording', () async {
      final sleeping = await freshState(data);
      sleeping.startSleep();
      expect(describeOurHomeStatus(sleeping), startsWith('我在睡觉呢，大概'));
      expect(describeOurHomeStatus(sleeping), endsWith('后醒~'));

      final working = await freshState(data);
      final started = working.startWork();
      expect(
        describeOurHomeStatus(working),
        startsWith('我出门做"${started.job.name}"呢，大概'),
      );
      expect(describeOurHomeStatus(working), endsWith('后回家~'));

      final shopping = await freshState(data);
      shopping.startTravel('shop');
      final intent = shopping.longActivity!.meta['shopIntent'];
      expect(
        describeOurHomeStatus(shopping),
        startsWith('我在采购呢，准备买点$intent，大概'),
      );
      expect(describeOurHomeStatus(shopping), endsWith('后回家~'));

      final adventuring = await freshState(data);
      adventuring.startTravel('adventure');
      expect(describeOurHomeStatus(adventuring), startsWith('我在冒险呢，大概'));

      final library = await freshState(data);
      library.startTravel('outing', outingVariant: 'library');
      expect(describeOurHomeStatus(library), startsWith('我在图书馆看书呢，大概'));

      final street = await freshState(data);
      street.startTravel('outing', outingVariant: 'street');
      expect(describeOurHomeStatus(street), startsWith('我在街上逛呢，大概'));

      final mystery = await freshState(data);
      mystery.startTravel('outing', outingVariant: 'mystery');
      expect(describeOurHomeStatus(mystery), startsWith('我在玩剧本杀呢，大概'));

      final escape = await freshState(data);
      escape.startTravel('outing', outingVariant: 'escape');
      expect(describeOurHomeStatus(escape), startsWith('我在密室逃脱呢，大概'));
    });

    test('idle at home with an active hobby emote uses hobbyLabels', () async {
      final home = await freshState(data);
      expect(describeOurHomeStatus(home, activeEmoteKey: 'lm'), '我在听歌呢~');
      expect(describeOurHomeStatus(home, activeEmoteKey: 'ck'), '我在做饭呢~');
    });

    test('genuinely idle with nothing going on', () async {
      final home = await freshState(data);
      expect(describeOurHomeStatus(home), '没干嘛呀，就在家里待着~');
    });
  });

  test('fullLogMaxDays actually prunes old entries on save', () async {
    final state = await freshState(data);
    state.fullLog.add(
      LogEntry(
        time: DateTime.now().subtract(
          Duration(days: OurHomeState.fullLogMaxDays + 1),
        ),
        text: '很久以前的一条记录',
      ),
    );
    state.fullLog.add(LogEntry(time: DateTime.now(), text: '刚刚的记录'));
    await state.save();
    expect(state.fullLog.length, 1);
    expect(state.fullLog.single.text, '刚刚的记录');
  });
}
