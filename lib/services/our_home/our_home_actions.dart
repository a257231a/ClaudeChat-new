import 'dart:math' as math;

import 'economy_data.dart';
import 'our_home_state.dart';

export 'our_home_state.dart' show InterruptOutcome, rollInterrupt;

/// Result of a single pet action (work/sleep/shop/eat/...), shared between
/// the "我们的家" page's own chat box and the main-chat `our_home_pet_action`
/// tool so both call paths produce identical behavior and wording.
class OurHomeActionResult {
  const OurHomeActionResult({required this.summary, this.ok = true});

  final String summary;
  final bool ok;
}

const _actionNames = <String, String>{
  'work': '工作',
  'sleep': '睡觉',
  'shop': '采购',
  'adventure': '冒险',
  'library': '去图书馆',
  'street': '逛街',
  'mystery': '剧本杀',
  'escape': '密室逃脱',
  'outing': '外出',
  'eat': '吃饭',
  'bath': '洗澡',
  'drink': '喝水',
  'snack': '吃零食',
  'cook': '做饭',
  'come_home': '回家',
  'give_money': '给钱',
};

/// The list of actions `our_home_pet_action` and the page's chat box both
/// accept. `library`/`street`/`mystery`/`escape` force that specific 外出
/// variant; plain `outing` (only reachable via the generic "旅行/出去玩" chat
/// phrasing, not a quick-tap chip) picks one at random from `street`/
/// `mystery`/`escape` (never `library`, which is explicit-only), matching
/// the demo's own forced-vs-random distinction.
const ourHomeActionKeys = <String>[
  'work',
  'sleep',
  'shop',
  'adventure',
  'library',
  'street',
  'mystery',
  'escape',
  'outing',
  'eat',
  'bath',
  'drink',
  'snack',
  'cook',
  'come_home',
  'give_money',
];

/// Performs one pet action against [home], mirroring the standalone demo's
/// `craftReply` dispatch — busy-guarded the same way (a long activity or an
/// active work session blocks every action except `come_home`, which
/// interrupts work early or is a no-op while away/asleep since those can
/// only be waited out, and `give_money`, which is a check-in gift rather
/// than an activity so it always goes through).
Future<OurHomeActionResult> performOurHomeAction(
  OurHomeState home,
  String action,
) async {
  final busy = home.isWorking || home.longActivity != null;
  if (busy && action == 'give_money') {
    return home.claimDailyGift()
        ? OurHomeActionResult(summary: '哇,谢谢你给我${OurHomeState.dailyGiftAmount}金币!')
        : const OurHomeActionResult(summary: '今天已经给过钱了哦', ok: false);
  }
  if (busy) {
    if (action == 'come_home') {
      if (home.longActivity?.kind == 'sleep') {
        home.interruptSleep();
        return const OurHomeActionResult(summary: '被叫醒了，没睡够，可能还有点困');
      }
      // Genuinely away (shop/adventure/outing) OR actually working — both
      // go through the same fail/angry/grudging roll as any other
      // interrupted activity instead of unconditionally succeeding/
      // refusing (see [OurHomeState.rollAwayRecallInterrupt]). This is the
      // headless/model-driven path (`our_home_pet_action`); the 我们的家
      // page's own chat/quick-tap path does its own roll instead so it can
      // sequence an angry animation before the walk-back (see
      // `_recallFromAway` in app.dart).
      switch (home.rollAwayRecallInterrupt()) {
        case InterruptOutcome.fail:
          return const OurHomeActionResult(
            summary: '还不想回来，想再多待一会儿',
            ok: false,
          );
        case InterruptOutcome.angry:
          home.changeMood(-8);
          final summary = home.isWorking
              ? home.interruptWork()
              : home.forceSettleAway()?.summary;
          return OurHomeActionResult(
            summary: '被强行叫回来，生气了${summary != null ? ' · $summary' : ''}',
          );
        case InterruptOutcome.grudging:
          home.changeMood(-2);
          final summary = home.isWorking
              ? home.interruptWork()
              : home.forceSettleAway()?.summary;
          return OurHomeActionResult(summary: summary ?? '回来了');
      }
    }
    return OurHomeActionResult(
      summary: '现在正忙着${describeOurHomeStatus(home)}，先等这次的事情结束吧',
      ok: false,
    );
  }
  switch (action) {
    case 'work':
      final started = home.startWork();
      return OurHomeActionResult(
        summary:
            '出门去做"${started.job.name}"了，${OurHomeState.workIntensityLabel(started.hoursPlanned)}',
      );
    case 'sleep':
      home.startSleep();
      return const OurHomeActionResult(summary: '睡觉了，别吵ta');
    case 'shop':
      home.startTravel('shop');
      return const OurHomeActionResult(summary: '出门采购去了');
    case 'adventure':
      home.startTravel('adventure');
      return const OurHomeActionResult(summary: '装备走起,出发冒险!');
    case 'library':
    case 'street':
    case 'mystery':
    case 'escape':
      home.startTravel(
        'outing',
        outingVariant: action,
        mysteryShowed: action == 'mystery' ? home.rollMysteryShowed() : null,
      );
      return OurHomeActionResult(
        summary: switch (action) {
          'library' => '好呀,去图书馆找本书看',
          'street' => '好呀,去街上逛逛',
          'mystery' => '好呀,去玩一局剧本杀',
          _ => '好呀,壮着胆子去密室逃脱',
        },
      );
    case 'outing':
      final variant = home.pickRandomOutingVariant();
      home.startTravel(
        'outing',
        outingVariant: variant,
        mysteryShowed: variant == 'mystery' ? home.rollMysteryShowed() : null,
      );
      return const OurHomeActionResult(summary: '好呀,我们出发吧!');
    case 'give_money':
      return home.claimDailyGift()
          ? OurHomeActionResult(summary: '哇,谢谢你给我${OurHomeState.dailyGiftAmount}金币!')
          : const OurHomeActionResult(summary: '今天已经给过钱了哦', ok: false);
    case 'eat':
      final used = home.tryEat();
      return used == null
          ? const OurHomeActionResult(summary: '家里没吃的了，得先去采购', ok: false)
          : OurHomeActionResult(summary: '吃了${used.join("、")}');
    case 'bath':
      final used = home.tryBath();
      return used == null
          ? const OurHomeActionResult(summary: '家里没有洗澡用的东西了', ok: false)
          : OurHomeActionResult(summary: '洗了个澡，用了${used.join("、")}');
    case 'drink':
      final used = home.tryDrink();
      return used == null
          ? const OurHomeActionResult(summary: '家里没有喝的了', ok: false)
          : OurHomeActionResult(summary: '喝了点${used.join("、")}');
    case 'snack':
      final used = home.trySnack();
      return used == null
          ? const OurHomeActionResult(summary: '家里没有零食了', ok: false)
          : OurHomeActionResult(summary: '吃了点${used.join("、")}当零食');
    case 'cook':
      final cooked = home.tryCook();
      return cooked == null
          ? const OurHomeActionResult(summary: '食材不够，做不了菜', ok: false)
          : OurHomeActionResult(
              summary: cooked.wanted
                  ? '做了想吃的${cooked.dish.name}'
                  : '食材不够，换着做了${cooked.dish.name}',
            );
    case 'come_home':
      return const OurHomeActionResult(summary: '本来就在家', ok: false);
    default:
      final label = _actionNames[action] ?? action;
      return OurHomeActionResult(summary: '不知道该怎么"$label"', ok: false);
  }
}

/// Matches a costume chat command — 'hat' | 'wizard' | 'newyear' to wear one,
/// or 'clear' to take it off. Not busy-guarded (matches the demo: costumes
/// are cosmetic, no reason to block them while working/sleeping/away — they
/// just won't visibly show until the pet is back to the plain idle crab).
/// Returns null if nothing matched.
String? matchOurHomeCostumeCommand(String text) {
  if (RegExp('戴.*帽子|小帽子').hasMatch(text)) return 'hat';
  if (RegExp('法师').hasMatch(text)) return 'wizard';
  if (RegExp('新年套装|新年装扮').hasMatch(text)) return 'newyear';
  if (RegExp('摘.*帽子|摘装扮|素颜|换回原样').hasMatch(text)) return 'clear';
  return null;
}

const costumeReplies = <String, String>{
  'hat': '这顶帽子还挺合适~',
  'wizard': '嗖!魔法发动',
  'newyear': '恭喜发财~',
  'clear': '轻松多啦',
};

/// Ported verbatim from the demo's `HOBBY_LABELS` — used only by
/// [describeOurHomeStatus]'s "currently mid-hobby, nothing else going on"
/// branch (a superset of [hobbyEmoteKeys]: also covers the momentary
/// eat/bath/cook/snack/watch-tv poses, which the demo's status line can
/// describe too even though they're not "interruptible hobbies").
const hobbyLabels = <String, String>{
  'lm': '听歌',
  'rd': '看书',
  'gt': '弹吉他',
  'pt': '画画',
  'ph': '拍照',
  'wt': '浇花',
  'cf': '喝点东西',
  'sg': '唱歌',
  'ex': '锻炼',
  'gm': '打游戏',
  'dc': '跳舞',
  'et': '吃饭',
  'sh': '洗澡',
  'ck': '做饭',
  'ty': '玩玩具',
  'tv': '看电视',
  'ch': '吃零食',
  'jg': '玩杂耍',
};

String _remainingMinutesText(DateTime endsAt) {
  final ms = endsAt.difference(DateTime.now()).inMilliseconds;
  final minutes = (ms / 60000).ceil();
  return minutes <= 0 ? '马上' : '$minutes分钟左右';
}

/// A first-person status reply — what the pet itself would say if you asked
/// "你在干嘛呀", ported verbatim (wording included, not just the logic) from
/// the demo's `describeCurrentActivity`. Shared between the page's chat box,
/// the HUD's busy-state line, and both our_home tools' JSON replies.
/// [activeEmoteKey] is the page's currently-playing one-off cosmetic emote,
/// if any — callers outside the page (e.g. the main-chat tools) have no
/// visibility into that and can omit it.
String describeOurHomeStatus(OurHomeState home, {String? activeEmoteKey}) {
  final activity = home.longActivity;
  if (activity != null) {
    final remain = _remainingMinutesText(activity.endsAt);
    if (activity.kind == 'sleep') return '我在睡觉呢，大概 $remain 后醒~';
    if (activity.kind == 'work') {
      // Explicitly says "出门"/"回家" now — work happens at a dedicated
      // office scene, not at a desk inside the home room, and a model
      // reading only this text (e.g. via read_our_home_status) was
      // otherwise assuming it never left home.
      return '我出门做"${home.currentWorkJobName}"呢，大概 $remain 后回家~';
    }
    if (activity.kind == 'shop') {
      final intent = activity.meta['shopIntent'] as String? ?? '东西';
      return '我在采购呢，准备买点$intent，大概 $remain 后回家~';
    }
    if (activity.kind == 'adventure') return '我在冒险呢，大概 $remain 后回家~';
    if (activity.kind == 'outing') {
      final variant = activity.meta['variant'] as String?;
      if (variant == 'mystery') return '我在玩剧本杀呢，大概 $remain 后回家~';
      if (variant == 'escape') return '我在密室逃脱呢，大概 $remain 后回家~';
      if (variant == 'street') return '我在街上逛呢，大概 $remain 后回家~';
      return '我在图书馆看书呢，大概 $remain 后回家~';
    }
    return '我在外面呢，大概 $remain 后回家~';
  }
  if (activeEmoteKey != null && hobbyLabels.containsKey(activeEmoteKey)) {
    return '我在${hobbyLabels[activeEmoteKey]}呢~';
  }
  return '没干嘛呀，就在家里待着~';
}

/// True for a direct "what are you buying" question — only meaningful while
/// actually shopping (checked by the caller); mirrors the demo's own
/// `/买什么|准备买/` check, gated on `pet.outKind==='shop'`.
bool isShopIntentQuery(String text) => RegExp('买什么|准备买').hasMatch(text);

const _happyHomecomingLines = <String>[
  '我回来啦，今天玩得很开心~',
  '到家咯，这一趟很值得！',
  '我回来了，心情还不错呢~',
];
const _roughHomecomingLines = <String>[
  '我回来了…今天有点不顺',
  '到家咯，刚才遇到点小意外',
  '我回来了，有点累，让我歇会儿',
];
const _neutralHomecomingLines = <String>[
  '我回来啦~',
  '到家咯，接下来干点别的吧',
  '我回来了',
];

/// A first-person "I'm home" line for the pet's spoken bubble when a work
/// session or a trip ends — picked by mood sentiment (not by re-narrating
/// the mechanical outcome text), so the bubble reads like something Clawd
/// would actually say ("我回来了，今天玩得很开心") rather than repeating the
/// action-log line verbatim ("剧本杀回来 · 线索严谨，成功还原真相"). The log
/// keeps the descriptive text; only the bubble uses this.
String homecomingSpeech(int moodDelta, math.Random random) {
  final pool = moodDelta > 0
      ? _happyHomecomingLines
      : moodDelta < 0
      ? _roughHomecomingLines
      : _neutralHomecomingLines;
  return pool[random.nextInt(pool.length)];
}

/// Same as [homecomingSpeech], but names the specific surprise item when a
/// shop trip's `giftItem` mechanic fired ("我看到一个xx，感觉很好吃，给你
/// 也买了一份") instead of a generic sentiment line — the log keeps the
/// mechanical "多买了一份X要送你" text regardless; only the spoken bubble
/// gets this more specific version.
String homecomingSpeechFor(SettleResult result, math.Random random) {
  final gift = result.giftItem;
  if (gift != null) return '我看到一个$gift，感觉很好吃，给你也买了一份';
  return homecomingSpeech(result.moodDelta, random);
}

/// A first-person "I want to go do X" line for when the pet decides to do
/// something **on its own** (no user/model command involved) — distinct
/// from [OurHomeActionResult.summary]'s command-acknowledgment phrasing
/// ("好呀，我们出发吧!"), which should only be spoken when a human or a
/// model actually issued the action. Returns null for actions with no
/// natural self-initiated line (falls back to the summary).
const Map<String, String> autonomousDepartureSpeech = <String, String>{
  'work': '我想去挣点钱，等我回来~',
  'sleep': '有点困了，我去睡一下~',
  'shop': '我想去买点东西，等我带战利品回来',
  'adventure': '我想去冒险，等我给你带战利品回来',
  'library': '我想去图书馆看看书',
  'street': '我想出去逛逛街',
  'mystery': '我想去玩一把剧本杀',
  'escape': '我想去挑战一下密室逃脱',
  'outing': '我想出去转转，等我带战利品回来',
  'eat': '我有点饿了，去吃点东西',
  'bath': '我去洗个澡~',
  'drink': '我去喝点东西',
  'snack': '我去吃点零食',
  'cook': '我去下厨做点吃的',
};

/// Keyword-matches free-form chat text to one of [ourHomeActionKeys] —
/// mirrors the standalone demo's `craftReply` keyword matching, kept
/// intentionally small (the subset of activities actually wired up so far).
/// Returns null if nothing matched.
String? matchOurHomeAction(String text) {
  if (RegExp('工作|上班|打工').hasMatch(text)) return 'work';
  if (RegExp('睡觉|睡了|去睡').hasMatch(text)) return 'sleep';
  if (RegExp('做饭|下厨|烧饭|做菜').hasMatch(text)) return 'cook';
  if (RegExp('吃饭|饿了|吃东西').hasMatch(text)) return 'eat';
  if (RegExp('喝水|渴了|喝点').hasMatch(text)) return 'drink';
  if (RegExp('洗澡|冲凉').hasMatch(text)) return 'bath';
  if (RegExp('零食|吃点小东西').hasMatch(text)) return 'snack';
  if (RegExp('回来|回家|叫醒|起床|别睡了').hasMatch(text)) return 'come_home';
  if (RegExp('给钱|给点钱').hasMatch(text)) return 'give_money';
  // Specific destinations checked before the generic "旅行/出去玩" pattern
  // below — a bare "玩" used to swallow near-miss phrasings of these (e.g.
  // "我想玩剧本杀" doesn't contain the literal "去剧本杀"), same fix already
  // applied in the standalone demo.
  if (RegExp('去购物|去超市|去采购|购物|采购|买东西').hasMatch(text)) return 'shop';
  if (RegExp('去冒险|冒险').hasMatch(text)) return 'adventure';
  if (RegExp('去图书馆|图书馆').hasMatch(text)) return 'library';
  // "逛街" (window-shopping/strolling downtown) is its own street scene, not
  // the 采购/超市 grocery-run 'shop' action above.
  if (RegExp('逛街|去逛街|街上走走|街上逛逛').hasMatch(text)) return 'street';
  if (RegExp('去剧本杀|剧本杀').hasMatch(text)) return 'mystery';
  if (RegExp('去密室|密室逃脱|密室').hasMatch(text)) return 'escape';
  if (RegExp('旅行|出去玩|出门|去玩|带我玩').hasMatch(text)) return 'outing';
  return null;
}

/// True for a plain "what are you up to" query — checked before
/// [matchOurHomeAction] so asking about status never accidentally triggers
/// an action.
bool isOurHomeStatusQuery(String text) =>
    RegExp('在干嘛|在做什么|干嘛呢|怎么样|状态').hasMatch(text);

// ---------- autonomous behavior (no user input at all) ----------

/// Ported verbatim from the demo's `HOBBY_POOL` — the pet's own pick when
/// it autonomously decides to do a hobby with nothing prompting it.
const autonomousHobbyPool = <(String key, String log)>[
  ('lm', '自己听起了歌'),
  ('rd', '自己看起了书'),
  ('gt', '自己弹起了吉他'),
  ('pt', '自己画起了画'),
  ('ph', '自己拍起了照'),
  ('wt', '自己浇起了花'),
  ('sg', '自己唱起了歌'),
  ('ex', '自己锻炼了一会儿'),
  ('gm', '自己打起了游戏'),
  ('dc', '自己跳起了舞'),
];

/// The pure outcomes `pickAutonomousChoice` can return that *aren't* one of
/// [ourHomeActionKeys] — the caller (the room page's idle-timer loop)
/// handles these two directly instead of dispatching through
/// [performOurHomeAction].
const autonomousCosmeticChoices = <String>['wander', 'hobby'];

/// One weighted-random autonomous choice — ported from the demo's
/// `decideNextHomeAction` weight table exactly (same 9 options, same
/// formulas keyed on coins/mood/needs/[workStreak]). Called once whenever
/// the pet has been idle at home long enough with nothing else going on.
/// Returns 'wander' or 'hobby' (pure cosmetic, see
/// [autonomousCosmeticChoices]), 'meal' (caller must still decide cook vs.
/// eat — see [preferCookingForMeal]), or one of [ourHomeActionKeys]
/// ('sleep'/'work'/'eat'/'bath'/'drink'/'snack') directly. 'out' is resolved
/// here into a concrete 'shop'/'adventure'/'outing' pick, matching the
/// demo's own `kinds` array (shop only offered once coins >= 200).
String pickAutonomousChoice(
  OurHomeState home,
  int workStreak,
  math.Random random,
) {
  final canCook = home.canCookAnything;
  final mealPool = home.itemsByNeed('meal');
  final bathPool = home.itemsByNeed('bath');
  final drinkPool = home.itemsByNeed('drink');
  final snackPool = home.itemsByNeed('snack');
  final stockedOut =
      (mealPool.isEmpty && !canCook) || bathPool.isEmpty || drinkPool.isEmpty;
  final opts = <(String, double)>[
    ('wander', 22),
    ('hobby', 20 + (home.mood < 55 ? 15 : 0)),
    ('sleep', home.mood < 30 ? 26 : 4),
    (
      'work',
      math.max(
        6,
        16 + (home.coins < 250 ? 35 : 0) - (workStreak >= 2 ? 10 : 0),
      ).toDouble(),
    ),
    ('out', (home.mood >= 62 ? 22 : 6) + (stockedOut ? 18 : 0)),
    ('meal', (mealPool.isNotEmpty || canCook) ? (home.mealShort ? 18 : 3) : 0),
    ('bath', bathPool.isNotEmpty ? (home.bathShort ? 14 : 2) : 0),
    ('drink', drinkPool.isNotEmpty ? (home.drinkShort ? 12 : 2) : 0),
    ('snack', snackPool.isNotEmpty ? 6 : 0),
  ];
  final choice = pickWeighted(opts, (o) => o.$2, random).$1;
  if (choice != 'out') return choice;
  final kinds = <String>['outing', 'adventure', if (home.coins >= 200) 'shop'];
  return kinds[random.nextInt(kinds.length)];
}

/// Whether an autonomous 'meal' choice should cook instead of just eating —
/// mirrors the demo's own preference-for-cooking rule (always cook when
/// there's nothing ready-to-eat in stock; otherwise a coin flip).
bool preferCookingForMeal(OurHomeState home, math.Random random) {
  if (!home.canCookAnything) return false;
  final mealPool = home.itemsByNeed('meal');
  return mealPool.isEmpty || random.nextDouble() < 0.5;
}

// ---------- interruption (poking or messaging the pet while it's busy) ----------
//
// InterruptOutcome/rollInterrupt now live in our_home_state.dart (so
// OurHomeState itself can use them without a circular import) and are
// re-exported (see the top of this file) for every existing caller.

/// Emote keys that count as "doing a hobby" — ported verbatim from the
/// demo's `HOBBY_KEYS`. Poking the pet, or sending it an unrelated chat
/// command, while one of these is playing goes through [rollInterrupt]
/// instead of succeeding immediately.
const hobbyEmoteKeys = <String>{
  'lm',
  'rd',
  'gt',
  'pt',
  'ph',
  'wt',
  'cf',
  'sg',
  'ex',
  'gm',
  'dc',
  'ck',
  'ty',
  'tv',
  'ch',
  'jg',
};
