import 'dart:math' as math;

import 'package:flutter/material.dart' show Canvas, Color, Colors, Offset, Paint, Path;

import 'our_home_emotes.dart';

// Batch C: hp (开心) ag (生气) dc (跳舞) sg (唱歌) et (吃饭) sh (洗澡) cf (喝咖啡)
// sp (春节) ma (中秋) db (端午) hw (万圣节) — see `our_home_emotes.dart`'s class
// doc for the shared coordinate trick and animation-fidelity standard this
// file follows exactly.

void _poly(Canvas c, List<Offset> pts, Color color, {double opacity = 1}) {
  if (pts.length < 3) return;
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  c.drawPath(path, Paint()..color = opacity == 1 ? color : color.withValues(alpha: opacity));
}

// ---------- hp: 开心 (happy) ----------

void _drawHp(Canvas c, double t) {
  final bob = oscillate(t, .7, 0, -2.4);
  final shadowScaleX = oscillate(t, .7, 1, .85);
  final shadowOpacity = oscillate(t, .7, .5, .35);
  final blink = (t % 2.4) > 1.1 && (t % 2.4) < 1.3;
  final armL = oscillate(t, .7, 55, 75);
  final armR = oscillate(t, .7, -55, -75);

  _hpSpark(c, t, x: -9, y: -6, delay: 0);
  _hpSpark(c, t, x: 16, y: -9, delay: -.5);
  _hpSpark(c, t, x: 4, y: -15, delay: -.9);

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);
  });

  withTransform(c, ty: bob, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    withTransform(c, originX: 2, originY: 10, rotateDeg: armL, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: armR, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    final eyeH = blink ? 0.2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
    rrect(c, 5.5, 11, 4, 1.2, .6, const Color(0xFF7A2230));
  });
}

void _hpSpark(Canvas c, double t, {required double x, required double y, required double delay}) {
  final f = loopFraction(t, 1.6, delay: delay);
  final opacity = f < .3 ? (f / .3).clamp(0, 1) : (1 - (f - .3) / .7).clamp(0, 1);
  final ty = -9 * f;
  final scale = .4 + .7 * f;
  withTransform(c, tx: x, ty: y + ty, scaleX: scale, scaleY: scale, originX: x, originY: y + ty, draw: () {
    rrect(c, x - .7, y + ty - .7, 1.4, 1.4, .3, const Color(0xFFFFD54F), opacity: opacity.toDouble());
  });
}

// ---------- ag: 生气 (angry) ----------

void _drawAg(Canvas c, double t) {
  final shake = oscillate(t, .12, -2, 2);
  final fistL = oscillate(t, .3, 10, 24);
  final fistR = oscillate(t, .3, -10, -24);

  _agSteam(c, t, x: 3.5, y: 3.5, delay: 0);
  _agSteam(c, t, x: 10, y: 3.5, delay: -.4);

  rect(c, 3, 15, 9, 1, Colors.black, opacity: .5);

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: shake, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    withTransform(c, originX: 2, originY: 10, rotateDeg: fistL, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: fistR, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    strokePath(c, const [Offset(3.2, 7.4), Offset(4.8, 7.9)], const Color(0xFF7A2230), .5);
    strokePath(c, const [Offset(11.8, 7.4), Offset(10.2, 7.9)], const Color(0xFF7A2230), .5);
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
  });
}

void _agSteam(Canvas c, double t, {required double x, required double y, required double delay}) {
  final f = loopFraction(t, 1.1, delay: delay);
  final opacity = f < .3 ? (.8 * f / .3).clamp(0, 1) : (.8 * (1 - (f - .3) / .7)).clamp(0, 1);
  final ty = -7 * f;
  final scaleX = 1 - .5 * f;
  withTransform(c, tx: x, ty: y + ty, scaleX: scaleX, originX: x, originY: y + ty, draw: () {
    rrect(c, x - .45, y + ty, .9, 2.6, .4, const Color(0xFFE8E8E8), opacity: opacity.toDouble());
  });
}

// ---------- dc: 跳舞 (dance) ----------

void _drawDc(Canvas c, double t) {
  final sway = oscillate(t, .5, -9, 9);
  final swayX = oscillate(t, .5, -1, 1);
  final blink = (t % 2.6) > 1.24 && (t % 2.6) < 1.36;
  final armL = oscillate(t, .5, 20, 80);
  final armR = oscillate(t, .5, -20, -80, phase: -math.pi);

  _danceNote(c, t, x: 12, y: -4, delay: 0, dur: 1.8, dx: 6, color: const Color(0xFFFF9EC8));
  _danceNote(c, t, x: -3, y: -6, delay: -.9, dur: 1.8, dx: -6, color: const Color(0xFFA98CFF));

  rect(c, 3, 15, 9, 1, Colors.black, opacity: .5);

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sway, tx: swayX, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    withTransform(c, originX: 2, originY: 10, rotateDeg: armL, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: armR, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    final eyeH = blink ? 0.2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
  });
}

void _danceNote(
  Canvas c,
  double t, {
  required double x,
  required double y,
  required double delay,
  required double dur,
  required double dx,
  required Color color,
}) {
  final f = loopFraction(t, dur, delay: delay);
  final opacity = f < .2 ? (f / .2).clamp(0, 1) : (1 - (f - .2) / .8).clamp(0, 1);
  withTransform(c, tx: x + dx * f, ty: y - 16 * f, rotateDeg: 20 * f, draw: () {
    oval(c, 0, 0, .9, .7, color, opacity: opacity.toDouble());
    rect(c, .6, -3, .5, 3, color, opacity: opacity.toDouble());
  });
}

// ---------- sg: 唱歌 (singing) ----------

void _drawSg(Canvas c, double t) {
  final sway = oscillate(t, 1.4, -3, 3);
  final shadowScaleX = oscillate(t, 1.4, 1, .92);
  final shadowOpacity = oscillate(t, 1.4, .5, .42);
  final blink = (t % 2.8) > 1.32 && (t % 2.8) < 1.48;
  final mouthScaleY = oscillate(t, .5, .45, 1.15);
  final mouthScaleX = oscillate(t, .5, .9, 1.05);
  final armL = oscillate(t, 1.4, 42, 78);
  final micRot = oscillate(t, 1.4, -3, 3);

  _sgNote(c, t, x: 0, y: -1, delay: 0, dur: 2, dx: -6, rot: -25, color: const Color(0xFFFF7AB3));
  _sgNote(c, t, x: 11, y: -2, delay: -.8, dur: 2.3, dx: -4, rot: 18, color: const Color(0xFFFF9EC8));
  _sgNote(c, t, x: 5, y: -3, delay: -1.4, dur: 2.1, dx: -7, rot: -12, color: const Color(0xFFFF5AA0));

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sway, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    withTransform(c, originX: 2, originY: 10, rotateDeg: armL, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    rrect(c, 11, 9, 2, 3.6, .5, crabBody);
    final eyeH = blink ? 0.2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
    withTransform(c, originX: 7, originY: 11.2, scaleX: mouthScaleX, scaleY: mouthScaleY, draw: () {
      oval(c, 7, 11.2, 1.3, 1.2, const Color(0xFF7A2230));
    });
    withTransform(c, originX: 11.5, originY: 12, rotateDeg: micRot, draw: () {
      withTransform(c, originX: 11.5, originY: 12, rotateDeg: 24, draw: () {
        rrect(c, 8.8, 11.1, 3.6, 1, .5, const Color(0xFF3A3A42));
      });
      oval(c, 8.7, 11, 1.5, 1.5, const Color(0xFF9A9AA2));
      oval(c, 8.4, 10.6, .5, .5, const Color(0xFFD6D6DE));
    });
  });
}

void _sgNote(
  Canvas c,
  double t, {
  required double x,
  required double y,
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
    opacity = 1;
  } else {
    opacity = .85 * (1 - (f - .8) / .2);
  }
  opacity = opacity.clamp(0, 1);
  withTransform(c, tx: x + dx * f, ty: y - 18 * f, rotateDeg: rot * f, draw: () {
    oval(c, 0, 1.6, 1, .75, color, opacity: opacity.toDouble());
    rect(c, .9, -1.8, .6, 3.6, color, opacity: opacity.toDouble());
  });
}

// ---------- et: 吃饭 (eating) ----------

void _drawEt(Canvas c, double t) {
  final bob = oscillate(t, 1.8, 0, -.4);
  final shadowScaleX = oscillate(t, 1.8, 1, .97);
  final shadowOpacity = oscillate(t, 1.8, .5, .46);
  final blink = (t % 3.4) > 1.56 && (t % 3.4) < 1.84;
  final chewScaleY = oscillate(t, .45, .5, 1);
  final feedAngle = oscillate(t, 1.8, -13, 3);

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);
  });

  withTransform(c, ty: bob, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    final eyeH = blink ? 0.2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
    withTransform(c, originX: 7.5, originY: 11.3, scaleY: chewScaleY, draw: () {
      rrect(c, 6.4, 10.7, 2.2, 1.2, .5, const Color(0xFF7A2230));
    });
    withTransform(c, originX: 1, originY: 11.4, rotateDeg: 34, draw: () {
      rrect(c, -.4, 10.4, 2.6, 2, .4, crabBody);
    });
    withTransform(c, originX: 13, originY: 10, rotateDeg: feedAngle, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
      rect(c, 6.2, 11.2, 7.6, .5, const Color(0xFFC9A227));
      rect(c, 6.2, 12.3, 7.6, .5, const Color(0xFFC9A227));
      rrect(c, 5.6, 11, 1.5, 1.5, .5, const Color(0xFFE8B04B));
    });
    _etSteam(c, t, x: 3.6, y: 9.6, delay: 0);
    _etSteam(c, t, x: 5.6, y: 9.6, delay: -1);
    oval(c, 5.5, 11.7, 3.2, 1.1, const Color(0xFFFBF6EE));
    _poly(c, const [Offset(2, 11.6), Offset(9, 11.6), Offset(8, 14), Offset(3, 14)], const Color(0xFF3F7FD0));
    rect(c, 2, 11.6, 7, .8, const Color(0xFF5A9AEA));
  });
}

void _etSteam(Canvas c, double t, {required double x, required double y, required double delay}) {
  final f = loopFraction(t, 2, delay: delay);
  final opacity = f < .25 ? (.7 * f / .25).clamp(0, 1) : (.7 * (1 - (f - .25) / .75)).clamp(0, 1);
  rect(c, x, y - 2 * f, .7, 2, Colors.white, opacity: opacity.toDouble());
}

// ---------- sh: 洗澡 (bathing) ----------

void _drawSh(Canvas c, double t) {
  final sway = oscillate(t, 2.2, -2, 2);
  final shadowScaleX = oscillate(t, 2.2, 1, .95);
  final shadowOpacity = oscillate(t, 2.2, .5, .45);
  final blinkScaleY = oscillate(t, 3, .7, .1);
  final scrubAngle = oscillate(t, .5, -26, -50);

  rect(c, 6.5, -23, 2, 3, const Color(0xFF8A98A0));
  _poly(c, const [Offset(2, -20), Offset(13, -20), Offset(11.5, -18), Offset(3.5, -18)], const Color(0xFFAAB6BD));
  rect(c, 3.5, -18.4, 8, .6, const Color(0xFF87949B));

  for (final w in [
    (3.5, 0.0),
    (6.0, -.3),
    (8.5, -.6),
    (10.8, -.15),
    (4.8, -.45),
    (9.6, -.75),
  ]) {
    final f = loopFraction(t, 1.1, delay: w.$2);
    final opacity = f < .15 ? (.85 * f / .15).clamp(0, 1) : (.85 * (1 - (f - .15) / .85)).clamp(0, 1);
    rect(c, w.$1, -17 + 20 * f, .8, 2.4, const Color(0xFF7EC8FF), opacity: opacity.toDouble());
  }

  for (final b in [(13.0, 10.0, 2.4, 0.0, 4.0), (1.0, 11.0, 2.8, -1.0, -3.0), (14.0, 12.0, 2.2, -1.6, 2.0)]) {
    final f = loopFraction(t, b.$3, delay: b.$4);
    final opacity = f < .25 ? (.6 * f / .25).clamp(0, 1) : (.6 * (1 - (f - .25) / .75)).clamp(0, 1);
    oval(c, b.$1 + b.$5 * f, b.$2 - 15 * f, 1.3, 1.3, const Color(0xFFCFEEFF), opacity: opacity.toDouble());
  }

  rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity * (shadowScaleX / shadowScaleX));

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sway, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    withTransform(c, originX: 7.5, originY: 9, scaleY: blinkScaleY, draw: () {
      rect(c, 4, 8, 1, 2, crabEye);
      rect(c, 10, 8, 1, 2, crabEye);
    });
    rect(c, 0, 9, 2, 2, crabBody);
    withTransform(c, originX: 13, originY: 10, rotateDeg: scrubAngle, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
      rrect(c, 10.2, 8.4, 2.6, 2.2, .4, const Color(0xFFFFD95E));
    });
    oval(c, 4, 5, 1.6, 1.6, Colors.white);
    oval(c, 7.5, 4.2, 2, 2, Colors.white);
    oval(c, 11, 5, 1.6, 1.6, Colors.white);
    oval(c, 5.8, 5.2, 1.4, 1.4, Colors.white);
    oval(c, 9.2, 5.2, 1.4, 1.4, Colors.white);
  });

  withTransform(c, tx: 9.5, ty: 13.6, draw: () {
    oval(c, 1.6, 1.6, 2, 1.4, const Color(0xFFFFD22E));
    oval(c, 3.2, .3, 1.1, 1.1, const Color(0xFFFFD22E));
    rrect(c, 3.9, .1, 1.4, .8, .3, const Color(0xFFFF9000));
    oval(c, 3.4, 0, .25, .25, Colors.black);
  });
}

// ---------- cf: 喝咖啡 (coffee) ----------

void _drawCf(Canvas c, double t) {
  // cf-sip: 0-55% rest, ~72% sipped, ~88% back to rest — approximate as a
  // brief dip using a narrow oscillate window driven off the fraction.
  final f = (t % 3.4) / 3.4;
  double sipAngle = 0;
  double sipY = 0;
  double shadowScaleX = 1;
  double shadowOpacity = .5;
  if (f > .55 && f < .88) {
    final local = (f - .55) / .33; // 0..1 across the sip window
    final wave = math.sin(local * math.pi);
    sipAngle = -7 * wave;
    sipY = -1 * wave;
    shadowScaleX = 1 - .07 * wave;
    shadowOpacity = .5 - .06 * wave;
  }
  final blink = (t % 3) > 1.38 && (t % 3) < 1.62;

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: sipAngle, ty: sipY, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    final eyeH = blink ? 0.2 : 2.0;
    final eyeY = blink ? 8.9 : 8.0;
    rect(c, 4, eyeY, 1, eyeH, crabEye);
    rect(c, 10, eyeY, 1, eyeH, crabEye);
    rrect(c, 6.4, 10.8, 2.2, 1, .5, const Color(0xFF7A2230));
    withTransform(c, originX: 1.4, originY: 11, rotateDeg: 40, draw: () {
      rrect(c, .4, 10, 2, 2.2, .3, crabBody);
    });
    withTransform(c, originX: 13.6, originY: 11, rotateDeg: -40, draw: () {
      rrect(c, 12.6, 10, 2, 2.2, .3, crabBody);
    });
    _cfSteam(c, t, x: 5.6, y: 8.2, delay: 0);
    _cfSteam(c, t, x: 8, y: 8.2, delay: -1.2);
    strokePath(c, const [Offset(11, 11), Offset(13.4, 11.2), Offset(13.4, 12.6), Offset(11, 12.4)], const Color(0xFFEFE9DF), .9);
    rrect(c, 4, 10.4, 7, 3.6, .7, const Color(0xFFEFE9DF));
    rect(c, 4, 10.4, 7, 1, Colors.white);
    oval(c, 7.5, 10.7, 2.9, .8, const Color(0xFF5B3A22));
  });
}

void _cfSteam(Canvas c, double t, {required double x, required double y, required double delay}) {
  final f = loopFraction(t, 2.4, delay: delay);
  final opacity = f < .3 ? (.6 * f / .3).clamp(0, 1) : (.6 * (1 - (f - .3) / .7)).clamp(0, 1);
  rect(c, x, y - 8 * f, .7, 2.4, Colors.white, opacity: opacity.toDouble());
}

// ---------- sp: 春节 (spring festival) ----------

void _drawSp(Canvas c, double t) {
  // sp-bow: rest most of the cycle, dips to a bow around 42-62%, small
  // settle around 80% — approximated the same "windowed sine" way as cf-sip.
  final f = (t % 3.2) / 3.2;
  double bowAngle = 0;
  double bowX = 0;
  double bowY = 0;
  double shadowScaleX = 1;
  if (f > .42 && f < .62) {
    final wave = math.sin(((f - .42) / .2) * math.pi);
    bowAngle = -16 * wave;
    bowX = -1 * wave;
    bowY = 1.2 * wave;
    shadowScaleX = 1 - .22 * wave;
  } else if (f >= .62 && f < .8) {
    final wave = 1 - (f - .62) / .18;
    bowAngle = -4 * wave;
    bowX = -.4 * wave;
  }
  final armWave = f > .42 && f < .62 ? math.sin(((f - .42) / .2) * math.pi) : 0.0;
  final lanternL = oscillate(t, .9, -7, 7);
  final lanternR = oscillate(t, .9, 7, -7);
  final fuPulse = oscillate(t, 2.4, 1, 1.06);

  strokePath(c, const [Offset(-8, -25), Offset(-8, -22)], const Color(0xFF7A0000), .5);
  strokePath(c, const [Offset(23, -25), Offset(23, -22)], const Color(0xFF7A0000), .5);
  _lantern(c, tx: -8, ty: -22, swing: lanternL);
  _lantern(c, tx: 23, ty: -22, swing: lanternR);

  withTransform(c, tx: 18, ty: -3, scaleX: fuPulse, scaleY: fuPulse, originX: 18, originY: -3, draw: () {
    withTransform(c, originX: 18, originY: -3, rotateDeg: 45, draw: () {
      rect(c, 14, -7, 8, 8, const Color(0xFFCC0000));
      rect(c, 15, -6, 6, 6, const Color(0xFFE81818), opacity: .6);
    });
    final gold = const Color(0xFFFFD700);
    rect(c, 15.2, -5.6, 5.6, .8, gold);
    rect(c, 17.6, -4.8, 1, 4, gold);
    rect(c, 15.8, -4, 4.8, .7, gold);
    rect(c, 15.8, -3.3, 1.8, 1.8, gold);
    rect(c, 18.6, -3.3, 1.8, 1.8, gold);
    rect(c, 15.8, -1.5, 4.8, .8, gold);
  });

  for (final coin in [(-11.0, -15.0, 0.0, 1.6, const Color(0xFFFFD700)), (-13.0, -10.0, -.5, 1.4, const Color(0xFFFFC107)), (-9.0, -18.0, -1.0, 1.7, const Color(0xFFFFEB3B))]) {
    final f2 = loopFraction(t, coin.$4, delay: coin.$3);
    final opacity = f2 < .14 ? (f2 / .14).clamp(0, 1) : (f2 < .88 ? .8 : (.8 * (1 - (f2 - .88) / .12)).clamp(0, 1));
    withTransform(c, tx: coin.$1, ty: coin.$2 + 20 * f2, rotateDeg: 360 * f2, draw: () {
      rrect(c, -1, -1, 2, 2, 1, coin.$5, opacity: opacity.toDouble());
    });
  }

  withTransform(c, originX: 7.5, originY: 15.5, scaleX: shadowScaleX, draw: () {
    rect(c, 3, 15, 9, 1, Colors.black, opacity: .5);
  });

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: bowAngle, tx: bowX, ty: bowY, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    rect(c, 2, 10, 11, 2, const Color(0xFFCC0000));
    rect(c, 2, 10, 11, .7, const Color(0xFFFF3838));
    withTransform(c, originX: 2, originY: 10, rotateDeg: 58 * armWave, draw: () {
      rect(c, 0, 9, 2, 2, crabBody);
    });
    withTransform(c, originX: 14, originY: 10, rotateDeg: -58 * armWave, draw: () {
      rect(c, 13, 9, 2, 2, crabBody);
    });
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
  });
}

void _lantern(Canvas c, {required double tx, required double ty, required double swing}) {
  withTransform(c, tx: tx, ty: ty, rotateDeg: swing, originX: tx, originY: ty, draw: () {
    final gold = const Color(0xFFFFC83D);
    rect(c, tx - 2.2, ty, 4.4, .6, gold);
    rrect(c, tx - 2.6, ty + .6, 5.2, 5.4, 1.2, const Color(0xFFCC0000));
    rrect(c, tx - 1.6, ty + .8, 1.6, 5, .8, const Color(0xFFE03030), opacity: .5);
    rect(c, tx - 1.2, ty + 2, 2.4, .5, gold);
    rect(c, tx - .4, ty + 2.5, 1, 1.6, gold);
    rect(c, tx - 2.2, ty + 6, 4.4, .6, gold);
    rect(c, tx - 1.4, ty + 6.6, .5, 2.4, gold);
    rect(c, tx - .25, ty + 6.6, .5, 2.8, gold);
    rect(c, tx + .9, ty + 6.6, .5, 2.4, gold);
  });
}

// ---------- ma: 中秋 (mid-autumn) ----------

void _drawMa(Canvas c, double t) {
  final lookAngle = oscillate(t, 6.5, 0, -9, phase: -math.pi * .3);
  final shadowOpacity = oscillate(t, 6.5, .5, .35);
  final moonBob = oscillate(t, 8, 0, -1.5);
  final rabbitBob = oscillate(t, 4, 0, -.6);

  withTransform(c, ty: moonBob, draw: () {
    oval(c, 7.5, -17, 8, 8, const Color(0xFFFFF0A0));
    oval(c, 4.5, -19.5, 1.3, 1.3, const Color(0xFFF0DC6A), opacity: .45);
    oval(c, 10.5, -15, .9, .9, const Color(0xFFF0DC6A), opacity: .4);
    withTransform(c, ty: rabbitBob, draw: () {
      final rabbit = const Color(0xFFE8CF6A);
      oval(c, 7.5, -14.5, 2, 1.4, rabbit, opacity: .7);
      oval(c, 6.2, -16, 1.1, 1.1, rabbit, opacity: .7);
      rect(c, 5.4, -18.5, .7, 2.2, rabbit, opacity: .7);
      rect(c, 6.4, -18.6, .7, 2.2, rabbit, opacity: .7);
    });
  });

  for (final star in [
    (-12.0, -23.0, 1.0, 1.8, 0.0),
    (21.0, -22.0, .8, 2.4, -.6),
    (-5.0, -24.0, .6, 1.5, -1.0),
    (24.0, -15.0, .8, 3.0, -.4),
    (-13.0, -13.0, .6, 2.0, -.9),
  ]) {
    final opacity = oscillate(t + star.$4, star.$3, .3, 1);
    rect(c, star.$1, star.$2, star.$5 == 0 ? 1 : star.$5, star.$5 == 0 ? 1 : star.$5, const Color(0xFFFFF8DC), opacity: opacity);
  }

  rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity);

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: lookAngle, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    rect(c, 2, 6, 11, 7, crabBody);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 7, 2, 2, crabBody);
    withTransform(c, tx: 13.5, ty: 3.5, draw: () {
      rrect(c, 0, 0, 4, 3.2, .4, const Color(0xFFC8860A));
      rrect(c, .4, .4, 3.2, 2.4, .3, const Color(0xFFD4950F));
      rect(c, 1, .9, 2, .4, const Color(0xFFA06808));
      rect(c, 1.8, 1.3, .4, 1.2, const Color(0xFFA06808));
    });
    rect(c, 4, 8, 1, 2, crabEye);
    rect(c, 10, 8, 1, 2, crabEye);
  });
}

// ---------- db: 端午 (dragon boat) ----------

void _drawDb(Canvas c, double t) {
  final zzBob = oscillate(t, 2.2, 0, -2);
  final zzRot = oscillate(t, 2.2, -6, 6);
  final boatBob = oscillate(t, 1.6, 0, -1);
  final boatRot = oscillate(t, 1.6, -1.5, 1.5);
  final rowAngle = oscillate(t, .7, -3, 3);
  final eyeBlink = (t % 1.4) > .59 && (t % 1.4) < .81;
  final armL = oscillate(t, .7, -48, 12);
  final armR = oscillate(t, .7, 48, -12);

  // floating zongzi (rice dumpling)
  withTransform(c, tx: -11, ty: -4 + zzBob, rotateDeg: zzRot, originX: -11, originY: -4, draw: () {
    _poly(c, const [
      Offset(-7.5, -4),
      Offset(-4.5, -2),
      Offset(-4.5, 3.5),
      Offset(-7.5, 5.5),
      Offset(-10.5, 3.5),
      Offset(-10.5, -2),
    ], const Color(0xFF2D7A2D));
    rect(c, -7.9, -5, .8, 2, const Color(0xFF8B5A2B));
    rect(c, -9.4, -2.8, 4, .6, const Color(0xFF8B5A2B));
    rect(c, -9.4, 0, 4, .4, const Color(0xFF1A5A1A), opacity: .6);
    rect(c, -9.4, 2.2, 4, .4, const Color(0xFF1A5A1A), opacity: .6);
  });

  withTransform(c, ty: boatBob, draw: () {
    withTransform(c, originX: 7.5, originY: 12, rotateDeg: boatRot, draw: () {
      rect(c, -6, 15, 42, 1.4, const Color(0xFF1A7A3A), opacity: .75);
      rect(c, -6, 15.5, 42, .6, const Color(0xFF4ECB7B), opacity: .38);
      _poly(c, const [Offset(-7, 11), Offset(-9, 14), Offset(-5, 14), Offset(17, 14), Offset(21, 14), Offset(19, 11)], const Color(0xFF7A3B12));
      rect(c, -6, 11, 24, 1.4, const Color(0xFF9A5424));
      rect(c, -6, 11, 24, .5, const Color(0xFFC8893F));
      // dragon head
      withTransform(c, tx: -13, ty: 7, draw: () {
        rrect(c, 0, 0, 5, 4, .4, const Color(0xFFCC2200));
        rect(c, 1, -2, .9, 2.2, const Color(0xFFCC2200));
        rect(c, 2.6, -2.4, .7, 1.8, const Color(0xFFCC2200));
        rrect(c, 3.6, .8, .9, .9, .2, const Color(0xFFFFD700));
        rect(c, 3.8, 1, .4, .4, Colors.black);
        rect(c, .3, 1.6, 3.5, .5, const Color(0xFFAA1800), opacity: .5);
      });
      // dragon tail
      withTransform(c, tx: 18, ty: 8, draw: () {
        _poly(c, const [Offset(0, 0), Offset(4, -1.5), Offset(3, 3), Offset(0, 3)], const Color(0xFFCC2200));
      });
      // oars
      withTransform(c, originX: -2, originY: 8, rotateDeg: armL * .1, draw: () {
        rect(c, -2, 8, .6, 6, const Color(0xFF8B5A2B));
        rrect(c, -3.2, 13, 2.6, 1.5, .2, const Color(0xFF1A5A8A));
      });
      withTransform(c, originX: 16.4, originY: 8, rotateDeg: armR * .1, draw: () {
        rect(c, 16.4, 8, .6, 6, const Color(0xFF8B5A2B));
        rrect(c, 16.6, 13, 2.6, 1.5, .2, const Color(0xFF1A5A8A));
      });
      withTransform(c, originX: 7.5, originY: 10, rotateDeg: rowAngle, draw: () {
        rect(c, 2, 4, 11, 2.4, const Color(0xFF1A7A3A));
        rect(c, 2, 5, 11, .7, const Color(0xFFFFD700), opacity: .7);
        rect(c, 13, 4, 2, 1, const Color(0xFF1A7A3A));
        rect(c, 14, 5, 1, 3, const Color(0xFF1A7A3A));
        rect(c, 2, 6, 11, 6, crabBody);
        withTransform(c, originX: 2, originY: 10, rotateDeg: armL, draw: () {
          rect(c, 0, 9, 2, 2, crabBody);
        });
        withTransform(c, originX: 13, originY: 10, rotateDeg: armR, draw: () {
          rect(c, 13, 9, 2, 2, crabBody);
        });
        final eyeH = eyeBlink ? .2 : 2.0;
        final eyeY = eyeBlink ? 8.9 : 8.0;
        rect(c, 4, eyeY, 1, eyeH, crabEye);
        rect(c, 10, eyeY, 1, eyeH, crabEye);
      });
    });
  });
}

// ---------- hw: 万圣节 (halloween) ----------

void _drawHw(Canvas c, double t) {
  final bodyBob = oscillate(t, 2.4, 0, -2);
  final bodyRot = oscillate(t, 2.4, -1, 1);
  final shadowScaleX = oscillate(t, 2.4, 1, .86);
  final shadowOpacity = oscillate(t, 2.4, .45, .3);
  final hatRot = oscillate(t, 2.4, 0, -5);
  final ghostF = (oscillate(t, 3, 0, 1));
  final ghostOpacity = .5 + .4 * ghostF;
  final ghostTx = 2 * ghostF;
  final ghostTy = -3 * ghostF;

  _bat(c, t, baseTx: 0, baseTy: -20, delay: 0, scale: 1);
  _bat(c, t, baseTx: 0, baseTy: -15, delay: -2, scale: .7);

  withTransform(c, tx: 18 + ghostTx, ty: -4 + ghostTy, draw: () {
    // ghost body, approximated as a rounded blob with a wavy hem
    rrect(c, 0, -4, 6, 7, 3, const Color(0xFFE8E8F0), opacity: ghostOpacity);
    rect(c, 0, 3, 6, 1.4, const Color(0xFFE8E8F0), opacity: ghostOpacity);
    rect(c, 1.6, -1.6, 1, 1.4, const Color(0xFF333333));
    rect(c, 3.6, -1.6, 1, 1.4, const Color(0xFF333333));
    oval(c, 3, 1.4, .7, 1, const Color(0xFF333333));
  });

  final pumpkin = const Color(0xFFE8731A);
  withTransform(c, tx: -13, ty: 9, draw: () {
    rect(c, 3, -2, 1, 1.5, const Color(0xFF3A7D2C));
    oval(c, 3.5, 3, 4, 3.4, pumpkin);
    oval(c, 1.6, 3, 1.4, 3.2, const Color(0xFFFF8C2E), opacity: .5);
    oval(c, 5.4, 3, 1.4, 3.2, const Color(0xFFC85E12), opacity: .5);
    _poly(c, const [Offset(1.5, 2), Offset(3, 2), Offset(2.2, 3.2)], const Color(0xFFFFD54F));
    _poly(c, const [Offset(5.5, 2), Offset(4, 2), Offset(4.8, 3.2)], const Color(0xFFFFD54F));
    _poly(c, const [Offset(2, 4.2), Offset(3, 5), Offset(4, 4.2), Offset(5, 5), Offset(2.5, 5.2)], const Color(0xFFFFD54F));
  });

  rect(c, 3, 15, 9, 1, Colors.black, opacity: shadowOpacity * shadowScaleX);

  withTransform(c, originX: 7.5, originY: 13, rotateDeg: bodyRot, ty: bodyBob, draw: () {
    rect(c, 3, 13, 1, 2, crabBody);
    rect(c, 5, 13, 1, 2, crabBody);
    rect(c, 9, 13, 1, 2, crabBody);
    rect(c, 11, 13, 1, 2, crabBody);
    withTransform(c, originX: 7.5, originY: 5.5, rotateDeg: hatRot, draw: () {
      final witch = const Color(0xFF3A1A5A);
      _poly(c, const [Offset(7.5, -2.5), Offset(5, 4.5), Offset(10, 4.5)], witch);
      rect(c, 2, 4.5, 11, 1.4, witch);
      rect(c, 5.6, 2.9, 3.5, 1.6, const Color(0xFFFFC107));
      rect(c, 6.4, 3.1, 1.8, 1.2, witch);
    });
    rect(c, 2, 6, 11, 7, crabBody);
    rect(c, 0, 9, 2, 2, crabBody);
    rect(c, 13, 9, 2, 2, crabBody);
    rect(c, 4, 8, 1, 2, const Color(0xFFFF7A00));
    rect(c, 10, 8, 1, 2, const Color(0xFFFF7A00));
  });
}

void _bat(Canvas c, double t, {required double baseTx, required double baseTy, required double delay, required double scale}) {
  final f = loopFraction(t, 4, delay: delay);
  double tx;
  if (f < .5) {
    tx = -16 + (36 * (f / .5));
  } else {
    tx = 20 - (36 * ((f - .5) / .5));
  }
  final ty = f < .5 ? -4 * (f / .5) : -4 * (1 - (f - .5) / .5);
  final flap = oscillate(t, .25, 1, .4);
  withTransform(c, tx: baseTx + tx, ty: baseTy + ty, scaleX: scale, scaleY: scale, draw: () {
    rrect(c, -.6, -.6, 1.2, 1.2, .3, const Color(0xFF1A1A1A));
    withTransform(c, scaleX: flap, draw: () {
      _poly(c, const [Offset(-.6, 0), Offset(-3, -1.2), Offset(-2.4, 1), Offset(-.6, .6)], const Color(0xFF1A1A1A));
      _poly(c, const [Offset(.6, 0), Offset(3, -1.2), Offset(2.4, 1), Offset(.6, .6)], const Color(0xFF1A1A1A));
    });
  });
}

final Map<String, EmoteDrawFn> ourHomeEmotesBatchC = {
  'hp': _drawHp,
  'ag': _drawAg,
  'dc': _drawDc,
  'sg': _drawSg,
  'et': _drawEt,
  'sh': _drawSh,
  'cf': _drawCf,
  'sp': _drawSp,
  'ma': _drawMa,
  'db': _drawDb,
  'hw': _drawHw,
};
