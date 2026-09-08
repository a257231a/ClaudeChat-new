import 'package:flutter/material.dart' show Canvas, Color, Colors, Offset, Paint, Path, PaintingStyle;

import 'our_home_emotes.dart';

// ---------- batch-local helpers (duplicated across batch files on purpose —
// each batch is authored independently; see our_home_emotes.dart for the
// shared primitives these build on) ----------

void _legs(Canvas c) {
  rect(c, 3, 13, 1, 2, crabBody);
  rect(c, 5, 13, 1, 2, crabBody);
  rect(c, 9, 13, 1, 2, crabBody);
  rect(c, 11, 13, 1, 2, crabBody);
}

void _torso(Canvas c) => rect(c, 2, 6, 11, 7, crabBody);

void _plainArms(Canvas c) {
  rect(c, 0, 9, 2, 2, crabBody);
  rect(c, 13, 9, 2, 2, crabBody);
}

/// Rectangular blinking eyes — mostly open at [baselineH]/[baselineY], with
/// a brief narrow dip once per [period]s (matches the "0%,X%,100%: open;
/// 50%: closed" shape shared by nearly every pose's eye keyframe).
void _blinkEyes(Canvas c, double t, double period, {double baselineH = 2.0, double baselineY = 8.0}) {
  final phase = (t % period) / period;
  final blink = (phase - 0.5).abs() < 0.045;
  final h = blink ? .2 : baselineH;
  final y = blink ? 8.9 : baselineY;
  rect(c, 4, y, 1, h, crabEye);
  rect(c, 10, y, 1, h, crabEye);
}

void _shadow(Canvas c, double t, double period, {double minScaleX = .9, double maxOpacity = .5, double minOpacity = .42}) {
  final sx = oscillate(t, period, 1, minScaleX);
  final op = oscillate(t, period, maxOpacity, minOpacity);
  withTransform(c, originX: 7.5, originY: 15.5, scaleX: sx, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: op);
  });
}

Path _polyPath(List<Offset> pts) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  return path;
}

void _fillPoly(Canvas c, List<Offset> pts, Color color, {double opacity = 1}) {
  c.drawPath(_polyPath(pts), Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity));
}

void _strokeLine(Canvas c, double x1, double y1, double x2, double y2, Color color, double width) {
  c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width);
}

/// A single floating particle (note/spark/confetti) — opacity ramps in, holds,
/// ramps out over one loop, drifting by (dx,dy) and rotating by [rotDeg] as
/// it goes. Covers the "opacity 0->1->~0.8->0, translate, rotate" shape
/// shared by most of these poses' particle keyframes.
double _particleFraction(double t, double seconds, double delay) => loopFraction(t, seconds, delay: delay);

double _particleOpacity(double f, {double inEnd = .15, double outStart = .8, double holdOpacity = 1}) {
  if (f < inEnd) return (f / inEnd) * holdOpacity;
  if (f < outStart) return holdOpacity;
  return holdOpacity * (1 - (f - outStart) / (1 - outStart));
}

// ---------- gm: 打游戏 (gaming) ----------

void _drawGm(Canvas c, double t) {
  withTransform(c, draw: () {
    rect(c, -1, -12.5, 18, 11.4, const Color(0xFF16161D), opacity: oscillate(t, 2.4, .96, 1));
    rect(c, .4, -11.1, 15.2, 8.5, const Color(0xFF0B1626));
    rect(c, .4, -4.9, 15.2, 2.3, const Color(0xFF15401B));
    rect(c, 2.4, oscillate(t, .8, -6.9, -8.3), 1.9, 2, const Color(0xFF4AD6FF));
    rect(c, oscillate(t, 1.1, 10, 8), -5, 1.7, 2.4, const Color(0xFFFF5A5A));
    rrect(c, 12.8, -9.8, 1.1, 1.1, .55, const Color(0xFFFFD14A));
    rect(c, 5.2, -10, .9, .9, Colors.white, opacity: .6);
    rect(c, 7, -1.2, 2.6, 2, const Color(0xFF16161D));
    rrect(c, 3.8, .8, 9, 1.4, .6, const Color(0xFF16161D));
  });

  _shadow(c, t, 2.4);

  final lean = oscillate(t, 2.4, 0, -2);
  withTransform(c, originX: 7.5, originY: 13, rotateDeg: lean, ty: lean, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 2, 6, 11, 5, const Color(0xFF4AD6FF), opacity: oscillate(t, .5, .1, .26));
    withTransform(c, originX: 2, originY: 10, rotateDeg: oscillate(t, 2.4, 46, 40), draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: oscillate(t, 2.4, -46, -40), draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    _blinkEyes(c, t, 2.8, baselineH: 1.64);
    rrect(c, 2.6, 10.4, 9.8, 2.8, 1.3, const Color(0xFF2B2B34));
    rrect(c, 2.6, 10.4, 9.8, .9, 1.3, const Color(0xFF3A3A46));
    rect(c, 4, 11.4, 1.8, .7, const Color(0xFF555555));
    rect(c, 4.55, 10.85, .7, 1.8, const Color(0xFF555555));
    oval(c, 9.4, 11.3, .7, .7, const Color(0xFFFF5555));
    oval(c, 10.8, 12, .7, .7, const Color(0xFFFFD14A));
  });
}

// ---------- rd: 看书 (reading) ----------

void _drawRd(Canvas c, double t) {
  _shadow(c, t, 4.2, minScaleX: .97, minOpacity: .46);
  final bob = oscillate(t, 4.2, 0, -.5);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    _blinkEyes(c, t, 4.2);
    withTransform(c, originX: 1, originY: 10.6, rotateDeg: 28, draw: () {
      rrect(c, -.3, 9.6, 2.6, 2, .4, crabBody);
    });
    withTransform(c, originX: 14, originY: 10.6, rotateDeg: -28, draw: () {
      rrect(c, 12.7, 9.6, 2.6, 2, .4, crabBody);
    });
    _fillPoly(c, const [Offset(1.6, 12.4), Offset(2.8, 9.4), Offset(7.5, 9.9), Offset(7.5, 12.6)], const Color(0xFF8A5A2A));
    _fillPoly(c, const [Offset(13.4, 12.4), Offset(12.2, 9.4), Offset(7.5, 9.9), Offset(7.5, 12.6)], const Color(0xFF7A4E22));
    _fillPoly(c, const [Offset(2.2, 12.1), Offset(3.2, 9.7), Offset(7.5, 10.1), Offset(7.5, 12.2)], const Color(0xFFF5E6C8));
    final flip = (t % 4.2) / 4.2;
    final pageScaleX = (flip > .72 && flip < .88) ? .08 : 1.0;
    withTransform(c, originX: 7.5, originY: 11, scaleX: pageScaleX, draw: () {
      _fillPoly(c, const [Offset(12.8, 12.1), Offset(11.8, 9.7), Offset(7.5, 10.1), Offset(7.5, 12.2)], const Color(0xFFFBF1D8));
    });
    _strokeLine(c, 3.4, 10.6, 6.9, 10.9, const Color(0xFFC9B48A), .25);
    _strokeLine(c, 3.3, 11.3, 6.9, 11.5, const Color(0xFFC9B48A), .25);
    _strokeLine(c, 8.1, 10.9, 11.6, 10.6, const Color(0xFFC9B48A), .25);
    _strokeLine(c, 8.1, 11.5, 11.7, 11.3, const Color(0xFFC9B48A), .25);
    rect(c, 7.2, 9.7, .6, 2.9, const Color(0xFF5E3C1A));
  });
}

// ---------- ex: 锻炼 (exercise) ----------

void _drawEx(Canvas c, double t) {
  void sweat(double delay, double tx) {
    final f = _particleFraction(t, 1, delay);
    final opacity = f < .2 ? f / .2 : (1 - (f - .2) / .8);
    withTransform(c, tx: tx * f, ty: 6 * f, draw: () {
      rrect(c, 0, 0, 1.2, 1.6, .6, const Color(0xFF7EC8FF), opacity: opacity.clamp(0, 1));
    });
  }

  withTransform(c, tx: 13, ty: 4, draw: () => sweat(0, 4));
  withTransform(c, tx: 0, ty: 5, draw: () => sweat(-.5, -4));

  _shadow(c, t, 1, minScaleX: 1.06, maxOpacity: .5, minOpacity: .55);
  final squat = oscillate(t, 1, 0, 1);
  final squatScaleY = oscillate(t, 1, 1, .93);
  withTransform(c, ty: squat, scaleY: squatScaleY, originX: 7.5, originY: 13, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 2, 6.3, 11, 1.3, const Color(0xFFFF5555));
    rect(c, 2, 6.3, 11, .5, const Color(0xFFFF8888));
    withTransform(c, originX: 2, originY: 10, rotateDeg: oscillate(t, 1, 12, 74), draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
      rect(c, -1.6, 9.6, 5.2, .9, const Color(0xFF222222));
      rrect(c, -1.8, 8.9, 1, 2.3, .2, const Color(0xFF3A3A3A));
      rrect(c, 2.8, 8.9, 1, 2.3, .2, const Color(0xFF3A3A3A));
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: oscillate(t, 1, -12, -74), draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
      rect(c, 11.4, 9.6, 5.2, .9, const Color(0xFF222222));
      rrect(c, 11.2, 8.9, 1, 2.3, .2, const Color(0xFF3A3A3A));
      rrect(c, 15.8, 8.9, 1, 2.3, .2, const Color(0xFF3A3A3A));
    });
    final eyeH = oscillate(t, 1, 1.4, 1.0);
    rect(c, 4, 8 + (2 - eyeH) / 2, 1, eyeH, crabEye);
    rect(c, 10, 8 + (2 - eyeH) / 2, 1, eyeH, crabEye);
  });
}

// ---------- sl: 睡觉 (sleeping) ----------

void _drawSl(Canvas c, double t) {
  void zzz(double delay, double dur, double x, double y, double size, double tx) {
    final f = _particleFraction(t, dur, delay);
    final opacity = _particleOpacity(f, inEnd: .2, outStart: .8);
    withTransform(c, tx: x + tx * f, ty: y - 15 * f, scaleX: .6 + .7 * f, scaleY: .6 + .7 * f, draw: () {
      rect(c, 0, -size, size * .18, size, const Color(0xFF8CA0FF), opacity: opacity);
    });
  }

  zzz(0, 3, 11, -2, 3.4, 7);
  zzz(-1, 3, 13, -6, 4.4, 6);
  zzz(-2, 3, 15, -11, 5.6, 5);

  final shadowSx = oscillate(t, 3.6, 1, 1.03);
  oval(c, 7.5, 17.4, 13 * shadowSx, 1.3, Colors.black, opacity: oscillate(t, 3.6, .5, .46));

  rrect(c, -6, 13.4, 27, 4.4, 1.3, const Color(0xFF473B59));
  rrect(c, -6, 13.4, 27, 1.2, 1.3, const Color(0xFF5D4F73));
  rrect(c, -5, 11.7, 25, 2.6, 1.3, const Color(0xFFDFE4FF));
  rrect(c, -2, 8.6, 18, 5, 2.4, const Color(0xFFEEF1FF));
  rrect(c, -2, 8.6, 18, 1.6, 2.4, Colors.white);

  final breathe = oscillate(t, 3.6, 0, .5);
  final breatheScaleY = oscillate(t, 3.6, 1, .96);
  withTransform(c, ty: breathe, scaleY: breatheScaleY, originX: 7.5, originY: 13, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    rrect(c, 3.6, 8.9, 2, .7, .35, crabEye);
    rrect(c, 9.4, 8.9, 2, .7, .35, crabEye);
    final bubbleScale = oscillate(t, 3.6, .2, 1);
    oval(c, 12.4, 9.6, 1.1 * bubbleScale, 1.1 * bubbleScale, const Color(0xFFCFE0FF), opacity: .6);
    rect(c, 1.6, 4.8, 11.5, 1.6, const Color(0xFF3E5C8A));
    rect(c, 1.6, 4.8, 11.5, .6, const Color(0xFF587CB0));
    _fillPoly(c, const [Offset(2.5, 5), Offset(3, .8), Offset(7, -.2), Offset(11.4, -1.2), Offset(13, 1.6), Offset(12.2, 3.2), Offset(10, 1.8), Offset(7, 2.2), Offset(4, 2.6)], const Color(0xFF4A6FA5));
    oval(c, 12.6, 2, 1.6, 1.6, Colors.white);
  });

  _fillPoly(c, const [Offset(-5, 12.4), Offset(20, 12.4), Offset(20, 15.6), Offset(-5, 15.6)], const Color(0xFF3E5C8A));
  _fillPoly(c, const [Offset(-5, 12.4), Offset(20, 12.4), Offset(20, 13.4), Offset(-5, 13.4)], const Color(0xFF6E8FC4));
}

// ---------- pt: 画画 (painting) ----------

void _drawPt(Canvas c, double t) {
  _shadow(c, t, 2.6, minScaleX: .97, minOpacity: .46);
  void spark(double delay, double x, double y, Color color) {
    final f = _particleFraction(t, 2, delay);
    final opacity = _particleOpacity(f, inEnd: .3, outStart: .3, holdOpacity: 1);
    withTransform(c, tx: x, ty: y - 6 * f, draw: () {
      rrect(c, 0, 0, 1, 1, .2, color, opacity: opacity);
    });
  }

  final bob = oscillate(t, 2.6, 0, -.4);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    _blinkEyes(c, t, 3.2);
    rect(c, 0, 9, 2, 2, crabBody);
    oval(c, -1.6, 11.6, 3.5, 2.4, const Color(0xFFCAA46E));
    oval(c, -1.4, 12, 1, .8, const Color(0xFF1A1208));
    oval(c, -3.4, 10.8, .7, .7, const Color(0xFFFF5A5A));
    oval(c, -1.8, 9.9, .7, .7, const Color(0xFF4AD6FF));
    oval(c, -.1, 10.4, .7, .7, const Color(0xFFFFD14A));
    oval(c, -3.2, 12.4, .7, .7, const Color(0xFF5AD17A));
    withTransform(c, originX: 13, originY: 10, rotateDeg: oscillate(t, 1, -32, -6), draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
      withTransform(c, originX: 10.5, originY: 6.5, rotateDeg: 30, draw: () {
        rrect(c, 10.1, 3, .8, 7, .3, const Color(0xFFA9743A));
      });
      _fillPoly(c, const [Offset(8.6, 3.6), Offset(10.4, 2.2), Offset(11, 3.4), Offset(9.4, 4.6)], const Color(0xFFFF5A5A));
    });
    spark(0, 7.6, 1.6, const Color(0xFF4AD6FF));
    spark(-.9, 11, 2.4, const Color(0xFFFFD14A));
    spark(-1.4, 9.4, .6, const Color(0xFFFF5A5A));
  });
}

// ---------- ph: 拍照 (photo) ----------

void _drawPh(Canvas c, double t) {
  _shadow(c, t, 3, minScaleX: .97, minOpacity: .46);
  final bob = oscillate(t, 3, 0, -.4);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 6.2, 11.4, 2.6, .8, const Color(0xFF7A2230));
    withTransform(c, originX: 1.8, originY: 9.8, rotateDeg: 34, draw: () {
      rrect(c, .6, 8.8, 2.4, 2, .3, crabBody);
    });
    withTransform(c, originX: 13.2, originY: 9.8, rotateDeg: -34, draw: () {
      rrect(c, 12, 8.8, 2.4, 2, .3, crabBody);
    });
    rrect(c, 8.4, 5.6, 2.4, 1.6, .3, const Color(0xFF3A3A44));
    rrect(c, 2.6, 6.6, 9, 4.6, .7, const Color(0xFF2B2B34));
    rect(c, 2.6, 6.6, 9, 1, const Color(0xFF3A3A46));
    oval(c, 7, 9, 2, 2, const Color(0xFF1A1A20));
    oval(c, 7, 9, 1.3, 1.3, const Color(0xFF46566B));
    oval(c, 6.5, 8.5, .5, .5, const Color(0xFFA9C4E0));
    final flashLit = (t % 2.4) / 2.4 > .92 && (t % 2.4) / 2.4 < .95;
    rrect(c, 3.2, 7, 1.6, 1.1, .25, flashLit ? const Color(0xFFFFFBE0) : const Color(0xFF7A7D86));
    if (flashLit) {
      _fillPoly(c, const [Offset(.4, 4), Offset(1.1, 5.6), Offset(.4, 7.2), Offset(-.3, 5.6)], const Color(0xFFFFFBE0));
      _fillPoly(c, const [Offset(-1.4, 5.6), Offset(.2, 4.9), Offset(1.8, 5.6), Offset(.2, 6.3)], const Color(0xFFFFFBE0));
    }
  });
}

// ---------- wt: 浇花 (watering) ----------

void _drawWt(Canvas c, double t) {
  _shadow(c, t, 2.8, minScaleX: .97, minOpacity: .46);
  final bob = oscillate(t, 2.8, 0, -.4);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    _blinkEyes(c, t, 3.4);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    withTransform(c, originX: 13, originY: 10, rotateDeg: oscillate(t, 2.8, -4, -16), draw: () {
      rrect(c, 13.6, 4.4, 5.2, 3.8, .8, const Color(0xFF6FB3C9));
      rrect(c, 13.6, 4.4, 5.2, 1.1, .8, const Color(0xFF8FD0E2));
      _fillPoly(c, const [Offset(13.8, 7.6), Offset(10.2, 6.6), Offset(9.8, 7.9), Offset(13.6, 8.7)], const Color(0xFF6FB3C9));
      rrect(c, 9.4, 6.1, 1.5, 1.5, .3, const Color(0xFF8FD0E2));
    });
  });

  void drop(double delay) {
    final f = _particleFraction(t, 1, delay);
    final opacity = _particleOpacity(f, inEnd: .2, outStart: .2, holdOpacity: .9);
    rrect(c, 10, 7.8 + 8 * f, .7, 1.5, .35, const Color(0xFF7EC8FF), opacity: opacity);
  }

  drop(0);
  drop(-.3);
  drop(-.6);

  final sway = oscillate(t, 2.8, -3, 3);
  withTransform(c, originX: 10.5, originY: 13, rotateDeg: sway, draw: () {
    rect(c, 10.1, 11, .8, 2.6, const Color(0xFF3F9A52));
    withTransform(c, originX: 8.8, originY: 11.8, rotateDeg: -28, draw: () {
      oval(c, 8.8, 11.8, 1.5, .9, const Color(0xFF4FB564));
    });
    withTransform(c, originX: 12.2, originY: 11.6, rotateDeg: 28, draw: () {
      oval(c, 12.2, 11.6, 1.5, .9, const Color(0xFF4FB564));
    });
    oval(c, 10.5, 11.1, 1.2, 1.2, const Color(0xFFFF7EB0));
    oval(c, 10.5, 11.1, .5, .5, const Color(0xFFFFD14A));
  });
  _fillPoly(c, const [Offset(7.6, 13.4), Offset(13.6, 13.4), Offset(12.8, 16.4), Offset(8.4, 16.4)], const Color(0xFFC2693F));
  rrect(c, 7.3, 12.8, 6.6, 1.2, .3, const Color(0xFFD6794D));
}

// ---------- gt: 弹吉他 (guitar) ----------

void _drawGt(Canvas c, double t) {
  _shadow(c, t, 1.6, minScaleX: .95, minOpacity: .45);
  final bob = oscillate(t, 1.6, 0, -.5);
  final tilt = oscillate(t, 1.6, 0, -1.5);
  withTransform(c, ty: bob, originX: 7.5, originY: 13, rotateDeg: tilt, draw: () {
    _legs(c);
    _torso(c);
    _blinkEyes(c, t, 3);
    withTransform(c, originX: 7.5, originY: 10.4, rotateDeg: 46, draw: () {
      rrect(c, -1.6, 9.65, 9.6, 1.5, .3, const Color(0xFF6B4420));
      _strokeLine(c, 2.2, 9.65, 2.2, 11.15, const Color(0xFFCAA06A), .3);
      _strokeLine(c, 4, 9.65, 4, 11.15, const Color(0xFFCAA06A), .3);
      _strokeLine(c, 5.8, 9.65, 5.8, 11.15, const Color(0xFFCAA06A), .3);
      rrect(c, -3.7, 9.1, 2.6, 2.5, .4, const Color(0xFF4F3014));
      oval(c, -2.7, 9.6, .34, .34, const Color(0xFFCAA06A));
      oval(c, -2.7, 11.1, .34, .34, const Color(0xFFCAA06A));
    });
    oval(c, 9.6, 12.8, 3.5, 3, const Color(0xFFB9742F));
    oval(c, 9.6, 11.7, 2.7, 1.5, const Color(0xFFCF8A3C), opacity: .75);
    oval(c, 9, 12.4, 1.15, 1.15, const Color(0xFF3A2410));
    rrect(c, 9.8, 14, 1.8, .7, .15, const Color(0xFF5C3517));
    rect(c, -.2, 2.8, 2.2, 2, crabBody);
    withTransform(c, originX: 13, originY: 10, rotateDeg: oscillate(t, .4, -14, 8), draw: () {
      rrect(c, 8.6, 11.4, 2.4, 2, .4, crabBody);
    });
    void note(double delay, double x, double y, double size, double tx) {
      final f = _particleFraction(t, 2.2, delay);
      final opacity = _particleOpacity(f, inEnd: .25, outStart: .25);
      withTransform(c, tx: x + tx * f, ty: y - 13 * f, draw: () {
        rect(c, 0, 0, size * .3, size, const Color(0xFFE0A050), opacity: opacity);
      });
    }

    note(0, 13, 6, 4, 6);
    note(-1.1, 11, 4, 5, 8);
  });
}

// ---------- cd: 写代码 (coding — also shown continuously while genuinely
// working, so keep this one legible and well-lit) ----------

void _drawCd(Canvas c, double t) {
  _shadow(c, t, 2.4, minScaleX: .98, minOpacity: .47);
  final focus = oscillate(t, 2.4, 0, -.3);
  withTransform(c, ty: focus, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 2, 6, 11, 4, const Color(0xFF4FD6A0), opacity: oscillate(t, .6, .08, .2));
    _plainArms(c);
    _blinkEyes(c, t, 2.8);
    rrect(c, .4, 9.9, 14.2, 5.2, .5, const Color(0xFF23272F));
    rrect(c, 1.3, 10.6, 12.4, 3.8, .3, const Color(0xFF0C1018));
    final type1 = ((t % 1.8) < .9) ? .5 : 1.0;
    final type2 = (((t + .6) % 1.8) < .9) ? .5 : 1.0;
    final type3 = (((t + 1.2) % 1.8) < .9) ? .5 : 1.0;
    rect(c, 2.2, 11, 4 * type1, .7, const Color(0xFFFF79C6));
    rect(c, 6.8, 11, 3, .7, const Color(0xFF8BE9FD));
    rect(c, 3, 12.1, 5 * type2, .7, const Color(0xFF50FA7B));
    rect(c, 8.6, 12.1, 2.4, .7, const Color(0xFFF1FA8C));
    rect(c, 2.2, 13.2, 3.4 * type3, .7, const Color(0xFFBD93F9));
    final cursorOn = (t % 1) < .5;
    if (cursorOn) rect(c, 6, 13.2, .7, .8, Colors.white);
    rrect(c, -.4, 15, 15.4, 1, .4, const Color(0xFF2F343D));
  });
}

// ---------- bd: 生日 (birthday) ----------

void _drawBd(Canvas c, double t) {
  void confetti(double delay, double dur, double x, double y, double w, double h, double tx, double rot, Color color) {
    final f = _particleFraction(t, dur, delay);
    final opacity = _particleOpacity(f, inEnd: .12, outStart: .85);
    withTransform(c, tx: x + tx * f, ty: y + 22 * f, rotateDeg: rot * f, draw: () {
      rect(c, 0, 0, w, h, color, opacity: opacity);
    });
  }

  confetti(0, 1.4, -6, -20, 1.6, 1.6, -6, 220, const Color(0xFFFF4444));
  confetti(-.3, 1.1, 13, -22, 1.6, 1, 5, 160, const Color(0xFFFFD700));
  confetti(-.6, 1.5, 3, -23, 1, 1.6, -3, 280, const Color(0xFF44AAFF));
  confetti(-.9, 1.2, 19, -19, 1.6, 1, 7, 90, const Color(0xFFFF69B4));
  confetti(-.2, 1.6, -9, -16, 1, 1.6, -8, 320, const Color(0xFF44DD88));
  confetti(-.7, 1.05, 9, -24, 1.6, 1, 4, 180, const Color(0xFFFF9500));
  confetti(-.45, 1.35, 16, -18, 1, 1, -5, 240, const Color(0xFFCC44FF));
  confetti(-.85, 1.15, -3, -21, 1.6, 1.6, 2, 120, const Color(0xFFFFD700));

  final hopPhase = (t % 1.1) / 1.1;
  double hopY;
  double hopScaleX;
  double hopScaleY;
  if (hopPhase < .46) {
    final f = hopPhase / .46;
    hopY = -6 * f;
    hopScaleY = 1 - .15 * f;
    hopScaleX = 1 + .1 * f;
  } else if (hopPhase < .58) {
    hopY = -6;
    hopScaleY = 1.02;
    hopScaleX = .98;
  } else {
    final f = (hopPhase - .58) / .42;
    hopY = -6 * (1 - f);
    hopScaleY = 1 - .1 * (1 - f);
    hopScaleX = 1 + .05 * (1 - f);
  }
  final shadowSx = 1 - hopY.abs() / 6 * .45;
  oval(c, 7.5, 15.5, 9 * shadowSx / 2, .5, Colors.black, opacity: .5 - hopY.abs() / 6 * .32);

  withTransform(c, originX: 7.5, originY: 15, ty: hopY, scaleX: hopScaleX, scaleY: hopScaleY, draw: () {
    final hatWobble = oscillate(t, 1.1, -4, 3);
    withTransform(c, originX: 7.5, originY: 6, rotateDeg: hatWobble, draw: () {
      rect(c, 6.5, -1.5, 2, 2, Colors.white);
      rect(c, 6, .5, 3, 1, const Color(0xFFFF4444));
      rect(c, 5, 1.5, 5, 1, const Color(0xFFFFD700));
      rect(c, 4, 2.5, 7, 1, const Color(0xFFFF4444));
      rect(c, 3, 3.5, 9, 1, const Color(0xFFFFD700));
      rrect(c, 2, 4.5, 11, 1.2, 0, const Color(0xFFFF4444));
      rect(c, 2, 5.5, 11, .6, Colors.white, opacity: .55);
    });
    _legs(c);
    _torso(c);
    withTransform(c, originX: 2, originY: 10, rotateDeg: oscillate(t, .55, 35, 75), draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 14, originY: 10, rotateDeg: oscillate(t, .55, -35, -75), draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    _blinkEyes(c, t, 2.2);
  });

  withTransform(c, tx: 2.5, ty: 13.5, draw: () {
    rect(c, -1, 3.2, 11, .8, const Color(0xFFBBBBBB));
    rect(c, 0, 0, 9, 3.4, const Color(0xFFF48FB1));
    rect(c, 0, -.6, 9, 1, Colors.white);
    rect(c, 1, -.6, 1, 1.5, Colors.white);
    rect(c, 4, -.6, 1, 1.7, Colors.white);
    rect(c, 7, -.6, 1, 1.4, Colors.white);
    rect(c, 0, 1.6, 9, .5, Colors.white, opacity: .4);
    rect(c, 4, -4, 1, 3.4, const Color(0xFFFFD700));
    final flameSquash = ((t % .22) / .22) > .5 ? .65 : 1.0;
    withTransform(c, originX: 4.5, originY: -5, scaleX: flameSquash, scaleY: 2 - flameSquash, draw: () {
      rect(c, 4, -6, 1, 2, const Color(0xFFFF6B00));
      rect(c, 4.2, -6.5, .6, 1, const Color(0xFFFFD700));
    });
  });
}

// ---------- fw: 放烟花/元旦快乐 (fireworks / new year cheer) ----------

void _drawFw(Canvas c, double t) {
  void burst(double delay, double dx, double dy, Color color, double scale) {
    final f = _particleFraction(t, 2.4, delay);
    double opacity;
    double s;
    if (f < .15) {
      opacity = f / .15;
      s = .1 + .2 * (f / .15);
    } else if (f < .55) {
      opacity = 1;
      s = .3 + .7 * ((f - .15) / .4);
    } else if (f < .8) {
      opacity = 1 - .6 * ((f - .55) / .25);
      s = 1 + .15 * ((f - .55) / .25);
    } else {
      opacity = .4 * (1 - (f - .8) / .2);
      s = 1.15 + .1 * ((f - .8) / .2);
    }
    withTransform(c, tx: dx, ty: dy, scaleX: s * scale, scaleY: s * scale, draw: () {
      rect(c, -.5, -6, 1, 2.4, color, opacity: opacity);
      rect(c, -.5, 3.6, 1, 2.4, color, opacity: opacity);
      rect(c, -6, -.5, 2.4, 1, color, opacity: opacity);
      rect(c, 3.6, -.5, 2.4, 1, color, opacity: opacity);
      rect(c, -4.4, -4.4, 1.8, 1.8, color, opacity: opacity);
      rect(c, 2.6, -4.4, 1.8, 1.8, color, opacity: opacity);
      rect(c, -4.4, 2.6, 1.8, 1.8, color, opacity: opacity);
      rect(c, 2.6, 2.6, 1.8, 1.8, color, opacity: opacity);
    });
  }

  burst(0, -7, -16, const Color(0xFFFFD700), 1);
  burst(-.9, 7, -19, const Color(0xFFFF5252), .83);
  burst(-1.6, 19, -14, const Color(0xFF44CCFF), .75);

  final cheer = oscillate(t, 1.8, 0, -1.5);
  oval(c, 7.5, 15.5, 9 * oscillate(t, 1.8, 1, .94) / 2, .5, Colors.black, opacity: oscillate(t, 1.8, .5, .42));
  withTransform(c, ty: cheer, draw: () {
    _legs(c);
    _torso(c);
    withTransform(c, originX: 2, originY: 10, rotateDeg: oscillate(t, 1.8, 50, 70), ty: oscillate(t, 1.8, 0, -1), draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 14, originY: 10, rotateDeg: oscillate(t, 1.8, -50, -70), ty: oscillate(t, 1.8, 0, -1), draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    _blinkEyes(c, t, 1.8);
    rrect(c, 6, 11, 3, 1, .5, Colors.black);
  });
}

// ---------- xm: 圣诞快乐 (christmas) ----------

void _drawXm(Canvas c, double t) {
  void snow(double delay, double dur, double x, double y, double size, double tx) {
    final f = _particleFraction(t, dur, delay);
    final opacity = _particleOpacity(f, inEnd: .12, outStart: .88, holdOpacity: .9);
    withTransform(c, tx: x + tx * f, ty: y + 26 * f, draw: () {
      rrect(c, 0, 0, size, size, size / 2, Colors.white, opacity: opacity);
    });
  }

  snow(0, 3.2, -10, -23, 1.2, -3);
  snow(-.8, 2.8, -2, -24, 1, 2);
  snow(-1.5, 3.5, 6, -23, 1.4, -2);
  snow(-.4, 3, 14, -24, 1, 3);
  snow(-2, 3.3, 20, -22, 1.2, -1);
  snow(-1.2, 2.6, -13, -21, 1, 2);
  snow(-2.4, 3.4, 23, -20, 1.2, -3);

  withTransform(c, tx: -13, ty: 4, draw: () {
    _fillPoly(c, const [Offset(3, -2), Offset(5.5, 2), Offset(.5, 2)], const Color(0xFF2E7D32));
    _fillPoly(c, const [Offset(3, 0), Offset(6, 4), Offset(0, 4)], const Color(0xFF388E3C));
    _fillPoly(c, const [Offset(3, 2), Offset(6.5, 7), Offset(-.5, 7)], const Color(0xFF43A047));
    rect(c, 2.4, 7, 1.2, 2, const Color(0xFF6D4C41));
    final twinkle = oscillate(t, 1.6, .5, 1);
    rrect(c, 2.4 - (twinkle - .5) * .4, -3.4 - (twinkle - .5) * .4, 1.2 + (twinkle - .5) * .8, 1.2 + (twinkle - .5) * .8, .2, const Color(0xFFFFD700));
    oval(c, 1.8, 3, .5, .5, const Color(0xFFFF5252));
    oval(c, 4.2, 2, .5, .5, const Color(0xFFFFD700));
    oval(c, 3, 5.5, .5, .5, const Color(0xFF42A5F5));
  });

  _shadow(c, t, 2.6, minScaleX: 1.04, minOpacity: .45);
  final sway = oscillate(t, 2.6, -2, 2);
  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sway, draw: () {
    _legs(c);
    rect(c, 2, 3, 10, 2, const Color(0xFFCC0000));
    rect(c, 3, 1, 8, 2, const Color(0xFFD81B1B));
    rect(c, 5, -.5, 5, 2, const Color(0xFFE53535));
    final pomWobble = oscillate(t, 2.6, 0, 10);
    withTransform(c, originX: 9, originY: -2, rotateDeg: pomWobble, draw: () {
      rrect(c, 8, -2, 3, 2, .5, Colors.white);
    });
    rect(c, 2, 4.6, 10, 1.6, Colors.white);
    _torso(c);
    rect(c, 2, 10.5, 11, 1.8, const Color(0xFF1B7A3A));
    rect(c, 2, 10.5, 11, .6, const Color(0xFF34C75A));
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    _blinkEyes(c, t, 3);
  });
}

final Map<String, EmoteDrawFn> ourHomeEmotesBatchB = {
  'gm': _drawGm,
  'rd': _drawRd,
  'ex': _drawEx,
  'sl': _drawSl,
  'pt': _drawPt,
  'ph': _drawPh,
  'wt': _drawWt,
  'gt': _drawGt,
  'cd': _drawCd,
  'bd': _drawBd,
  'fw': _drawFw,
  'xm': _drawXm,
};
