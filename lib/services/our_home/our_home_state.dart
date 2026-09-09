import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'economy_data.dart';
import 'our_home_festivals.dart';

/// A pending long (real 10-minute) activity — work/sleep/shop/adventure/
/// outing — persisted so it resolves correctly no matter how long the app
/// was closed. Mirrors the standalone demo's `ourHomeLongActivity`.
class LongActivity {
  LongActivity({required this.kind, required this.meta, required this.endsAt});

  final String kind; // 'work' | 'sleep' | 'shop' | 'adventure' | 'outing'
  final Map<String, Object?> meta;
  final DateTime endsAt;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'meta': meta,
    'endsAt': endsAt.toIso8601String(),
  };

  factory LongActivity.fromJson(Map<String, Object?> json) => LongActivity(
    kind: json['kind'] as String,
    meta: (json['meta'] as Map).cast<String, Object?>(),
    endsAt: DateTime.parse(json['endsAt'] as String),
  );
}

/// Result of a settled shop/adventure/outing trip, work session, or cooked
/// meal — callers (UI, notifications, log) use this to know what to show;
/// this class carries no UI concerns itself.
class SettleResult {
  const SettleResult({
    required this.summary,
    this.coinDelta = 0,
    this.moodDelta = 0,
    this.giftItem,
  });

  final String summary;
  final int coinDelta;
  final int moodDelta;
  final String? giftItem;
}

/// The 3-way outcome of [rollInterrupt] — 30% fail / 35% angry / 35%
/// grudging, ported verbatim from the demo's `rollInterrupt`. Shared by
/// every interruptible-busy case (a hobby-type emote playing, sleep, or —
/// see [OurHomeState.rollAwayRecallInterrupt] — a manual "回家" while
/// genuinely away). Lives here (not in `our_home_actions.dart`, which
/// imports this file) so [OurHomeState] can use it without a circular
/// import; re-exported from `our_home_actions.dart` for every existing
/// caller.
enum InterruptOutcome { fail, angry, grudging }

InterruptOutcome rollInterrupt(math.Random random) {
  final roll = random.nextDouble();
  if (roll < 0.3) return InterruptOutcome.fail;
  if (roll < 0.65) return InterruptOutcome.angry;
  return InterruptOutcome.grudging;
}

/// The user's own 3-axis log taxonomy (superseding an earlier flat-enum
/// draft): every [LogEntry] carries a **消息类型** (is this a plain system
/// narration, or something the pet/user actually "said"?), a **行为类型**
/// (what kind of interaction produced it), and a **行为来源** (who/what is
/// behind it). Displayed as "<消息类型>·<行为类型>·<行为来源>" in the
/// 历史日志 page, e.g. "系统·戳一戳·用户" / "气泡·对话·小螃蟹".
enum LogMessageType { system, bubble }

enum LogActionType { auto, poke, interrupt, chat }

enum LogSource { system, pet, user, model }

String _logMessageTypeLabel(LogMessageType t) =>
    t == LogMessageType.system ? '系统' : '气泡';

String _logActionTypeLabel(LogActionType t) => switch (t) {
  LogActionType.auto => '自动',
  LogActionType.poke => '戳一戳',
  LogActionType.interrupt => '打断',
  LogActionType.chat => '对话',
};

String _logSourceLabel(LogSource s) => switch (s) {
  LogSource.system => '系统',
  LogSource.pet => '小螃蟹',
  LogSource.user => '用户',
  LogSource.model => '模型',
};

/// The "<消息类型>·<行为类型>·<行为来源>" tag shown above a log row in the
/// 历史日志 page.
String logTagLabel(LogEntry entry) =>
    '${_logMessageTypeLabel(entry.messageType)}·'
    '${_logActionTypeLabel(entry.actionType)}·'
    '${_logSourceLabel(entry.source)}';

/// True for a row that should render as a chat bubble in the "跟ta说说话"
/// feed — exactly the rows tagged [LogMessageType.bubble].
bool logRowIsBubble(LogEntry entry) => entry.messageType == LogMessageType.bubble;

/// One entry in the persisted activity log (mirrors the demo's `fullLog`).
class LogEntry {
  const LogEntry({
    required this.time,
    required this.text,
    this.messageType = LogMessageType.system,
    this.actionType = LogActionType.auto,
    this.source = LogSource.system,
  });

  final DateTime time;
  final String text;
  final LogMessageType messageType;
  final LogActionType actionType;
  final LogSource source;

  Map<String, Object?> toJson() => {
    't': time.millisecondsSinceEpoch,
    'text': text,
    'msgType': messageType.name,
    'actionType': actionType.name,
    'source': source.name,
  };

  factory LogEntry.fromJson(Map<String, Object?> json) => LogEntry(
    time: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
    text: json['text'] as String,
    // Missing/unrecognized (e.g. entries saved before this 3-field scheme
    // existed) fall back to a plain system/auto/system row.
    messageType: LogMessageType.values.firstWhere(
      (v) => v.name == json['msgType'],
      orElse: () => LogMessageType.system,
    ),
    actionType: LogActionType.values.firstWhere(
      (v) => v.name == json['actionType'],
      orElse: () => LogActionType.auto,
    ),
    source: LogSource.values.firstWhere(
      (v) => v.name == json['source'],
      orElse: () => LogSource.system,
    ),
  );
}

/// Core "我们的家" game state — coins/mood/backpack/needs/weather/the
/// current long activity — plus every bit of pure economy logic (no
/// widgets, no rendering) ported directly from the standalone HTML demo's
/// scratchpad/our-home-demo.html. Persisted via shared_preferences under a
/// single JSON blob (key: [_prefsKey]).
class OurHomeState {
  OurHomeState({required this.data, required this._prefs, math.Random? random})
    : _random = random ?? math.Random();

  static const _prefsKey = 'our_home_state_v1';
  static const longActivityMs = Duration(minutes: 10);
  static const dailyMealTarget = 2;
  static const dailyBathTarget = 1;
  static const dailyDrinkTarget = 2;
  static const festivalReplayMax = 3;
  static const fullLogMaxDays = 14;

  final OurHomeEconomyData data;
  final SharedPreferences _prefs;
  final math.Random _random;

  int coins = 1000;
  int mood = 70;
  final Map<String, int> inventory = <String, int>{};
  final List<LogEntry> fullLog = <LogEntry>[];

  String _needCountsDay = '';
  int mealsToday = 0;
  int bathsToday = 0;
  int drinksToday = 0;

  String _weatherDay = '';
  String weatherKey = 'sunny';
  double weatherFactor = 1.2;

  String _festivalDay = '';
  int festivalCountToday = 0;

  String? _lastGiftDate;

  /// Walking-crab-only costume, set/cleared via chat — null | 'hat' |
  /// 'wizard' | 'newyear'. Never shown during a real emote pose or while
  /// away, same rule as the demo ("弹吉他、听歌等动作的时候还是原皮就行").
  String? costume;

  /// Editable page title, defaults to "我们的家" like the demo's own default.
  String title = '我们的家';

  /// 'MM-DD', or null if never set.
  String? birthday;

  LongActivity? longActivity;

  static const weatherTypes = <(String key, bool good, double weight)>[
    ('sunny', true, 35),
    ('cloudy', true, 25),
    ('overcast', false, 20),
    ('rain', false, 15),
    ('storm', false, 5),
  ];

  static Future<OurHomeState> load(OurHomeEconomyData data) async {
    final prefs = await SharedPreferences.getInstance();
    final state = OurHomeState(data: data, prefs: prefs);
    state._restore();
    return state;
  }

  String _todayKey([DateTime? at]) {
    final d = at ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _restore() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) {
      _rollWeather();
      return;
    }
    final json = jsonDecode(raw) as Map<String, Object?>;
    coins = (json['coins'] as num?)?.toInt() ?? coins;
    mood = (json['mood'] as num?)?.toInt() ?? mood;
    inventory.addAll(
      ((json['inventory'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
    );
    fullLog.addAll(
      ((json['fullLog'] as List?) ?? const [])
          .map((e) => LogEntry.fromJson((e as Map).cast<String, Object?>())),
    );
    _needCountsDay = json['needCountsDay'] as String? ?? '';
    mealsToday = (json['mealsToday'] as num?)?.toInt() ?? 0;
    bathsToday = (json['bathsToday'] as num?)?.toInt() ?? 0;
    drinksToday = (json['drinksToday'] as num?)?.toInt() ?? 0;
    _weatherDay = json['weatherDay'] as String? ?? '';
    weatherKey = json['weatherKey'] as String? ?? 'sunny';
    weatherFactor = (json['weatherFactor'] as num?)?.toDouble() ?? 1.2;
    _festivalDay = json['festivalDay'] as String? ?? '';
    festivalCountToday = (json['festivalCountToday'] as num?)?.toInt() ?? 0;
    _lastGiftDate = json['lastGiftDate'] as String?;
    costume = json['costume'] as String?;
    title = json['title'] as String? ?? title;
    birthday = json['birthday'] as String?;
    final rawLong = json['longActivity'] as Map?;
    longActivity = rawLong == null
        ? null
        : LongActivity.fromJson(rawLong.cast<String, Object?>());
    _rollWeather(); // no-op if today's weather is already rolled
  }

  /// Drops log entries older than [fullLogMaxDays] — called from [save] so
  /// every one of the many call sites that append to [fullLog] gets this
  /// for free instead of needing to remember it individually.
  void _pruneFullLog() {
    final cutoff = DateTime.now().subtract(Duration(days: fullLogMaxDays));
    fullLog.removeWhere((entry) => entry.time.isBefore(cutoff));
  }

  /// True right after a [save] call failed to actually persist (e.g. the
  /// platform's storage write threw) — cleared again on the next successful
  /// save. `unawaited(home.save())` is called from 20+ sites across the app
  /// specifically so a slow write never blocks the UI, which means nothing
  /// naturally surfaces a failure there — this flag plus the one-time log
  /// row added below are the fallback so a failed save is at least visible
  /// somewhere instead of silently vanishing.
  bool lastSaveFailed = false;

  Future<void> save() async {
    _pruneFullLog();
    final json = <String, Object?>{
      'coins': coins,
      'mood': mood,
      'inventory': inventory,
      'fullLog': fullLog.map((e) => e.toJson()).toList(),
      'needCountsDay': _needCountsDay,
      'mealsToday': mealsToday,
      'bathsToday': bathsToday,
      'drinksToday': drinksToday,
      'weatherDay': _weatherDay,
      'weatherKey': weatherKey,
      'weatherFactor': weatherFactor,
      'festivalDay': _festivalDay,
      'festivalCountToday': festivalCountToday,
      'lastGiftDate': _lastGiftDate,
      'costume': costume,
      'title': title,
      'birthday': birthday,
      'longActivity': longActivity?.toJson(),
    };
    try {
      await _prefs.setString(_prefsKey, jsonEncode(json));
      lastSaveFailed = false;
    } on Object catch (error) {
      // Only log once per failure streak (not on every retry a few seconds
      // later) so a sustained storage outage doesn't spam the log. The row
      // itself only reaches disk once a later save succeeds — best effort,
      // same as everything else in this class.
      if (!lastSaveFailed) {
        fullLog.add(
          LogEntry(time: DateTime.now(), text: '存档失败了，最近的改动可能没保存上（$error）'),
        );
      }
      lastSaveFailed = true;
    }
  }

  // ---------- mood / coins ----------

  /// Weather amplifies the "right-direction" swing only: good weather makes
  /// gains bigger, bad weather makes losses bigger — matches the user's
  /// spec exactly, the "wrong direction" case (e.g. getting angry on a
  /// sunny day) is left alone.
  void changeMood(int delta) {
    final good = weatherTypes.firstWhere((w) => w.$1 == weatherKey).$2;
    if (delta > 0 && good) {
      delta = (delta * weatherFactor).round();
    } else if (delta < 0 && !good) {
      delta = (delta * weatherFactor).round();
    }
    mood = mood.clamp0to100(delta);
  }

  static const _lowMoodLines = <String>[
    '我有点失落，可以哄哄我吗',
    '心情不太好…陪我说说话吧',
    '唔…有点难过，摸摸我可以吗',
  ];
  DateTime? _lastLowMoodPromptAt;

  /// A proactive, unprompted line to show as a pet-voiced bubble when mood
  /// is genuinely low — ported from the demo's `changeMood` hook. Gated to
  /// at most once every 3 real minutes so it doesn't spam on every small
  /// dip; the cooldown is session-only (not persisted), matching the demo's
  /// own in-memory `lastLowMoodPromptAt`. Callers should invoke this right
  /// after [changeMood] and, if non-null, speak it the same way any other
  /// pet reply is spoken — this method only decides *whether* to speak, it
  /// never touches the UI itself.
  String? maybeLowMoodLine() {
    if (mood >= 25) return null;
    final now = DateTime.now();
    if (_lastLowMoodPromptAt != null &&
        now.difference(_lastLowMoodPromptAt!) < const Duration(minutes: 3)) {
      return null;
    }
    _lastLowMoodPromptAt = now;
    return _lowMoodLines[_random.nextInt(_lowMoodLines.length)];
  }

  void changeCoins(int delta) {
    coins = math.max(0, coins + delta);
  }

  /// A once-a-day 500-coin check-in gift, ported from the demo's `/给钱`
  /// slash command. Returns false (no-op) if already claimed today.
  static const dailyGiftAmount = 500;

  bool get canClaimDailyGift => _lastGiftDate != _todayKey();

  bool claimDailyGift() {
    if (!canClaimDailyGift) return false;
    _lastGiftDate = _todayKey();
    changeCoins(dailyGiftAmount);
    return true;
  }

  /// Rolls how many of the other 3 剧本杀 seats show up (0-3) — needs 2+ to
  /// actually play, checked by [settleOuting] before rolling the outcome
  /// table. Rolled once when a mystery-variant outing starts.
  int rollMysteryShowed() => _random.nextInt(4);

  // 'library' is intentionally excluded from the random pool — it's only
  // reachable via the explicit "去图书馆" command. A random/generic outing
  // instead shows 'street' (city street: mall/snack stall/swing), since
  // that's what docs/OUR_HOME_ECONOMY.md's 外出娱乐结果清单 (公园散步/荡
  // 秋千/逛集市/坐摩天轮…) actually reads as, not a literal reading room.
  static const _outingVariants = <String>['street', 'mystery', 'escape'];

  /// Picks a random 外出 variant for a plain, non-forced outing trip.
  String pickRandomOutingVariant() =>
      _outingVariants[_random.nextInt(_outingVariants.length)];

  // ---------- backpack ----------

  bool hasItem(String name) => (inventory[name] ?? 0) > 0;

  void addToInventory(String name, [int qty = 1]) {
    inventory[name] = (inventory[name] ?? 0) + qty;
  }

  bool takeItem(String name) {
    if (!hasItem(name)) return false;
    inventory[name] = inventory[name]! - 1;
    if (inventory[name]! <= 0) inventory.remove(name);
    return true;
  }

  List<ShopItem> itemsByNeed(String need) =>
      data.shopItems.where((it) => it.need == need && hasItem(it.name)).toList();

  /// Consumes 1-2 random items from a need category — never a fixed
  /// exactly-one, per the user's "不需要设置只能消耗一件物品".
  List<String> consumeForNeed(String need, {int maxItems = 2}) {
    final pool = itemsByNeed(need);
    if (pool.isEmpty) return const [];
    final target = math.min(maxItems, math.min(pool.length, _random.nextBool() ? 1 : 2));
    final used = <String>[];
    for (var i = 0; i < target; i++) {
      final avail = itemsByNeed(need);
      if (avail.isEmpty) break;
      final pick = avail[_random.nextInt(avail.length)];
      takeItem(pick.name);
      used.add(pick.name);
    }
    return used;
  }

  // ---------- daily need quotas ----------

  void _rollNeedCountsForToday() {
    final today = _todayKey();
    if (_needCountsDay != today) {
      _needCountsDay = today;
      mealsToday = 0;
      bathsToday = 0;
      drinksToday = 0;
    }
  }

  void bumpNeedCount(String key) {
    _rollNeedCountsForToday();
    switch (key) {
      case 'meal':
        mealsToday++;
      case 'bath':
        bathsToday++;
      case 'drink':
        drinksToday++;
    }
  }

  bool get mealShort {
    _rollNeedCountsForToday();
    return mealsToday < dailyMealTarget;
  }

  bool get bathShort {
    _rollNeedCountsForToday();
    return bathsToday < dailyBathTarget;
  }

  bool get drinkShort {
    _rollNeedCountsForToday();
    return drinksToday < dailyDrinkTarget;
  }

  // ---------- weather ----------

  void _rollWeather() {
    final today = _todayKey();
    if (_weatherDay == today) return;
    _weatherDay = today;
    final chosen = pickWeighted(weatherTypes, (w) => w.$3, _random);
    weatherKey = chosen.$1;
    weatherFactor = 1.2 + _random.nextDouble() * 0.3;
  }

  // ---------- festival auto-detection ----------

  void _rollFestivalDayIfNeeded([DateTime? at]) {
    final today = _todayKey(at);
    if (_festivalDay != today) {
      _festivalDay = today;
      festivalCountToday = 0;
    }
  }

  /// Checks whether today (or [at], for tests) is one of the ~9
  /// real-calendar festivals with a pose, and whether it's still eligible to
  /// play right now — mirrors the demo's `playFestivalIfEligible`: the very
  /// first check of a festival day ([firstOfDay] true) always fires; later
  /// idle-tick rechecks may replay it a few more times that same day (capped
  /// at [festivalReplayMax]). Returns the emote key to play, or null if
  /// nothing's eligible.
  String? checkFestivalReplay({required bool firstOfDay, DateTime? at}) {
    _rollFestivalDayIfNeeded(at);
    final key = todaysAutoFestivalKey(at);
    if (key == null) return null;
    if (firstOfDay) {
      if (festivalCountToday > 0) return null;
      festivalCountToday = 1;
      return key;
    }
    if (festivalCountToday == 0 || festivalCountToday >= festivalReplayMax) {
      return null;
    }
    festivalCountToday++;
    return key;
  }

  // ---------- need-gated activities ----------

  /// Returns the consumed item names on success, or null if nothing was
  /// available (caller shows an "out of stock, go shopping" reply).
  List<String>? tryEat() {
    final used = consumeForNeed('meal', maxItems: 2);
    if (used.isEmpty) return null;
    bumpNeedCount('meal');
    return used;
  }

  List<String>? tryBath() {
    final used = consumeForNeed('bath', maxItems: 3);
    if (used.isEmpty) return null;
    bumpNeedCount('bath');
    return used;
  }

  List<String>? tryDrink() {
    final used = consumeForNeed('drink', maxItems: 2);
    if (used.isEmpty) return null;
    bumpNeedCount('drink');
    return used;
  }

  List<String>? trySnack() {
    final used = consumeForNeed('snack', maxItems: 2);
    if (used.isEmpty) return null;
    return used;
  }

  bool canMakeRecipe(Recipe r) => r.ingredients.every(hasItem);

  bool get canCookAnything => data.recipes.any(canMakeRecipe);

  /// Wants a random recipe; if it can't be made, substitutes a makeable one
  /// at reduced mood. Returns null only if literally no recipe is makeable.
  ({Recipe dish, bool wanted})? tryCook() {
    final wanted = data.recipes[_random.nextInt(data.recipes.length)];
    Recipe? made;
    var gotWanted = false;
    if (canMakeRecipe(wanted)) {
      made = wanted;
      gotWanted = true;
    } else {
      final makeable = data.recipes.where(canMakeRecipe).toList();
      if (makeable.isNotEmpty) made = makeable[_random.nextInt(makeable.length)];
    }
    if (made == null) return null;
    for (final ingredient in made.ingredients) {
      takeItem(ingredient);
    }
    bumpNeedCount('meal'); // cooking satisfies "吃饭" directly
    if (gotWanted) {
      changeMood(made.mood);
    } else {
      changeMood((made.mood * 0.5).round() - 4);
    }
    return (dish: made, wanted: gotWanted);
  }

  // ---------- shopping ----------

  SettleResult settleShop() {
    final bought = <String>[];
    final boughtItems = <ShopItem>[];
    var totalCost = 0;
    var budget = coins;
    while (true) {
      final afford = data.shopItems.where((it) => it.price <= budget).toList();
      if (afford.isEmpty) break;
      final pick = afford[_random.nextInt(afford.length)];
      bought.add(pick.name);
      boughtItems.add(pick);
      budget -= pick.price;
      totalCost += pick.price;
      if (_random.nextDouble() < 0.45) break;
    }
    if (bought.isEmpty) {
      return const SettleResult(summary: '采购回来 · 这次囊中羞涩，什么都没舍得买');
    }
    // Occasionally buys a second helping of something tasty to bring home
    // as a gift — real extra cost, not added to the backpack (it's given
    // away, not kept).
    String? giftItem;
    final foodBought = boughtItems.where((it) => it.cat == '吃的').toList();
    if (foodBought.isNotEmpty && _random.nextDouble() < 0.25) {
      final pick2 = foodBought[_random.nextInt(foodBought.length)];
      if (coins - totalCost >= pick2.price) {
        totalCost += pick2.price;
        giftItem = pick2.name;
      }
    }
    for (final it in boughtItems) {
      addToInventory(it.name);
    }
    changeCoins(-totalCost);
    final moodGain = 4 + (giftItem != null ? 2 : 0);
    changeMood(moodGain);
    final joined = bought.join('、');
    if (giftItem != null) {
      return SettleResult(
        summary: '采购回来 · 买了$joined，多买了一份$giftItem要送你 · -$totalCost💰',
        coinDelta: -totalCost,
        moodDelta: moodGain,
        giftItem: giftItem,
      );
    }
    return SettleResult(
      summary: '采购回来 · 买了$joined · -$totalCost💰',
      coinDelta: -totalCost,
      moodDelta: moodGain,
    );
  }

  SettleResult settleAdventure() {
    final outcome = pickOutcome(data.adventureOutcomes, _random);
    final coin = outcome.coin.roll(_random);
    if (coin != 0) changeCoins(coin);
    changeMood(outcome.mood);
    final coinText = coin != 0 ? ' · ${coin > 0 ? '+' : ''}$coin💰' : '';
    return SettleResult(
      summary: '冒险回来 · ${outcome.result}$coinText',
      coinDelta: coin,
      moodDelta: outcome.mood,
    );
  }

  /// [mysteryShowed] is 0-3 other players (of 4 seats) rolled when the trip
  /// started — needs 2+ to actually play; falling short is a gate before
  /// the outcome table, not one of its 30 rows.
  SettleResult settleOuting(String variant, int mysteryShowed) {
    if (variant == 'mystery') {
      if (mysteryShowed < 2) {
        return const SettleResult(
          summary: '剧本杀回来 · 玩家人数不够，剧本杀玩不成了',
          moodDelta: -8,
        );
      }
      final outcome = pickOutcome(data.mysteryOutcomes, _random);
      final coin = outcome.coin.roll(_random);
      if (coin != 0) changeCoins(coin);
      changeMood(outcome.mood);
      return SettleResult(
        summary: '剧本杀回来 · ${outcome.result}${coin != 0 ? ' · $coin💰' : ''}',
        coinDelta: coin,
        moodDelta: outcome.mood,
      );
    }
    if (variant == 'escape') {
      final outcome = pickOutcome(data.escapeOutcomes, _random);
      final coin = outcome.coin.roll(_random);
      if (coin != 0) changeCoins(coin);
      changeMood(outcome.mood);
      return SettleResult(
        summary: '密室逃脱回来 · ${outcome.result}${coin != 0 ? ' · $coin💰' : ''}',
        coinDelta: coin,
        moodDelta: outcome.mood,
      );
    }
    // 'street' (the random/generic pick) and 'library' (explicit "去图书馆")
    // both settle against the same 外出娱乐结果清单 — there's no separate
    // dedicated table for a literal library trip in the doc.
    final outcome = pickOutcome(data.outingOutcomes, _random);
    final coin = outcome.coin.roll(_random);
    if (coin != 0) changeCoins(coin);
    changeMood(outcome.mood);
    return SettleResult(
      summary: '外出回来 · ${outcome.result}${coin != 0 ? ' · $coin💰' : ''}',
      coinDelta: coin,
      moodDelta: outcome.mood,
    );
  }

  SettleResult settleSleepWake() {
    const sleepMoodBonus = 10;
    changeMood(sleepMoodBonus);
    return const SettleResult(summary: '睡醒了，伸了个懒腰', moodDelta: sleepMoodBonus);
  }

  /// Rolls what happens when someone tries to manually call the pet home
  /// while it's genuinely away (shop/adventure/outing) — the demo itself
  /// let a manual recall always succeed instantly with no roll at all, but
  /// per an explicit product decision this now goes through the same
  /// fail/angry/grudging shape used everywhere else an activity can be
  /// interrupted (a hobby emote, sleep), for consistency.
  InterruptOutcome rollAwayRecallInterrupt() => rollInterrupt(_random);

  /// Ends the current away trip immediately regardless of its real
  /// [LongActivity.endsAt] and settles it through the normal shop/
  /// adventure/outing outcome tables — used by a successful manual recall
  /// (angry/grudging outcomes of [rollAwayRecallInterrupt]). Returns null
  /// if nothing was actually away (e.g. it already finished on its own in
  /// the same moment this was called).
  SettleResult? forceSettleAway() {
    final la = longActivity;
    if (la == null || la.kind == 'sleep' || la.kind == 'work') return null;
    longActivity = null;
    return switch (la.kind) {
      'shop' => settleShop(),
      'adventure' => settleAdventure(),
      'outing' => settleOuting(
        la.meta['variant'] as String? ?? 'street',
        (la.meta['mysteryShowed'] as num?)?.toInt() ?? 0,
      ),
      _ => null,
    };
  }

  // ---------- work ----------

  /// 1hr=1x, 2hr=2×1.2, 5hr=5×1.5 — 0.2/hr from 1→2, 0.1/hr from 2hr on.
  static double workDurationMult(int hours) {
    if (hours <= 1) return 1;
    return 1.2 + 0.1 * (hours - 2);
  }

  static const _workHourWeights = <(int hours, double weight)>[
    (1, 30),
    (2, 28),
    (3, 20),
    (4, 12),
    (5, 7),
    (6, 3),
  ];

  int pickWorkHours() => pickWeighted(_workHourWeights, (w) => w.$2, _random).$1;

  /// "hoursPlanned" only drives the mood-scaling formula internally — the
  /// real session is always exactly [longActivityMs] (10 min) regardless,
  /// so this must never be shown to the user as "X 小时" (that was a real
  /// reported inconsistency in the original demo). Everything user-facing
  /// uses real minutes out of the 10-minute session instead.
  static String workIntensityLabel(int hoursPlanned) {
    if (hoursPlanned <= 1) return '随便做一下';
    if (hoursPlanned == 2) return '做一会儿';
    if (hoursPlanned == 3) return '认真干一阵';
    if (hoursPlanned == 4) return '干得比较久';
    if (hoursPlanned == 5) return '连轴转';
    return '拼了命干';
  }

  static int workMinutesDone(int hoursDone, int hoursPlanned) =>
      math.max(1, (hoursDone / hoursPlanned * 10).round());

  /// Settles pay/mood for one hour boundary, matching the doc's cumulative
  /// formula exactly (computed as a cumulative difference so rounding never
  /// drifts hour to hour).
  void _settleWorkHour(int jobMood, double rate, int hour) {
    final cumNow = jobMood * hour * workDurationMult(hour);
    final cumPrev = jobMood * (hour - 1) * workDurationMult(hour - 1);
    changeCoins(rate.round());
    changeMood((cumNow - cumPrev).round());
  }

  String? _workJobName;
  int? _workJobMood;
  double? _workRate;
  int? _workHoursPlanned;
  int _workHoursPaid = 0;
  DateTime? _workStartedAt;

  bool get isWorking => _workJobName != null;
  String? get currentWorkJobName => _workJobName;
  int? get workHoursPlanned => _workHoursPlanned;
  int get workHoursPaid => _workHoursPaid;

  /// Starts a new real job — always takes exactly [longActivityMs] (10 real
  /// minutes) of wall-clock time regardless of hoursPlanned; [tickWork]
  /// spreads the planned hours evenly across that real window.
  ({WorkJob job, int hoursPlanned}) startWork() {
    final job = data.workJobs[_random.nextInt(data.workJobs.length)];
    final rate = job.inc.min + _random.nextDouble() * (job.inc.max - job.inc.min);
    final hoursPlanned = pickWorkHours();
    final startedAt = DateTime.now();
    _workJobName = job.name;
    _workJobMood = job.mood;
    _workRate = rate;
    _workHoursPlanned = hoursPlanned;
    _workHoursPaid = 0;
    _workStartedAt = startedAt;
    longActivity = LongActivity(
      kind: 'work',
      meta: {
        'jobName': job.name,
        'jobMood': job.mood,
        'rate': rate,
        'hoursPlanned': hoursPlanned,
        'hoursPaid': 0,
        'startedAt': startedAt.toIso8601String(),
      },
      endsAt: startedAt.add(longActivityMs),
    );
    return (job: job, hoursPlanned: hoursPlanned);
  }

  void _persistWorkProgress() {
    final la = longActivity;
    if (la == null || la.kind != 'work') return;
    longActivity = LongActivity(
      kind: 'work',
      meta: {...la.meta, 'hoursPaid': _workHoursPaid},
      endsAt: la.endsAt,
    );
  }

  void _finishWork() {
    _workJobName = null;
    _workJobMood = null;
    _workRate = null;
    _workHoursPlanned = null;
    _workHoursPaid = 0;
    _workStartedAt = null;
    longActivity = null;
  }

  /// Advances the current work session against the real clock. Call this
  /// periodically (e.g. once a second) while [isWorking] is true. Returns a
  /// settlement summary once the session ends (mood-stopped or completed
  /// naturally), or null while it's still running / nothing is happening.
  String? tickWork([DateTime? now]) {
    if (_workJobName == null || _workHoursPlanned == null || _workStartedAt == null) {
      return null;
    }
    final effectiveNow = now ?? DateTime.now();
    final msPerHour = longActivityMs.inMilliseconds / _workHoursPlanned!;
    final elapsedMs = effectiveNow.difference(_workStartedAt!).inMilliseconds;
    final hoursNow = math.min(_workHoursPlanned!, (elapsedMs / msPerHour).floor());
    final jobName = _workJobName!;
    final jobMood = _workJobMood!;
    final rate = _workRate!;
    final hoursPlanned = _workHoursPlanned!;
    while (_workHoursPaid < hoursNow) {
      _workHoursPaid++;
      _settleWorkHour(jobMood, rate, _workHoursPaid);
      _persistWorkProgress();
      if (mood < 20) {
        final minutes = workMinutesDone(_workHoursPaid, hoursPlanned);
        _finishWork();
        return '做"$jobName"做了 $minutes 分钟，心情撑不住了，先歇一歇';
      }
    }
    if (_workHoursPaid >= hoursPlanned) {
      _finishWork();
      return '结束了"$jobName"，忙了这10分钟，回客厅歇一会儿';
    }
    return null;
  }

  /// Manual interrupt (e.g. user says "回家" while a job is in progress) —
  /// pay/mood for hours already completed were already applied
  /// incrementally by [tickWork], so this just stops the clock; satisfies
  /// "取整工作时长获得对应的报酬" for free.
  String? interruptWork() {
    if (_workJobName == null) return null;
    final jobName = _workJobName!;
    final doneHours = _workHoursPaid;
    final hoursPlanned = _workHoursPlanned!;
    _finishWork();
    if (doneHours <= 0) {
      return '把ta从"$jobName"里叫了回来，还不到1分钟，这次没有收入';
    }
    final minutes = workMinutesDone(doneHours, hoursPlanned);
    return '把ta从"$jobName"里叫了回来，按已经忙的 $minutes 分钟结了钱';
  }

  // ---------- sleep / travel (long-activity starters) ----------

  void startSleep() {
    longActivity = LongActivity(
      kind: 'sleep',
      meta: const {},
      endsAt: DateTime.now().add(longActivityMs),
    );
  }

  /// Wakes the pet up early with no mood-restore bonus — a cut-short nap
  /// isn't a full one. Used by the explicit "起床/醒醒/叫醒" chat command and
  /// by the angry/grudging outcomes of an interrupt roll during sleep; a
  /// 'fail' roll should never call this (the demo leaves the nap untouched).
  void interruptSleep() {
    longActivity = null;
  }

  static const _shopIntentCategories = <String>['日用品', '吃的', '衣服', '其他'];

  /// [kind] is 'shop' | 'adventure' | 'outing'; for 'outing', pass
  /// [outingVariant] ('street' | 'library' | 'mystery' | 'escape') and, for mystery,
  /// [mysteryShowed] (0-3 other players rolled at trip start). For 'shop', a
  /// cosmetic "what are you shopping for" category is rolled automatically
  /// (never constrains the real purchase RNG — flavor only, matches the
  /// demo's own `pet.shopIntent`).
  void startTravel(
    String kind, {
    String? outingVariant,
    int? mysteryShowed,
  }) {
    final shopIntent = kind == 'shop'
        ? _shopIntentCategories[_random.nextInt(_shopIntentCategories.length)]
        : null;
    longActivity = LongActivity(
      kind: kind,
      meta: {
        'variant': ?outingVariant,
        'mysteryShowed': ?mysteryShowed,
        'shopIntent': ?shopIntent,
      },
      endsAt: DateTime.now().add(longActivityMs),
    );
  }

  // ---------- resume-on-launch ----------

  /// Call once after [load] (e.g. right when the "我们的家" page opens) —
  /// if a long activity was pending and its real 10 minutes already
  /// elapsed (no matter how long the app was actually closed), resolves it
  /// immediately and returns the settlement; if it's still running,
  /// restores the in-progress work session fields so [tickWork] can keep
  /// going, and returns null. Also returns null if nothing was pending.
  SettleResult? resolvePendingLongActivity([DateTime? now]) {
    final la = longActivity;
    if (la == null) return null;
    final effectiveNow = now ?? DateTime.now();
    if (la.endsAt.isAfter(effectiveNow)) {
      if (la.kind == 'work') {
        _workJobName = la.meta['jobName'] as String;
        _workJobMood = (la.meta['jobMood'] as num).toInt();
        _workRate = (la.meta['rate'] as num).toDouble();
        _workHoursPlanned = (la.meta['hoursPlanned'] as num).toInt();
        _workHoursPaid = (la.meta['hoursPaid'] as num?)?.toInt() ?? 0;
        _workStartedAt = DateTime.parse(la.meta['startedAt'] as String);
      }
      return null;
    }
    longActivity = null;
    switch (la.kind) {
      case 'work':
        final jobName = la.meta['jobName'] as String;
        final jobMood = (la.meta['jobMood'] as num).toInt();
        final rate = (la.meta['rate'] as num).toDouble();
        final hoursPlanned = (la.meta['hoursPlanned'] as num).toInt();
        var hoursPaid = (la.meta['hoursPaid'] as num?)?.toInt() ?? 0;
        while (hoursPaid < hoursPlanned) {
          hoursPaid++;
          _settleWorkHour(jobMood, rate, hoursPaid);
          if (mood < 20) break;
        }
        final full = hoursPaid >= hoursPlanned;
        return SettleResult(
          summary: full
              ? '趁你不在的时候，"$jobName"已经忙完这10分钟了'
              : '趁你不在的时候，"$jobName"做了 ${workMinutesDone(hoursPaid, hoursPlanned)} 分钟，心情撑不住提前歇了',
        );
      case 'sleep':
        return settleSleepWake();
      case 'shop':
        return settleShop();
      case 'adventure':
        return settleAdventure();
      case 'outing':
        return settleOuting(
          la.meta['variant'] as String? ?? 'library',
          (la.meta['mysteryShowed'] as num?)?.toInt() ?? 0,
        );
      default:
        return null;
    }
  }
}

extension on int {
  int clamp0to100(int delta) => (this + delta).clamp(0, 100);
}
