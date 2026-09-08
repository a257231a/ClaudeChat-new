import 'dart:math' as math;

import 'package:flutter/material.dart'
    show Canvas, Color, Colors, Offset, Paint, Path, PaintingStyle, RRect, Radius, Rect;

/// Renders one of the 35 "real Clawd" emote poses (working/hobbies/moods/
/// festivals), ported from the standalone demo's SVG+CSS poses
/// (scratchpad/our-home-demo.html, `.emote[data-key="..."]`).
///
/// ## The coordinate trick that makes this a near-verbatim port
///
/// Every pose's SVG uses `viewBox="-15 -25 45 45"`, and `drawClawd`'s own
/// local coordinates were already hand-derived as "the source's units x2,
/// recentered so (0,0) sits at the feet" (see `_OurHomePainter._drawClawd`).
/// Concretely: `localX = 2*svgX - 15`, `localY = 2*svgY - 30`. That is
/// exactly what `canvas.translate(-15, -30); canvas.scale(2, 2);` produces
/// for free — so every pose function below can draw using the **raw
/// SVG source numbers verbatim** (rect x/y/width/height, ellipse cx/cy/rx/ry,
/// path points, transform="translate(a,b)" as canvas.translate(a,b), CSS
/// `transform-origin` as the pivot for canvas.rotate) instead of hand
/// re-deriving every coordinate. [paintOurHomeEmote] applies that transform
/// once so individual pose functions never have to.
///
/// ## Animation fidelity
///
/// The source's CSS keyframes (193 rules across 35 poses) are not
/// reproduced curve-for-curve — each is approximated with [oscillate] (back
/// -and-forth, matching `alternate`/ping-pong keyframes) or [loopFraction]
/// (one-shot-then-repeat, matching a note/spark/particle keyframe), which is
/// the same level of fidelity already used for `drawClawd`'s own bob/leg
/// -wave (sine functions, not literal CSS timing curves). This keeps 35
/// poses tractable while still reading as "alive" and matching each
/// keyframe's actual range and rough tempo.
typedef EmoteDrawFn = void Function(Canvas canvas, double t);

// ---------- drawing primitives (raw SVG-unit coordinates) ----------

void rect(Canvas c, double x, double y, double w, double h, Color color, {double opacity = 1}) {
  c.drawRect(
    Rect.fromLTWH(x, y, w, h),
    Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity),
  );
}

void rrect(Canvas c, double x, double y, double w, double h, double r, Color color, {double opacity = 1}) {
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
    Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity),
  );
}

void oval(Canvas c, double cx, double cy, double rx, double ry, Color color, {double opacity = 1}) {
  c.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity),
  );
}

void strokePath(Canvas c, List<Offset> points, Color color, double width) {
  if (points.length < 2) return;
  final path = _pathFrom(points);
  c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width,
  );
}

/// Straight-line polyline through [points] — used for the handful of poses
/// whose SVG `<path>` is a simple curve; the curve is approximated as a
/// couple of line segments rather than reproducing the exact bezier, in
/// keeping with this file's "recognizable, not pixel-identical" standard.
Path _pathFrom(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// Runs [draw] inside a translate + rotate-around-[originX],[originY]
/// transform — the canvas equivalent of an SVG group with
/// `transform-origin` + a CSS `rotate()`/`translate()` keyframe.
void withTransform(
  Canvas c, {
  double tx = 0,
  double ty = 0,
  double rotateDeg = 0,
  double originX = 0,
  double originY = 0,
  double scaleX = 1,
  double scaleY = 1,
  required void Function() draw,
}) {
  c.save();
  c.translate(tx, ty);
  if (rotateDeg != 0 || scaleX != 1 || scaleY != 1) {
    c.translate(originX, originY);
    if (rotateDeg != 0) c.rotate(rotateDeg * math.pi / 180);
    if (scaleX != 1 || scaleY != 1) c.scale(scaleX, scaleY);
    c.translate(-originX, -originY);
  }
  draw();
  c.restore();
}

// ---------- procedural animation helpers ----------

/// Oscillates between [min] and [max] with period [seconds] — matches an
/// `alternate`/ping-pong CSS keyframe (e.g. "rotate 0 -> 22deg alternate").
double oscillate(double t, double seconds, double min, double max, {double phase = 0}) {
  final wave = 0.5 + 0.5 * math.sin((2 * math.pi * t / seconds) + phase);
  return min + (max - min) * wave;
}

/// 0..1 fraction through a repeating cycle of [seconds] starting at [delay]
/// — matches a one-shot-then-repeat keyframe (floating note/spark/particle).
double loopFraction(double t, double seconds, {double delay = 0}) {
  final local = (t + delay) % seconds;
  return local / seconds;
}

const crabBody = Color(0xFFDE886D);
const crabEye = Color(0xFF000000);

// ---------- lm: 听歌 (listening to music) ----------

void _drawLm(Canvas c, double t) {
  final groove = oscillate(t, 1.1, -3, 3); // lm-groove rotate
  final bodyBob = oscillate(t, 1.1, 0, -1); // lm-groove translateY
  final shadowScaleX = oscillate(t, 1.1, 1, .9);
  final shadowOpacity = oscillate(t, 1.1, .5, .42);
  final blink = (t % 3) > 1.38 && (t % 3) < 1.62; // lm-blink dips at 50% of 3s
  final tapL = oscillate(t, 1.1, 0, 22); // lm-tap-l alternate .55s (2x for full cycle)
  final tapR = oscillate(t, 1.1, 0, -22);

  withTransform(
    c,
    tx: 0,
    ty: 0,
    draw: () {
      // floating music notes
      _lmNote(c, t, tx: 13, ty: -2, delay: 0, dur: 1.9, dx: 6, rot: 25, color: const Color(0xFFA98CFF));
      _lmNote(c, t, tx: -2, ty: -1, delay: -.7, dur: 2.2, dx: -5, rot: -20, color: const Color(0xFFC0A6FF));
      _lmNote(c, t, tx: 9, ty: -3, delay: -1.3, dur: 2, dx: 4, rot: 15, color: const Color(0xFF8C6CFF));
    },
  );

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);
  });

  withTransform(
    c,
    originX: 7.5,
    originY: 13,
    rotateDeg: groove,
    ty: bodyBob,
    draw: () {
      rect(c, 3, 13, 1, 2, crabBody);
      rect(c, 5, 13, 1, 2, crabBody);
      rect(c, 9, 13, 1, 2, crabBody);
      rect(c, 11, 13, 1, 2, crabBody);
      rect(c, 2, 6, 11, 7, crabBody);
      withTransform(c, originX: 2, originY: 10, rotateDeg: tapL, draw: () {
        rect(c, 0, 9, 2, 2, crabBody);
      });
      withTransform(c, originX: 13, originY: 10, rotateDeg: tapR, draw: () {
        rect(c, 13, 9, 2, 2, crabBody);
      });
      strokePath(c, const [Offset(1, 6), Offset(7.5, .5), Offset(14, 6)], const Color(0xFF2B2B35), 1.5);
      rrect(c, -.4, 6.2, 2.6, 3.6, .9, const Color(0xFF33333F));
      rrect(c, 12.8, 6.2, 2.6, 3.6, .9, const Color(0xFF33333F));
      rrect(c, .1, 6.8, 1.6, 2.4, .6, const Color(0xFF6A5AD0));
      rrect(c, 13.3, 6.8, 1.6, 2.4, .6, const Color(0xFF6A5AD0));
      final eyeH = blink ? 0.2 : 2.0;
      final eyeY = blink ? 8.9 : 8.0;
      rect(c, 4, eyeY, 1, eyeH, crabEye);
      rect(c, 10, eyeY, 1, eyeH, crabEye);
    },
  );
}

void _lmNote(
  Canvas c,
  double t, {
  required double tx,
  required double ty,
  required double delay,
  required double dur,
  required double dx,
  required double rot,
  required Color color,
}) {
  final f = loopFraction(t, dur, delay: delay);
  double opacity;
  if (f < .15) {
    opacity = f / .15;
  } else if (f < .8) {
    opacity = 1 - (f - .15) / .65 * .15;
  } else {
    opacity = .85 * (1 - (f - .8) / .2);
  }
  opacity = opacity.clamp(0, 1);
  final travelX = dx * f;
  final travelY = -19 * f;
  final angle = rot * f;
  withTransform(c, tx: tx + travelX, ty: ty + travelY, rotateDeg: angle, draw: () {
    oval(c, 0, 2, 1.1, .85, color, opacity: opacity);
    rect(c, 1, -2, .7, 4, color, opacity: opacity);
    rect(c, 1, -2, 2.2, .8, color, opacity: opacity);
  });
}

// ---------- registry ----------

/// All ported poses, keyed by the same 2-letter code the demo uses
/// (`data-key`). Populated incrementally as poses are ported — see the
/// class doc for which are done. Additional batches are added in sibling
/// files (`our_home_emotes_b.dart`, etc.) and merged into this map by
/// `our_home_emotes_registry.dart`.
final Map<String, EmoteDrawFn> ourHomeEmotesBatchA = {
  'lm': _drawLm,
};
