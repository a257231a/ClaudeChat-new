import 'dart:math' as math;

import 'package:flutter/material.dart'
    show
        Alignment,
        Canvas,
        Color,
        Colors,
        LinearGradient,
        Offset,
        Paint,
        Path,
        RadialGradient,
        Rect;

/// Renders the "away scene" backgrounds/props (shopping/adventure/outing),
/// ported from the standalone demo's canvas drawing code
/// (scratchpad/our-home-demo.html: `drawShop`/`drawAdventure`/`drawLibrary`/
/// `drawMystery`/`drawEscape`). Uses the room's own 256x192 logical
/// coordinate space directly (same as `_OurHomePainter.drawRoom` — 1:1 with
/// the JS source's numbers, no extra scaling), unlike the emote poses in
/// `our_home_emotes.dart` which use their own 2x-scaled SVG-unit space.
///
/// Pure Canvas + primitives only — no dependency on `OurHomeState`/
/// `LongActivity`. Callers pass in whatever per-visit state a scene needs
/// (e.g. the library's chosen table, the mystery's rolled seat count)
/// instead of this file inventing its own "pet" object.

const double _w = 256;
const double _h = 192;

/// One frame's result: where the pet's feet should be drawn, and an
/// optional foreground pass to run *after* the pet is drawn (so a prop —
/// e.g. the library table — can occlude the pet's lower body).
typedef SceneResult = ({double x, double y, void Function(Canvas)? fg});

const List<Color> _bookColors = [
  Color(0xFFE0A458),
  Color(0xFF4D8B6B),
  Color(0xFFC2544A),
  Color(0xFF8C6BB1),
  Color(0xFFE0A458),
];

void _rect(Canvas c, double x, double y, double w, double h, Color color) {
  c.drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
}

void _glow(Canvas c, double cx, double cy, double radius, Color color) {
  final paint = Paint()
    ..shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
  c.drawCircle(Offset(cx, cy), radius, paint);
}

void _verticalGradient(Canvas c, double height, Color top, Color bottom) {
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    ).createShader(Rect.fromLTWH(0, 0, _w, height));
  c.drawRect(Rect.fromLTWH(0, 0, _w, height), paint);
}

double _lerp(double a, double b, double f) => a + (b - a) * f.clamp(0, 1);

// ---------- shop ----------

const double shopFeetY = 168;

const List<Color> _shopProducts = [
  Color(0xFFE8946A),
  Color(0xFF5F9E6F),
  Color(0xFF4F7CA8),
  Color(0xFFE0A458),
  Color(0xFFC2544A),
  Color(0xFF8C6BB1),
];

SceneResult drawShopScene(Canvas c, double t) {
  _rect(c, 0, 0, _w, 114, const Color(0xFFDCE8F0));
  _rect(c, 0, 108, _w, 6, const Color(0xFFC7D6E0));
  _rect(c, 0, 114, _w, _h - 114, const Color(0xFFE8E8EC));
  for (double i = 0; i < _w; i += 16) {
    _rect(c, i, 114, 1, _h - 114, const Color(0xFFD2D2D8));
  }
  for (double j = 114; j < _h; j += 16) {
    _rect(c, 0, j, _w, 1, const Color(0xFFD2D2D8));
  }

  for (final sx in const [20.0, 96.0, 172.0]) {
    _rect(c, sx, 36, 48, 78, const Color(0xFF8A8A92));
    _rect(c, sx + 3, 40, 42, 70, const Color(0xFFC9C9D2));
    for (final sy in const [50.0, 68.0, 86.0, 102.0]) {
      _rect(c, sx + 3, sy, 42, 2, const Color(0xFF8A8A92));
      for (double px = sx + 5; px < sx + 40; px += 6) {
        _rect(
          c,
          px,
          sy - 8,
          4,
          8,
          _shopProducts[(px / 6).floor() % _shopProducts.length],
        );
      }
    }
  }

  _rect(c, 224, 132, 28, 32, const Color(0xFFC2693F));
  _rect(c, 224, 128, 28, 4, const Color(0xFFD6794D));
  _rect(c, 230, 120, 10, 10, const Color(0xFF3A3A42));
  _rect(c, 232, 122, 6, 4, const Color(0xFF8FD6FF));

  final wx = 128 + math.sin(t * 0.5) * 76;
  // cart sits beside the pet (not underneath it) so it's actually visible
  final cartX = wx - 20;
  _rect(c, cartX, shopFeetY - 16, 1, 16, const Color(0xFFAAB3BA));
  _rect(c, cartX - 2, shopFeetY - 18, 7, 2, const Color(0xFFAAB3BA));
  _rect(c, cartX - 1, shopFeetY - 14, 17, 9, const Color(0xFFCFD6DC));
  _rect(c, cartX - 1, shopFeetY - 14, 17, 2, const Color(0xFFAAB3BA));
  _rect(c, cartX - 1, shopFeetY - 4, 2, 2, const Color(0xFF3A3A42));
  _rect(c, cartX + 14, shopFeetY - 4, 2, 2, const Color(0xFF3A3A42));

  return (x: wx, y: shopFeetY, fg: null);
}

// ---------- adventure ----------

const double adventureFeetY = 90;

// Hand-placed so the ring reads as irregular village/forest clusters with
// gaps between them, rather than a perfectly even repeating pattern.
const List<(double angle, bool house)> _advDecos = [
  (0.15, false), (0.32, false), (0.48, true),
  (0.78, false), (0.98, false), (1.14, false),
  (1.5, true), (1.64, true), (1.8, false),
  (2.25, false), (2.4, false), (2.56, false),
  (2.95, true), (3.35, false), (3.5, false),
  (3.95, false), (4.25, true), (4.4, false),
  (4.85, false), (5.05, false), (5.3, false),
  (5.72, true), (5.88, false),
];

const List<(double speed, double y, double scale, double offset)> _advClouds =
    [(6, 24, 1, 0), (4, 42, .7, 90), (5, 16, .55, 180)];

SceneResult drawAdventureScene(Canvas c, double t) {
  _verticalGradient(c, 120, const Color(0xFF7FC7E8), const Color(0xFFCFE8F0));

  c.drawCircle(const Offset(210, 26), 11, Paint()..color = const Color(0xFFFFE58A));

  final cloudPaint = Paint()..color = Colors.white.withValues(alpha: .88);
  for (final cloud in _advClouds) {
    final ccx = ((t * cloud.$1 + cloud.$4) % (_w + 40)) - 20;
    final cy = cloud.$2;
    final sc = cloud.$3;
    final path = Path()
      ..addOval(
        Rect.fromCenter(center: Offset(ccx, cy), width: 20 * sc, height: 10 * sc),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(ccx + 8 * sc, cy - 2 * sc),
          width: 14 * sc,
          height: 8 * sc,
        ),
      )
      ..addOval(
        Rect.fromCenter(
          center: Offset(ccx - 7 * sc, cy - 1 * sc),
          width: 12 * sc,
          height: 8 * sc,
        ),
      );
    c.drawPath(path, cloudPaint);
  }

  const cx = 128.0, cy = 330.0, r = 240.0;
  final rot = t * 0.25;
  c.drawCircle(const Offset(cx, cy), r, Paint()..color = const Color(0xFF5FA85F));

  for (var k = 0; k < 18; k++) {
    final ga = k * (2 * math.pi / 18) - rot - math.pi / 2;
    final gx = cx + math.cos(ga) * r;
    final gy = cy + math.sin(ga) * r;
    if (gy > 55 && gy < 112) {
      _rect(c, gx - 4, gy - 2, 8, 2, const Color(0xFF4F8F52));
    }
  }

  for (final deco in _advDecos) {
    final ang = deco.$1 - rot - math.pi / 2;
    final dx = cx + math.cos(ang) * r;
    final dy = cy + math.sin(ang) * r;
    if (dy < -8 || dy > 108) continue;
    if (deco.$2) {
      _rect(c, dx - 6, dy - 12, 12, 12, const Color(0xFFC2A06A));
      final roof = Path()
        ..moveTo(dx - 7, dy - 12)
        ..lineTo(dx, dy - 20)
        ..lineTo(dx + 7, dy - 12)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFFA85C3B));
    } else {
      _rect(c, dx - 1, dy - 10, 2, 10, const Color(0xFF6B4226));
      _rect(c, dx - 5, dy - 22, 10, 14, const Color(0xFF3F8A4A));
    }
  }

  return (x: 128, y: adventureFeetY, fg: null);
}

// ---------- outing: library ----------

const double outFeetY = 168;
const List<double> libraryTables = [60, 128, 196];
const double libraryShelfX = 80;

void _libraryTableShape(Canvas c, double tx) {
  // a noticeably lighter wood tone than the floor, so it doesn't blend in
  _rect(c, tx - 14, 150, 28, 8, const Color(0xFFC9905A));
  _rect(c, tx - 14, 150, 28, 2, const Color(0xFFE0B077));
  _rect(c, tx - 10, 158, 4, 14, const Color(0xFF6B4226));
  _rect(c, tx + 6, 158, 4, 14, const Color(0xFF6B4226));
  _rect(c, tx - 10, 146, 8, 4, const Color(0xFF5A3A22));
}

/// [awayStart] is when this trip started (same time-base as [t]) — drives
/// the walk-to-shelf / walk-to-table / seated phases. [tableX] is which of
/// [libraryTables] this visit picked (choose it once per trip and keep
/// passing the same value every frame).
SceneResult drawLibraryScene(
  Canvas c,
  double t, {
  required double awayStart,
  required double tableX,
}) {
  _rect(c, 0, 0, _w, 114, const Color(0xFFE7DCC8));
  _rect(c, 0, 108, _w, 6, const Color(0xFFD8C9A8));
  _rect(c, 0, 114, _w, _h - 114, const Color(0xFF8A5A3B));
  for (double i = 0; i < _w; i += 16) {
    _rect(c, i, 114, 1, _h - 114, const Color(0xFF754A2F));
  }

  for (final sx in const [8.0, 150.0, 214.0]) {
    _rect(c, sx, 18, 40, 96, const Color(0xFF5A3A22));
    _rect(c, sx + 3, 22, 34, 88, const Color(0xFF3F2A18));
    for (final sy in const [32.0, 50.0, 68.0, 86.0, 100.0]) {
      for (double bx = sx + 5; bx < sx + 34; bx += 4) {
        _rect(c, bx, sy - 8, 3, 8, _bookColors[(bx / 4).floor() % _bookColors.length]);
      }
    }
  }
  _rect(c, libraryShelfX - 24, 18, 48, 96, const Color(0xFF5A3A22));
  _rect(c, libraryShelfX - 20, 22, 40, 88, const Color(0xFF3F2A18));
  for (final sy in const [32.0, 50.0, 68.0, 86.0, 100.0]) {
    for (double bx = libraryShelfX - 18; bx < libraryShelfX + 18; bx += 4) {
      _rect(c, bx, sy - 8, 3, 8, _bookColors[(bx / 4).floor() % _bookColors.length]);
    }
  }

  for (final tx in libraryTables) {
    _libraryTableShape(c, tx);
  }

  final since = t - awayStart;
  double px;
  if (since < 3) {
    px = _lerp(30, libraryShelfX, since / 3);
  } else if (since < 5) {
    px = libraryShelfX;
  } else if (since < 8) {
    px = _lerp(libraryShelfX, tableX, (since - 5) / 3);
  } else {
    // seated: lift feetY so the crab's head/claws clear the tabletop edge
    // (y150), then re-draw the table's front + the open book as an "fg"
    // pass after the crab so the table hides the lower body/legs and only
    // the head pokes out above it.
    px = tableX;
    return (
      x: px,
      y: 158,
      fg: (fgCanvas) {
        _libraryTableShape(fgCanvas, px);
        _rect(fgCanvas, px - 6, 148, 12, 4, const Color(0xFFFBF3E3));
        _rect(fgCanvas, px - 5, 149, 4, .8, const Color(0xFFC9B48A));
        _rect(fgCanvas, px + 1, 149, 4, .8, const Color(0xFFC9B48A));
      },
    );
  }
  return (x: px, y: outFeetY, fg: null);
}

// ---------- outing: murder mystery ----------

const List<(double, double)> _mysterySeats = [
  (50, 120),
  (50, 145),
  (206, 120),
  (206, 145),
];

/// [mysteryShowed] is 0-3 (how many of the other 4 seats are filled) —
/// rolled once when the trip starts (`OurHomeState.rollMysteryShowed()`)
/// and passed in unchanged every frame.
SceneResult drawMysteryScene(Canvas c, double t, {required int mysteryShowed}) {
  _verticalGradient(c, _h, const Color(0xFF2E1830), const Color(0xFF1A0E1C));

  for (final p in const [(70.0, 20.0), (186.0, 20.0)]) {
    _rect(c, p.$1, p.$2, 26, 20, const Color(0xFF4A2C1A));
    _rect(c, p.$1 + 3, p.$2 + 3, 20, 14, const Color(0xFF6B4A3A));
  }
  for (final p in const [(40.0, 50.0), (216.0, 50.0)]) {
    _rect(c, p.$1, p.$2, 3, 14, const Color(0xFF8A8F99));
    _glow(
      c,
      p.$1 + 1,
      p.$2 - 4,
      10 + math.sin(t * 6) * 2,
      const Color(0xFFFFB45A).withValues(alpha: .4),
    );
    _rect(c, p.$1 - 1, p.$2 - 8, 5, 6, const Color(0xFFFFB454));
  }

  c.drawOval(
    Rect.fromCenter(center: const Offset(128, 132), width: 144, height: 52),
    Paint()..color = const Color(0xFF6B4226),
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(128, 130), width: 128, height: 42),
    Paint()..color = const Color(0xFF8A5A3B),
  );
  _rect(c, 118, 122, 20, 14, const Color(0xFFFBF3E3));
  _rect(c, 122, 140, 6, 6, const Color(0xFFE8394A));

  _rect(c, 120, 84, 16, 14, const Color(0xFFDE886D));
  _rect(c, 124, 80, 2, 4, Colors.black);
  _rect(c, 130, 80, 2, 4, Colors.black);
  _rect(c, 110, 88, 44, 4, const Color(0xFF2B2438));

  for (var i = 0; i < _mysterySeats.length; i++) {
    final s = _mysterySeats[i];
    if (i < mysteryShowed) {
      _rect(c, s.$1, s.$2, 10, 8, const Color(0xFFDE886D));
      _rect(c, s.$1 + 2, s.$2 - 3, 6, 6, const Color(0xFFDE886D));
      _rect(c, s.$1 + 3, s.$2 - 1, 1, 2, Colors.black);
      _rect(c, s.$1 + 6, s.$2 - 1, 1, 2, Colors.black);
    } else {
      _rect(c, s.$1 + 2, s.$2, 6, 10, const Color(0xFF3A2A1A));
    }
  }

  return (x: 136, y: 118, fg: null);
}

// ---------- outing: escape room ----------

const List<(double, double, String)> _escapeProps = [
  (30, 100, 'pumpkin'),
  (210, 96, 'pumpkin'),
  (70, 104, 'skull'),
  (170, 102, 'skull'),
];

SceneResult drawEscapeScene(Canvas c, double t) {
  // Halloween-style deep purple (same family as the witch hat's #3A1A5A in
  // the ported "hw" emote), not near-black — was reading as plain black.
  _verticalGradient(c, _h, const Color(0xFF3A1A5A), const Color(0xFF20103A));
  _rect(c, 0, _h - 6, _w, 6, const Color(0xFF180A2C));

  for (final p in _escapeProps) {
    final x = p.$1, y = p.$2;
    if (p.$3 == 'pumpkin') {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 18, height: 14),
        Paint()..color = const Color(0xFFC2691F),
      );
      _rect(c, x - 1, y - 10, 2, 3, const Color(0xFF3A7D2C));
      final facePaint = Paint()..color = const Color(0xFFFFD54F);
      c.drawRect(Rect.fromLTWH(x - 4, y - 2, 2, 3), facePaint);
      c.drawRect(Rect.fromLTWH(x + 2, y - 2, 2, 3), facePaint);
      c.drawRect(Rect.fromLTWH(x - 3, y + 2, 6, 2), facePaint);
    } else {
      _rect(c, x - 4, y - 6, 8, 8, const Color(0xFFE8E4D8));
      _rect(c, x - 3, y - 3, 2, 2, Colors.black);
      _rect(c, x + 1, y - 3, 2, 2, Colors.black);
    }
  }

  // occasional jump-scare NPC — same visual language as the ported "hw"
  // (Halloween) emote's ghost, drawn directly on canvas since the overlay
  // system is tied to the main pet, not a second roaming actor
  const cycleLen = 6.0;
  final cycleIndex = (t / cycleLen).floor();
  final cycleT = t % cycleLen;
  if (cycleT < 1.5) {
    final rx = 30.0 + (cycleIndex * 67) % 190;
    final ry = 55.0 + (cycleIndex * 41) % 35;
    final a = cycleT < 0.3
        ? cycleT / 0.3
        : (cycleT > 1.2 ? (1.5 - cycleT) / 0.3 : 1.0);
    final ghostPaint = Paint()..color = const Color(0xFFE8E8F0).withValues(alpha: a);
    final ghost = Path()
      ..moveTo(rx, ry)
      ..lineTo(rx, ry - 10)
      ..quadraticBezierTo(rx, ry - 16, rx + 6, ry - 16)
      ..quadraticBezierTo(rx + 12, ry - 16, rx + 12, ry - 10)
      ..lineTo(rx + 12, ry)
      ..lineTo(rx + 9, ry - 3)
      ..lineTo(rx + 6, ry)
      ..lineTo(rx + 3, ry - 3)
      ..close();
    c.drawPath(ghost, ghostPaint);
    final eyePaint = Paint()..color = const Color(0xFF333333).withValues(alpha: a);
    c.drawRect(Rect.fromLTWH(rx + 3, ry - 13, 2, 3), eyePaint);
    c.drawRect(Rect.fromLTWH(rx + 7, ry - 13, 2, 3), eyePaint);
  }

  return (x: 128 + math.sin(t * 0.3) * 30, y: outFeetY, fg: null);
}

// ---------- outing: street ----------

const double streetFeetY = 168;

const List<Color> _streetSnacks = [
  Color(0xFFE8946A),
  Color(0xFFE0A458),
  Color(0xFFC2544A),
];

/// A generic "went out for a bit of fun" city-street scene — a mall
/// storefront, a snack stall, and a park swing, with the pet strolling back
/// and forth along the sidewalk. This is what the random/generic outing
/// pick (and the explicit "去逛街" command) shows — kept distinct from the
/// literal reading-room [drawLibraryScene], since most rows in
/// docs/OUR_HOME_ECONOMY.md's 外出娱乐结果清单 (公园散步/荡秋千/逛集市/坐
/// 摩天轮…) read as an outdoor city outing, not "sat down and read a book".
SceneResult drawStreetScene(Canvas c, double t) {
  _verticalGradient(c, 90, const Color(0xFF9FD2EE), const Color(0xFFD9EEF6));
  c.drawCircle(const Offset(226, 20), 10, Paint()..color = const Color(0xFFFFE58A));

  // mall storefront, background right
  _rect(c, 150, 34, 96, 56, const Color(0xFFC7CDD6));
  _rect(c, 150, 34, 96, 8, const Color(0xFFE85C74));
  for (final wx in const [162.0, 182.0, 202.0, 222.0]) {
    _rect(c, wx, 50, 10, 12, const Color(0xFF7FA8C9));
    _rect(c, wx, 68, 10, 12, const Color(0xFF7FA8C9));
  }
  _rect(c, 186, 78, 24, 12, const Color(0xFF5A3A22));

  // sidewalk / street, with a thin curb-side grass strip
  _rect(c, 0, 90, _w, 4, const Color(0xFF6FAE5E));
  _rect(c, 0, 94, _w, _h - 94, const Color(0xFFBFC0C8));
  for (double i = 4; i < _w; i += 26) {
    _rect(c, i, 128, 16, 2, const Color(0xFFA7A8B2));
  }

  // swing set, left
  const swingTopX = 26.0, swingTopY = 46.0;
  _rect(c, swingTopX - 20, swingTopY, 3, 40, const Color(0xFF8A8A92));
  _rect(c, swingTopX + 20, swingTopY, 3, 40, const Color(0xFF8A8A92));
  _rect(c, swingTopX - 20, swingTopY - 3, 43, 3, const Color(0xFF8A8A92));
  final sway = math.sin(t * 1.6) * 8;
  final seatX = swingTopX + sway;
  final ropePaint = Paint()
    ..color = const Color(0xFF6B6B74)
    ..strokeWidth = 1;
  c.drawLine(
    Offset(swingTopX - 6, swingTopY),
    Offset(seatX - 4, swingTopY + 34),
    ropePaint,
  );
  c.drawLine(
    Offset(swingTopX + 6, swingTopY),
    Offset(seatX + 4, swingTopY + 34),
    ropePaint,
  );
  _rect(c, seatX - 6, swingTopY + 34, 12, 3, const Color(0xFFC2693F));

  // snack stall, center
  const stallX = 110.0;
  _rect(c, stallX - 4, 52, 48, 8, const Color(0xFFE85C74));
  _rect(c, stallX - 4, 60, 48, 4, const Color(0xFFF6889A));
  _rect(c, stallX, 66, 40, 22, const Color(0xFFE7DCC8));
  _rect(c, stallX, 66, 40, 3, const Color(0xFFC9905A));
  for (var i = 0; i < _streetSnacks.length; i++) {
    _rect(c, stallX + 6 + i * 12, 70, 8, 6, _streetSnacks[i]);
  }

  final wx = 128 + math.sin(t * 0.4) * 90;
  return (x: wx, y: streetFeetY, fg: null);
}

// ---------- work: office ----------

const double officeFeetY = 168;

/// A dedicated office scene for real work sessions — the desk/monitor/
/// chair are the same look the home room used to draw at its own desk
/// corner (moved here wholesale, per an explicit "工位应该在外面，不是在
/// 家里" ask), now with an office backdrop (window w/ blinds, a filing
/// cabinet, a potted plant) instead of living-room furniture around it.
/// The pet sits still here the whole session (no wander), so this always
/// returns the same fixed anchor.
SceneResult drawOfficeScene(Canvas c, double t) {
  _verticalGradient(c, 114, const Color(0xFFDCD3C4), const Color(0xFFCFC3AF));
  _rect(c, 0, 108, _w, 6, const Color(0xFFBBAD96));
  _rect(c, 0, 114, _w, _h - 114, const Color(0xFFA9998A));
  for (double i = 0; i < _w; i += 16) {
    _rect(c, i, 114, 1, _h - 114, const Color(0xFF988873));
  }

  // window with blinds, left
  _rect(c, 14, 22, 56, 46, const Color(0xFF8FBEDD));
  _rect(c, 12, 20, 60, 4, const Color(0xFF6B5A42));
  _rect(c, 12, 20, 4, 50, const Color(0xFF6B5A42));
  _rect(c, 68, 20, 4, 50, const Color(0xFF6B5A42));
  for (double by = 28; by < 66; by += 7) {
    _rect(c, 14, by, 56, 2, const Color(0x33334455));
  }

  // filing cabinet, right
  _rect(c, 206, 58, 34, 56, const Color(0xFF8A8F99));
  _rect(c, 210, 66, 26, 3, const Color(0xFF6E7480));
  _rect(c, 210, 82, 26, 3, const Color(0xFF6E7480));
  _rect(c, 210, 98, 26, 3, const Color(0xFF6E7480));
  _rect(c, 228, 68, 4, 2, const Color(0xFF4B5058));
  _rect(c, 228, 84, 4, 2, const Color(0xFF4B5058));
  _rect(c, 228, 100, 4, 2, const Color(0xFF4B5058));

  // potted plant, far right corner
  _rect(c, 240, 96, 4, 16, const Color(0xFF5A6B3C));
  _rect(c, 236, 88, 4, 12, const Color(0xFF5A6B3C));
  _rect(c, 244, 90, 4, 12, const Color(0xFF5A6B3C));
  _rect(c, 236, 108, 14, 10, const Color(0xFFC2693F));

  // desk + monitor + chair — same look the room's desk corner used to be
  const deskX = 92.0;
  _rect(c, deskX, 132, 84, 10, const Color(0xFF9C6A45));
  _rect(c, deskX, 142, 8, 34, const Color(0xFF754A2F));
  _rect(c, deskX + 76, 142, 8, 34, const Color(0xFF754A2F));
  _rect(c, deskX + 4, 122, 54, 10, const Color(0xFFFBF3E3));
  _rect(c, deskX + 7, 124, 48, 1.5, const Color(0xFFD8C9AD));
  _rect(c, deskX + 7, 128, 48, 1.5, const Color(0xFFD8C9AD));
  _rect(c, deskX + 14, 88, 60, 38, const Color(0xFF2B2438));
  _rect(c, deskX + 19, 92, 50, 28, const Color(0xFF8FD6FF));
  _glow(c, deskX + 44, 106, 24, const Color(0xFF8FD6FF).withValues(alpha: .25));
  _rect(c, deskX + 40, 126, 8, 6, const Color(0xFF754A2F));
  _rect(c, deskX + 24, 148, 24, 4, const Color(0xFF6B4226));

  return (x: deskX + 32, y: officeFeetY, fg: null);
}
