/// Chat-keyword triggers for the 35 real Clawd emote poses, ported directly
/// from the standalone demo's `craftReply` keyword matching
/// (scratchpad/our-home-demo.html / extracted.js, ~line 2098-2141). Pure
/// Dart, no Flutter/Canvas dependency — the poses themselves render via
/// `our_home_emotes.dart` and friends.
///
/// 7 of the 35 keys (work='cd', sleep='sl', eat='et', bath='sh', drink='cf',
/// snack='ch', cook='ck') are driven by real economy state/actions instead
/// of a standalone keyword match — see `_OurHomePageState` in app.dart,
/// which maps those action keys to these same pose codes. The 28 entries
/// below are pure cosmetic reactions: play the pose, log a line, nudge mood
/// once, then fall back to whatever ambient state was showing before.
class OurHomeEmoteMeta {
  const OurHomeEmoteMeta({
    required this.pattern,
    required this.durationSeconds,
    required this.logText,
    required this.replyText,
    this.moodDelta = 0,
  });

  final String pattern; // RegExp source
  final double durationSeconds;
  final String logText;
  final String replyText;
  final int moodDelta;
}

/// mood deltas ported verbatim from the demo's `MOOD_DELTA` table — keys not
/// listed here (most of the 28) have no mood effect, matching the source.
const Map<String, int> ourHomeEmoteMoodDelta = {
  'bd': 15,
  'xm': 12,
  'sp': 10,
  'ma': 8,
  'db': 8,
  'hw': 8,
  'lf': 8,
  'vd': 10,
  'qx': 8,
  'fw': 10,
  'sl': 10,
  'dz': 4,
  'hp': 6,
  'ag': -8,
  'hu': -10,
  'jj': -4,
};

/// The 28 pure-cosmetic reaction poses, keyed the same as the demo's
/// `data-key`. Checked in this order (first match wins) — order matters
/// only for the couple of keys sharing loose Chinese synonyms.
const Map<String, OurHomeEmoteMeta> ourHomeEmoteTriggers = {
  'lm': OurHomeEmoteMeta(
    pattern: '听歌|音乐',
    durationSeconds: 6,
    logText: '戴上耳机听起了歌',
    replyText: '嗯~ 来点音乐',
  ),
  'rd': OurHomeEmoteMeta(
    pattern: '看书|读书',
    durationSeconds: 8,
    logText: '翻开书看了起来',
    replyText: '正好想看点书',
  ),
  'gt': OurHomeEmoteMeta(
    pattern: '弹吉他|吉他',
    durationSeconds: 6,
    logText: '弹起了吉他',
    replyText: '弹一首给你听',
  ),
  'pt': OurHomeEmoteMeta(
    pattern: '画画|绘画',
    durationSeconds: 6,
    logText: '拿起画笔画了起来',
    replyText: '画点什么呢~',
  ),
  'wt': OurHomeEmoteMeta(
    pattern: '浇花|浇水',
    durationSeconds: 6,
    logText: '给花浇了浇水',
    replyText: '正好该浇水啦',
  ),
  'ph': OurHomeEmoteMeta(
    pattern: '拍照|照相',
    durationSeconds: 5,
    logText: '举起相机拍了张照',
    replyText: '茄子!',
  ),
  'gm': OurHomeEmoteMeta(
    pattern: '打游戏|玩游戏|游戏',
    durationSeconds: 6,
    logText: '打起了游戏',
    replyText: '来一局!',
  ),
  'ex': OurHomeEmoteMeta(
    pattern: '锻炼|运动|健身',
    durationSeconds: 5,
    logText: '锻炼了一会儿',
    replyText: '举铁走起',
  ),
  'bd': OurHomeEmoteMeta(
    pattern: '生日',
    durationSeconds: 5,
    logText: '庆祝了一下生日',
    replyText: '哇 生日快乐!',
    moodDelta: 15,
  ),
  'fw': OurHomeEmoteMeta(
    pattern: '烟花|放烟花|新年快乐|元旦',
    durationSeconds: 5,
    logText: '放了烟花',
    replyText: '哇~ 好漂亮',
    moodDelta: 10,
  ),
  'xm': OurHomeEmoteMeta(
    pattern: '圣诞',
    durationSeconds: 6,
    logText: '换上了圣诞装扮',
    replyText: '圣诞快乐!',
    moodDelta: 12,
  ),
  'hp': OurHomeEmoteMeta(
    pattern: '开心|高兴',
    durationSeconds: 4,
    logText: '开心地跳了起来',
    replyText: '嘿嘿,好开心~',
    moodDelta: 6,
  ),
  'ag': OurHomeEmoteMeta(
    pattern: '生气|气死|恼火',
    durationSeconds: 4,
    logText: '气鼓鼓的',
    replyText: '哼!人家生气了',
    moodDelta: -8,
  ),
  'dc': OurHomeEmoteMeta(
    pattern: '跳舞|舞蹈',
    durationSeconds: 5,
    logText: '跳起了舞',
    replyText: '一起扭起来~',
  ),
  'sg': OurHomeEmoteMeta(
    pattern: '唱歌',
    durationSeconds: 5,
    logText: '拿起麦唱起了歌',
    replyText: '来一首!',
  ),
  'sp': OurHomeEmoteMeta(
    pattern: '春节|新春',
    durationSeconds: 6,
    logText: '过起了春节',
    replyText: '新年好呀!',
    moodDelta: 10,
  ),
  'ma': OurHomeEmoteMeta(
    pattern: '中秋',
    durationSeconds: 8,
    logText: '赏起了月',
    replyText: '月亮好圆呀',
    moodDelta: 8,
  ),
  'db': OurHomeEmoteMeta(
    pattern: '端午',
    durationSeconds: 6,
    logText: '划起了龙舟',
    replyText: '端午安康!',
    moodDelta: 8,
  ),
  'hw': OurHomeEmoteMeta(
    pattern: '万圣节|万圣',
    durationSeconds: 6,
    logText: '过起了万圣节',
    replyText: '不给糖就捣蛋~',
    moodDelta: 8,
  ),
  'lf': OurHomeEmoteMeta(
    pattern: '元宵',
    durationSeconds: 6,
    logText: '提起了灯笼',
    replyText: '元宵节快乐',
    moodDelta: 8,
  ),
  'vd': OurHomeEmoteMeta(
    pattern: '情人节|爱心|喜欢|想你',
    durationSeconds: 6,
    logText: '比了个心',
    replyText: '我也喜欢你~',
    moodDelta: 10,
  ),
  'qx': OurHomeEmoteMeta(
    pattern: '七夕',
    durationSeconds: 6,
    logText: '看起了星河',
    replyText: '七夕快乐',
    moodDelta: 8,
  ),
  'jj': OurHomeEmoteMeta(
    pattern: '着急|紧张',
    durationSeconds: 4,
    logText: '急得团团转',
    replyText: '别急别急~',
    moodDelta: -4,
  ),
  'hu': OurHomeEmoteMeta(
    pattern: '受伤|疼',
    durationSeconds: 4,
    logText: '磕到了,有点疼',
    replyText: '嘶...疼疼',
    moodDelta: -10,
  ),
  'dz': OurHomeEmoteMeta(
    pattern: '打瞌睡|犯困',
    durationSeconds: 5,
    logText: '打起了瞌睡',
    replyText: '好困呀…',
    moodDelta: 4,
  ),
  'ty': OurHomeEmoteMeta(
    pattern: '玩具',
    durationSeconds: 5,
    logText: '玩起了玩具',
    replyText: '这个好好玩!',
  ),
  'tv': OurHomeEmoteMeta(
    pattern: '看电视|电视剧|追剧|看剧',
    durationSeconds: 8,
    logText: '在追剧呢',
    replyText: '在追剧呢',
  ),
  'jg': OurHomeEmoteMeta(
    pattern: '杂耍',
    durationSeconds: 5,
    logText: '玩起了杂耍',
    replyText: '看我的!',
  ),
};

/// Keyword-matches free-form chat text to one of the 28 cosmetic emote keys
/// above. Returns null if nothing matched — callers should try
/// [ourHomeActionKeys]'s economy actions (work/sleep/eat/...) first, since
/// those are the more consequential match and don't overlap in wording.
String? matchOurHomeEmoteKey(String text) {
  for (final entry in ourHomeEmoteTriggers.entries) {
    if (RegExp(entry.value.pattern).hasMatch(text)) return entry.key;
  }
  return null;
}
