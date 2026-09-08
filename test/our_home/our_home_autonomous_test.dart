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

const _validChoices = {
  'wander',
  'hobby',
  'sleep',
  'work',
  'meal',
  'bath',
  'drink',
  'snack',
  'shop',
  'adventure',
  'outing',
};

void main() {
  final data = loadRealData();

  test('always returns one of the documented outcomes, never an "out" placeholder', () async {
    final state = await freshState(data, seed: 1);
    final random = math.Random(2);
    for (var i = 0; i < 500; i++) {
      final choice = pickAutonomousChoice(state, 0, random);
      expect(_validChoices, contains(choice));
      expect(choice, isNot('out')); // must already be resolved to a concrete kind
    }
  });

  test('a well-stocked, happy, rich pet is never pushed toward sleep/work/shopping-out-of-need', () async {
    final state = await freshState(data);
    state.mood = 90;
    state.coins = 5000;
    final random = math.Random(3);
    var sleepCount = 0;
    for (var i = 0; i < 300; i++) {
      if (pickAutonomousChoice(state, 0, random) == 'sleep') sleepCount++;
    }
    // sleep's weight is only 4 when mood>=30 (vs 26 when mood<30) — should
    // be rare, not the dominant outcome.
    expect(sleepCount, lessThan(60));
  });

  test('low mood makes sleep and hobby much more likely than a happy pet', () async {
    final happy = await freshState(data);
    happy.mood = 90;
    final sad = await freshState(data);
    sad.mood = 10;
    final random = math.Random(4);
    int countSleep(OurHomeState s) {
      var n = 0;
      for (var i = 0; i < 400; i++) {
        if (pickAutonomousChoice(s, 0, random) == 'sleep') n++;
      }
      return n;
    }

    expect(countSleep(sad), greaterThan(countSleep(happy)));
  });

  test('low coins makes work much more likely than a rich pet', () async {
    final rich = await freshState(data);
    rich.coins = 5000;
    final poor = await freshState(data);
    poor.coins = 50;
    final random = math.Random(5);
    int countWork(OurHomeState s) {
      var n = 0;
      for (var i = 0; i < 400; i++) {
        if (pickAutonomousChoice(s, 0, random) == 'work') n++;
      }
      return n;
    }

    expect(countWork(poor), greaterThan(countWork(rich)));
  });

  test('a work streak of 2+ suppresses further work relative to no streak', () async {
    final state = await freshState(data);
    state.coins = 50; // low coins alone would otherwise push work up a lot
    final random = math.Random(6);
    int countWork(int streak) {
      var n = 0;
      for (var i = 0; i < 400; i++) {
        if (pickAutonomousChoice(state, streak, random) == 'work') n++;
      }
      return n;
    }

    expect(countWork(0), greaterThan(countWork(3)));
  });

  test('preferCookingForMeal always cooks when nothing is ready-to-eat but a recipe is makeable', () async {
    final state = await freshState(data);
    for (final ingredient in ['番茄', '一盒鸡蛋', '土豆']) {
      state.addToInventory(ingredient, 999);
    }
    // No plain "meal" item in stock (only ingredients), so cooking is the
    // only way to satisfy the need — must always prefer it.
    expect(state.itemsByNeed('meal'), isEmpty);
    expect(state.canCookAnything, isTrue);
    expect(preferCookingForMeal(state, math.Random(7)), isTrue);
  });
}
