import 'dart:math' as math;

import 'package:flutter/material.dart' show Canvas, Color, Colors, Offset, Paint, Path;

import 'our_home_emotes.dart';

// ---------- shared body fragments (identical across almost every pose) ----------

void _legs(Canvas c) {
  rect(c, 3, 13, 1, 2, crabBody);
  rect(c, 5, 13, 1, 2, crabBody);
  rect(c, 9, 13, 1, 2, crabBody);
  rect(c, 11, 13, 1, 2, crabBody);
}

void _torso(Canvas c) => rect(c, 2, 6, 11, 7, crabBody);

void _shadow(Canvas c, double opacity) => rect(c, 3, 15, 9, 1, Colors.black, opacity: opacity);

Path _polyFrom(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  return path;
}

void _fillPoly(Canvas c, List<Offset> points, Color color, {double opacity = 1}) {
  c.drawPath(_polyFrom(points), Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity));
}

/// A small pixel-art heart (2 top squares + a wide mid band + a tapering
/// point), reused by `vd`'s eyes/rising hearts and `qx`'s floating heart.
void _pixelHeart(Canvas c, Color color, {double scale = 1, double opacity = 1}) {
  rect(c, 0, 0, .8 * scale, .8 * scale, color, opacity: opacity);
  rect(c, 1.2 * scale, 0, .8 * scale, .8 * scale, color, opacity: opacity);
  rect(c, 0, .6 * scale, 2 * scale, .9 * scale, color, opacity: opacity);
  rect(c, .5 * scale, 1.4 * scale, 1 * scale, .7 * scale, color, opacity: opacity);
}

/// A 4-point sparkle/star (a vertical + horizontal bar cross).
void _sparkle(Canvas c, Color color, {double opacity = 1, double scale = 1}) {
  rect(c, -.5 * scale, -2 * scale, 1 * scale, 4 * scale, color, opacity: opacity);
  rect(c, -2 * scale, -.5 * scale, 4 * scale, 1 * scale, color, opacity: opacity);
}

/// The "Z" glyph used by `dz`'s floating sleep marker — approximated as a
/// zigzag of 3 thin rects (top bar / diagonal / bottom bar) since this file
/// has no text-rendering primitive, matching the "recognizable, not
/// pixel-identical" standard for every other particle in this codebase.
void _zGlyph(Canvas c, Color color, double opacity) {
  withTransform(c, draw: () {
    rect(c, 0, 0, 3.2, .7, color, opacity: opacity);
    withTransform(c, originX: 1.6, originY: 1.6, rotateDeg: 62, draw: () {
      rect(c, 1.45, 0, .7, 3.2, color, opacity: opacity);
    });
    rect(c, 0, 2.9, 3.2, .7, color, opacity: opacity);
  });
}

// ---------- lf: 元宵 (lantern festival) ----------

void _drawLf(Canvas c, double t) {
  final walkRot = oscillate(t, 2.4, -1.5, 1.5);
  final walkY = oscillate(t, 2.4, 0, -.8);
  final shadowScaleX = oscillate(t, 2.4, 1, .92);
  final shadowOpacity = oscillate(t, 2.4, .5, .42);
  final blink = (t % 3) > 1.35 && (t % 3) < 1.65;
  final armRot = oscillate(t, 2.4, -58, -64);
  final lanRot = oscillate(t, 2.4, 4, -4);
  final glowOpacity = oscillate(t, 2, .85, 1);

  rect(c, 18 - .5, -2 - .5, 1, 1, const Color(0x1FFF9500)); // faint ambient glow marker (flat circle simplified)
  oval(c, 18, -2, 9, 9, const Color(0xFFFF9500), opacity: .12 * glowOpacity);

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    _shadow(c, shadowOpacity);
  });

  // distant teacup with steam, translate(-13,9)
  withTransform(c, tx: -13, ty: 9, draw: () {
    for (final s in [(0.0, -1.0), (-1.2, 1.0)]) {
      final f = loopFraction(t, 2.5, delay: s.$1);
      final op = f < .2 ? f / .2 * .7 : .7 * (1 - (f - .2) / .8);
      rect(c, 2 + s.$2, -1 - 7 * f, .8, 2, Colors.white, opacity: op.clamp(0, 1));
    }
    _fillPoly(c, const [Offset(0, 2), Offset(8, 2), Offset(7, 6), Offset(1, 6)], const Color(0xFF4FC3F7));
    rect(c, 0, 2, 8, 1, const Color(0xFF81D4FA));
    oval(c, 2.5, 2.4, 1.3, 1.3, const Color(0xFFFFF8F0));
    oval(c, 5.2, 2.4, 1.3, 1.3, const Color(0xFFFFF8F0));
    oval(c, 3.9, 3.4, 1.3, 1.3, const Color(0xFFFFFBF5));
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: walkRot, ty: walkY, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    withTransform(c, originX: 14, originY: 9, rotateDeg: armRot, draw: () {
      rect(c, 13, 8, 2, 2, crabBody);
    });
    final eyeH = blink ? .2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
  });

  withTransform(c, originX: 18, originY: -6, rotateDeg: lanRot, draw: () {
    withTransform(c, originX: 14, originY: 3, rotateDeg: 28, draw: () {
      rect(c, 14, -3, .6, 6, const Color(0xFF8B5A2B));
    });
    withTransform(c, tx: 18, ty: -6, draw: () {
      rect(c, -2, 0, 4, .6, const Color(0xFFFFC83D));
      rrect(c, -2.4, .6, 4.8, 5, 1.1, const Color(0xFFE03030));
      rrect(c, -1.4, 1, 3.2, 4, .8, const Color(0xFFFFB347), opacity: .6 * glowOpacity);
      rect(c, -2, 5.6, 4, .6, const Color(0xFFFFC83D));
      rect(c, -1.2, 6.2, .4, 2, const Color(0xFFFFC83D));
      rect(c, -.2, 6.2, .4, 2.4, const Color(0xFFFFC83D));
      rect(c, .8, 6.2, .4, 2, const Color(0xFFFFC83D));
    });
  });
}

// ---------- vd: 情人节 (valentine) ----------

void _vdRise(Canvas c, double t, {required double tx, required double ty, required double delay, required double dur, required double dxEnd, required double rotEnd, required Color color, double scale = 1}) {
  final f = loopFraction(t, dur, delay: delay);
  double opacity;
  if (f < .15) {
    opacity = f / .15;
  } else if (f < .8) {
    opacity = 1;
  } else {
    opacity = .7 * (1 - (f - .8) / .2);
  }
  opacity = opacity.clamp(0, 1);
  final s = f < .15 ? (.5 + .5 * (f / .15)) : 1.0;
  withTransform(
    c,
    tx: tx + dxEnd * f,
    ty: ty - 22 * f,
    rotateDeg: rotEnd * f,
    scaleX: s,
    scaleY: s,
    draw: () => _pixelHeart(c, color, scale: scale, opacity: opacity),
  );
}

void _drawVd(Canvas c, double t) {
  final sway = oscillate(t, 2.8, -2, 2);
  final shadowScaleX = oscillate(t, 2.8, 1, 1.03);
  final shadowOpacity = oscillate(t, 2.8, .5, .45);
  final blush = oscillate(t, 2.8, .6, .95);
  final heartbeat = oscillate(t, .8, 1, 1.2);

  _vdRise(c, t, tx: -8, ty: 8, delay: 0, dur: 2.8, dxEnd: -3, rotEnd: -12, color: const Color(0xFFFF4081));
  _vdRise(c, t, tx: 15, ty: 9, delay: -.9, dur: 2.4, dxEnd: 4, rotEnd: 18, color: const Color(0xFFFF6EA5), scale: .78);
  _vdRise(c, t, tx: 4, ty: 10, delay: -1.6, dur: 3, dxEnd: -2, rotEnd: -20, color: const Color(0xFFFF80AB), scale: .84);
  _vdRise(c, t, tx: 20, ty: 7, delay: -2.1, dur: 2.5, dxEnd: 5, rotEnd: 10, color: const Color(0xFFFF4081), scale: .7);

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    _shadow(c, shadowOpacity);
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sway, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 8, 2, 2, crabBody);

    withTransform(c, tx: 14, ty: 2, draw: () {
      rect(c, 0, 3, .6, 4, const Color(0xFF2E7D32));
      withTransform(c, originX: -.4, originY: 4.8, rotateDeg: -30, draw: () {
        rect(c, -1, 4.5, 1.2, .6, const Color(0xFF388E3C));
      });
      rrect(c, -1.5, 0, 3.2, 3, .6, const Color(0xFFE91E63));
      rrect(c, -.8, .6, 1.6, 1.6, .3, const Color(0xFFFF5C8D));
    });

    rrect(c, 3, 10, 1.6, 1, .5, const Color(0xFFFF7AA8), opacity: blush);
    rrect(c, 10.4, 10, 1.6, 1, .5, const Color(0xFFFF7AA8), opacity: blush);

    withTransform(c, tx: 3.4, ty: 8, originX: 1, originY: 1, scaleX: heartbeat, scaleY: heartbeat, draw: () {
      _pixelHeart(c, const Color(0xFFFF1744));
    });
    withTransform(c, tx: 9.4, ty: 8, originX: 1, originY: 1, scaleX: heartbeat, scaleY: heartbeat, draw: () {
      _pixelHeart(c, const Color(0xFFFF1744));
    });
  });
}

// ---------- qx: 七夕 (qixi) ----------

void _drawQx(Canvas c, double t) {
  final look = oscillate(t, 5, 0, -7);
  final shadowOpacity = oscillate(t, 5, .5, .35);
  final shadowScaleX = oscillate(t, 5, 1, .88);
  final magFly = oscillate(t, 6, 0, 3);
  final magFlyY = oscillate(t, 6, 0, -2);
  final wingFlap = oscillate(t, .3, 1, .5);
  final heartPulse = oscillate(t, 1.5, .85, 1);
  final heartScale = oscillate(t, 1.5, 1, 1.12);

  const starPositions = [
    (-11.0, -12.0, 1.6),
    (-8.0, -15.0, 1.8),
    (-4.0, -17.5, 2.0),
    (1.0, -19.0, 1.7),
    (7.0, -19.5, 1.9),
    (13.0, -19.0, 2.1),
    (18.0, -17.5, 1.8),
    (22.0, -15.0, 2.0),
    (25.0, -12.0, 1.7),
  ];
  for (final s in starPositions) {
    final op = oscillate(t, s.$3, .3, .9, phase: s.$1);
    final scale = oscillate(t, s.$3, .6, 1, phase: s.$1);
    withTransform(c, tx: s.$1 + .4, ty: s.$2 + .4, originX: 0, originY: 0, scaleX: scale, scaleY: scale, draw: () {
      rrect(c, -.4, -.4, .8, .8, .2, const Color(0xFFC5CEFF), opacity: op);
    });
  }

  final bigOp1 = oscillate(t, 2.5, .7, 1);
  final bigScale1 = oscillate(t, 2.5, .9, 1.2);
  withTransform(c, tx: -11, ty: -8, scaleX: bigScale1, scaleY: bigScale1, draw: () {
    _sparkle(c, const Color(0xFFFFE066), opacity: bigOp1);
  });
  final bigOp2 = oscillate(t, 2.5, .7, 1, phase: -1.2 / 2.5 * 2 * math.pi);
  final bigScale2 = oscillate(t, 2.5, .9, 1.2, phase: -1.2 / 2.5 * 2 * math.pi);
  withTransform(c, tx: 25, ty: -8, scaleX: bigScale2, scaleY: bigScale2, draw: () {
    _sparkle(c, const Color(0xFFFFB3D1), opacity: bigOp2);
  });

  withTransform(c, tx: 16 + magFly, ty: -13 + magFlyY, draw: () {
    oval(c, 0, 0, 1.4, 1, const Color(0xFF222222));
    rrect(c, 1, -.4, 1.6, .8, .3, const Color(0xFF222222));
    withTransform(c, originX: -2, originY: -.4, scaleX: wingFlap, draw: () {
      _fillPoly(c, const [Offset(-1, -.4), Offset(-3, -1.4), Offset(-2.4, .6)], const Color(0xFF222222));
    });
    rect(c, -2.4, -.2, 2, .5, const Color(0xFF222222));
  });

  withTransform(c, tx: 6, ty: -22, originX: 1, originY: 1, scaleX: heartScale, scaleY: heartScale, draw: () {
    _pixelHeart(c, const Color(0xFFFF6B9D), scale: 1.5, opacity: heartPulse);
  });

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    _shadow(c, shadowOpacity);
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: look, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
  });
}

// ---------- jj: 着急 (anxious, original) ----------

void _drawJj(Canvas c, double t) {
  final jitter = oscillate(t, .15, 0, .6);
  final dartCycle = t % .8;
  final eyeDx = dartCycle < .4 ? -.8 : (dartCycle < .5 ? .8 : (dartCycle < .9 ? .8 : -.8));
  final wringL = oscillate(t, .3, 30, 48);
  final wringR = oscillate(t, .3, -30, -48);
  final sweatF = loopFraction(t, 1);
  final sweatOp = sweatF < .3 ? sweatF / .3 : (1 - (sweatF - .3) / .7);

  rect(c, 12, 4 + 6 * sweatF, 1.2, 1.8, const Color(0xFF7EC8FF), opacity: sweatOp.clamp(0, 1));
  _shadow(c, .5);

  withTransform(c, tx: jitter, draw: () {
    _legs(c);
    _torso(c);
    withTransform(c, originX: 2, originY: 10, rotateDeg: wringL, draw: () {
      rect(c, 1, 9.5, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: wringR, draw: () {
      rect(c, 12, 9.5, 2, 2, crabBody);
    });
    withTransform(c, tx: eyeDx, draw: () {
      rect(c, 4, 8, 1, 2, crabEye);
      rect(c, 10, 8, 1, 2, crabEye);
    });
  });
}

// ---------- hu: 受伤 (hurt) ----------

void _drawHu(Canvas c, double t) {
  final limpRot = oscillate(t, 1.2, -2, 3);
  final limpY = oscillate(t, 1.2, 0, -.6);
  final f = loopFraction(t, 1.6);
  final starOp = f < .3 ? f / .3 : (1 - (f - .3) / .7);
  final starRot = 40 * f;
  final starScale = f < .3 ? .5 + .5 * (f / .3) : .8 + .2 * (1 - (f - .3) / .7);

  withTransform(c, tx: 11, ty: 4, rotateDeg: starRot, scaleX: starScale, scaleY: starScale, draw: () {
    _sparkle(c, const Color(0xFFFFD700), opacity: starOp.clamp(0, 1));
  });
  _shadow(c, .5);

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: limpRot, ty: limpY, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 9.6, 8.8, 1.6, .6, crabEye);
    withTransform(c, originX: 6, originY: 7.4, rotateDeg: -10, draw: () {
      rect(c, 3, 6.6, 6, 1.6, const Color(0xFFF5E6C8));
      rect(c, 4.5, 6.9, 3, .5, const Color(0xFFC9622F), opacity: .5);
    });
  });
}

// ---------- dz: 打瞌睡 (dozing) ----------

void _drawDz(Canvas c, double t) {
  final f = loopFraction(t, 2.6);
  double nodRot, nodY;
  if (f < .6) {
    nodRot = 0;
    nodY = 0;
  } else if (f < .85) {
    final k = (f - .6) / .25;
    nodRot = 18 * k;
    nodY = 1 * k;
  } else {
    final k = (f - .85) / .15;
    nodRot = 18 * (1 - k);
    nodY = 1 * (1 - k);
  }
  final zf = loopFraction(t, 2.6);
  double zOp;
  if (zf < .55) {
    zOp = 0;
  } else if (zf < .7) {
    zOp = (zf - .55) / .15;
  } else {
    zOp = (1 - (zf - .7) / .3);
  }
  zOp = zOp.clamp(0, 1);
  final zProgress = zf < .55 ? 0.0 : (zf - .55) / .45;

  withTransform(c, tx: 11 + 3 * zProgress, ty: -2 - 8 * zProgress, scaleX: .6 + .5 * zProgress, scaleY: .6 + .5 * zProgress, draw: () {
    _zGlyph(c, const Color(0xFF8CA0FF), zOp);
  });

  _shadow(c, .5);
  _legs(c);
  withTransform(c, originX: 7.5, originY: 6, rotateDeg: nodRot, ty: nodY, draw: () {
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    rrect(c, 3.6, 8.9, 2, .7, .35, crabEye);
    rrect(c, 9.4, 8.9, 2, .7, .35, crabEye);
  });
}

// ---------- ty: 玩具 (toy) ----------

void _drawTy(Canvas c, double t) {
  final bounce = oscillate(t, .6, 0, -1.2);
  final blink = (t % 2.6) > 1.17 && (t % 2.6) < 1.43;
  final wave = oscillate(t, .5, -20, 20);

  _shadow(c, .5);
  withTransform(c, ty: bounce, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    withTransform(c, originX: 13, originY: 10, rotateDeg: wave, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
      withTransform(c, tx: 14, ty: 4, draw: () {
        rect(c, 0, 2, 3, 3, const Color(0xFF4AD6FF));
        rect(c, .5, 0, 2, 2, const Color(0xFF7EE2FF));
        rect(c, .3, 5, 1, 1.4, const Color(0xFF3A3A3A));
        rect(c, 1.7, 5, 1, 1.4, const Color(0xFF3A3A3A));
      });
    });
    final eyeH = blink ? .2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
  });
}

// ---------- tv: 看电视 (watching TV) ----------

void _drawTv(Canvas c, double t) {
  final bob = oscillate(t, 3, 0, -.4);
  final blink = (t % 3.6) > 1.62 && (t % 3.6) < 1.98;

  _shadow(c, .5);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    rrect(c, 13, 9, 2, 2.6, .4, crabBody);
    rrect(c, 12.6, 11.4, 2.8, 1.2, .3, const Color(0xFF3A3A3A));
    final eyeH = blink ? .2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
  });
}

// ---------- ch: 吃零食 (snacking) ----------

void _drawCh(Canvas c, double t) {
  final bob = oscillate(t, 1.6, 0, -.4);
  final chew = oscillate(t, .3, .5, 1);
  final feedRotF = loopFraction(t, 1.6);
  double feedRot;
  if (feedRotF < .12) {
    feedRot = 13;
  } else if (feedRotF < .48) {
    final k = (feedRotF - .12) / .36;
    feedRot = 13 - 16 * k;
  } else if (feedRotF < .82) {
    final k = (feedRotF - .48) / .34;
    feedRot = -3 + 16 * k;
  } else {
    feedRot = 13;
  }
  final crumbF = loopFraction(t, 1.6);
  final crumbOp = crumbF < .4 ? crumbF / .4 * .9 : .9 * (1 - (crumbF - .4) / .6);

  rect(c, 4, 12.5 + 4 * crumbF, .7, .7, const Color(0xFFE8B04B), opacity: crumbOp.clamp(0, 1));
  _shadow(c, .5);

  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 13, 9, 2, 2, crabBody);
    withTransform(c, originX: 0, originY: 10, rotateDeg: feedRot, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
      rrect(c, -1.2, 9.4, 3, 4.4, .3, const Color(0xFFE8394A));
      rect(c, -1.2, 9.4, 3, 1.4, const Color(0xFFFFD700));
    });
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
    withTransform(c, originX: 7.5, originY: 11.3, scaleY: chew, draw: () {
      rrect(c, 6.2, 10.7, 2.4, 1.2, .5, const Color(0xFF7A2230));
    });
  });
}

// ---------- ck: 做饭 (cooking) ----------

void _drawCk(Canvas c, double t) {
  final bob = oscillate(t, 1.4, 0, -.4);
  final stir = oscillate(t, 1.4, -18, 18);
  final fireOp = oscillate(t, .3, .7, 1);

  for (final s in [(4.0, 9.4, 0.0), (8.0, 9.4, -1.0)]) {
    final f = loopFraction(t, 2, delay: s.$3);
    final op = f < .3 ? f / .3 * .7 : .7 * (1 - (f - .3) / .7);
    rect(c, s.$1 + f, s.$2 - 7 * f, .7, 2, Colors.white, opacity: op.clamp(0, 1));
  }
  _shadow(c, .5);

  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    rect(c, 0, 9, 2, 2, crabBody);
    withTransform(c, originX: 11, originY: 9, rotateDeg: stir, draw: () {
      rect(c, 11, 8, 2, 2, crabBody);
      rect(c, 11.6, 4, .8, 5, const Color(0xFF8B5A2B));
    });
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
    _fillPoly(c, const [Offset(2, 11.4), Offset(12, 11.4), Offset(11, 14), Offset(3, 14)], const Color(0xFF5A5A62));
    oval(c, 7, 11.5, 4.6, 1, const Color(0xFF3A3A42));
  });

  withTransform(c, tx: 5, ty: 15.4, draw: () {
    rect(c, 0, -1.4, 1, 1.6, const Color(0xFFFF6B00), opacity: fireOp);
    rect(c, 1.4, -1.8, 1, 2, const Color(0xFFFF6B00), opacity: fireOp);
    rect(c, 2.8, -1.4, 1, 1.6, const Color(0xFFFF6B00), opacity: fireOp);
  });
}

// ---------- jg: 杂耍 (juggling) ----------

void _drawJg(Canvas c, double t) {
  final bob = oscillate(t, .5, 0, -1);
  final tossL = oscillate(t, .5, 50, 20);
  final tossR = oscillate(t, .5, -50, -20, phase: -.25 / .5 * 2 * math.pi);

  const balls = [
    (Color(0xFFFF5A5A), 0.0),
    (Color(0xFF4AD6FF), -.5),
    (Color(0xFFFFD14A), -1.0),
  ];
  for (final b in balls) {
    final phase = (t + b.$2) / 1.5 * 2 * math.pi;
    final bx = 6 * math.sin(phase);
    final by = -5.5 - 2.5 * math.cos(phase);
    oval(c, 7.5 + bx, by, 1.3, 1.3, b.$1);
  }

  _shadow(c, .5);
  withTransform(c, ty: bob, draw: () {
    _legs(c);
    _torso(c);
    withTransform(c, originX: 2, originY: 10, rotateDeg: tossL, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: tossR, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
  });
}

// ---------- registry ----------

final Map<String, EmoteDrawFn> ourHomeEmotesBatchD = {
  'lf': _drawLf,
  'vd': _drawVd,
  'qx': _drawQx,
  'jj': _drawJj,
  'hu': _drawHu,
  'dz': _drawDz,
  'ty': _drawTy,
  'tv': _drawTv,
  'ch': _drawCh,
  'ck': _drawCk,
  'jg': _drawJg,
};
