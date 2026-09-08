import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// A coin amount that's either a fixed value or a random range — mirrors
/// docs/OUR_HOME_ECONOMY.md's "40~140（随机）" style entries.
class MoneyRange {
  const MoneyRange.fixed(int value) : min = value, max = value;
  const MoneyRange.range(this.min, this.max);

  final int min;
  final int max;

  bool get isFixed => min == max;

  factory MoneyRange.fromJson(Object? json) {
    if (json is Map) {
      return MoneyRange.range((json['min'] as num).toInt(), (json['max'] as num).toInt());
    }
    return MoneyRange.fixed((json as num).toInt());
  }

  int roll(math.Random random) {
    if (isFixed) return min;
    return min + random.nextInt(max - min + 1);
  }
}

class ShopItem {
  const ShopItem({
    required this.cat,
    required this.name,
    required this.price,
    required this.mood,
    this.need,
  });

  final String cat;
  final String name;
  final int price;
  final int mood;

  /// Which daily need this satisfies when consumed from the backpack:
  /// 'bath' | 'meal' | 'drink' | 'snack' | 'ingredient' | null (decorative
  /// items that aren't consumed by any daily activity).
  final String? need;

  factory ShopItem.fromJson(Map<String, Object?> json) => ShopItem(
    cat: json['cat'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toInt(),
    mood: (json['mood'] as num).toInt(),
    need: json['need'] as String?,
  );
}

class WorkJob {
  const WorkJob({required this.name, required this.inc, required this.mood});

  final String name;
  final MoneyRange inc; // per-hour rate range
  final int mood; // base per-hour mood delta before the duration multiplier

  factory WorkJob.fromJson(Map<String, Object?> json) => WorkJob(
    name: json['name'] as String,
    inc: MoneyRange.fromJson(json['inc']),
    mood: (json['mood'] as num).toInt(),
  );
}

class Recipe {
  const Recipe({
    required this.name,
    required this.ingredients,
    required this.mood,
  });

  final String name;
  final List<String> ingredients;
  final int mood; // mood when this is the recipe actually wanted

  factory Recipe.fromJson(Map<String, Object?> json) => Recipe(
    name: json['name'] as String,
    ingredients: (json['ingredients'] as List).cast<String>(),
    mood: (json['mood'] as num).toInt(),
  );
}

/// One row of a probability-weighted outcome table (adventure/outing/
/// mystery/escape) — `w` is the doc's raw percentage weight, rows don't
/// need to sum to exactly 100 for weighted selection to work correctly.
class Outcome {
  const Outcome({
    required this.weight,
    required this.result,
    required this.coin,
    required this.mood,
  });

  final double weight;
  final String result;
  final MoneyRange coin;
  final int mood;

  factory Outcome.fromJson(Map<String, Object?> json) => Outcome(
    weight: (json['w'] as num).toDouble(),
    result: json['result'] as String,
    coin: MoneyRange.fromJson(json['coin']),
    mood: (json['mood'] as num).toInt(),
  );
}

/// Everything loaded once from assets/our_home/economy.json — regenerate
/// that file with tools/gen_our_home_economy_json.py after editing
/// docs/OUR_HOME_ECONOMY.md, don't hand-edit either the JSON or this class.
class OurHomeEconomyData {
  const OurHomeEconomyData({
    required this.shopItems,
    required this.recipes,
    required this.workJobs,
    required this.adventureOutcomes,
    required this.outingOutcomes,
    required this.mysteryOutcomes,
    required this.escapeOutcomes,
  });

  final List<ShopItem> shopItems;
  final List<Recipe> recipes;
  final List<WorkJob> workJobs;
  final List<Outcome> adventureOutcomes;
  final List<Outcome> outingOutcomes;
  final List<Outcome> mysteryOutcomes;
  final List<Outcome> escapeOutcomes;

  static Future<OurHomeEconomyData> load({
    String assetPath = 'assets/our_home/economy.json',
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    return OurHomeEconomyData.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
  }

  factory OurHomeEconomyData.fromJson(Map<String, Object?> json) {
    List<T> listOf<T>(String key, T Function(Map<String, Object?>) fromJson) =>
        (json[key] as List)
            .map((e) => fromJson(e as Map<String, Object?>))
            .toList(growable: false);
    return OurHomeEconomyData(
      shopItems: listOf('shopItems', ShopItem.fromJson),
      recipes: listOf('recipes', Recipe.fromJson),
      workJobs: listOf('workJobs', WorkJob.fromJson),
      adventureOutcomes: listOf('adventureOutcomes', Outcome.fromJson),
      outingOutcomes: listOf('outingOutcomes', Outcome.fromJson),
      mysteryOutcomes: listOf('mysteryOutcomes', Outcome.fromJson),
      escapeOutcomes: listOf('escapeOutcomes', Outcome.fromJson),
    );
  }

  List<ShopItem> itemsByNeed(String need) =>
      shopItems.where((it) => it.need == need).toList(growable: false);
}

/// Picks one entry from a list of {weight} items, weighted by `weight`.
T pickWeighted<T>(
  List<T> options,
  double Function(T) weightOf,
  math.Random random,
) {
  final total = options.fold<double>(0, (sum, o) => sum + weightOf(o));
  var r = random.nextDouble() * total;
  for (final option in options) {
    r -= weightOf(option);
    if (r <= 0) return option;
  }
  return options.last;
}

Outcome pickOutcome(List<Outcome> table, math.Random random) =>
    pickWeighted(table, (o) => o.weight, random);
