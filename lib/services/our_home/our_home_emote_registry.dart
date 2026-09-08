import 'package:flutter/material.dart' show Canvas;

import 'our_home_emotes.dart';
import 'our_home_emotes_b.dart';
import 'our_home_emotes_c.dart';
import 'our_home_emotes_d.dart';

/// Merges every pose batch into one draw registry and applies the shared
/// feet-anchored transform once, so callers never touch the per-pose
/// coordinate trick directly. See `our_home_emotes.dart`'s class doc for how
/// the transform works.
final Map<String, EmoteDrawFn> ourHomeEmoteDraw = {
  ...ourHomeEmotesBatchA,
  ...ourHomeEmotesBatchB,
  ...ourHomeEmotesBatchC,
  ...ourHomeEmotesBatchD,
};

/// Draws pose [key] anchored at ([feetX], [feetY]) — the same anchor point
/// `drawClawd` uses — animated against [t] (seconds, doesn't need to start
/// at 0; callers pass elapsed-since-pose-started for a clean loop start).
/// No-ops if [key] isn't a registered pose.
void paintOurHomeEmote(Canvas canvas, String key, double feetX, double feetY, double t) {
  final draw = ourHomeEmoteDraw[key];
  if (draw == null) return;
  canvas.save();
  canvas.translate(feetX, feetY);
  canvas.translate(-15, -30);
  canvas.scale(2, 2);
  draw(canvas, t);
  canvas.restore();
}
