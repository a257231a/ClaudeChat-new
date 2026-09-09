import 'dart:async';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'our_home_actions.dart';
import 'our_home_state.dart';

/// Tracks whether *the user* has had ClaudeChat itself closed for a real
/// stretch of time — a deliberately separate concern from
/// [OurHomeState]/`OurHomeSimulationService`: the pet's own headless
/// ticking only ever runs while the app process is alive, so it has
/// nothing to say about whether a human is actually looking at the app
/// right now. This owns its own tiny persisted timestamp under a dedicated
/// prefs key (not part of [OurHomeState]'s save blob), precisely so this
/// concern never has to be woven into the pet's simulation/economy code.
///
/// Wired in via `OurHomeSimulationService`'s two generic cold-start hooks
/// (`onBeforeColdStartLoad`/`onAfterColdStartLoad`) from
/// `AppController.bootstrap()`: [recordDepartureIfAway] runs first (before
/// anything else appends to the log this process, so "user left" stays the
/// oldest new entry) and [recordArrivalIfWasAway] runs last (so "user came
/// back" stays the newest) — plus [touch], called from the app's lifecycle
/// observer whenever it backgrounds, so the timestamp reflects the last
/// real moment the user was here rather than a stale one.
class OurHomePresenceService {
  OurHomePresenceService({math.Random? random})
    : _random = random ?? math.Random();

  static const _prefsKey = 'our_home_presence_last_active_v1';
  static const awayNarrationThreshold = Duration(minutes: 5);

  final math.Random _random;
  bool _pendingArrival = false;

  /// Refreshes the "user was just here" timestamp — call from the app's
  /// lifecycle observer on backgrounding (`AppLifecycleState.paused`).
  Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Cold-start check #1 — call before anything else touches [home]'s log
  /// this process. If the persisted "last seen" timestamp is far enough in
  /// the past, appends the departure system row + pet bubble (both stamped
  /// at that past moment) and remembers to also narrate the arrival once
  /// [recordArrivalIfWasAway] runs.
  Future<void> recordDepartureIfAway(
    OurHomeState home, {
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_prefsKey);
    final last = raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
    final wasAway =
        last != null &&
        DateTime.now().difference(last) >= awayNarrationThreshold;
    if (!wasAway) return;
    _pendingArrival = true;
    home.fullLog.add(
      LogEntry(time: last, text: awayDepartureNote(accountName, home.title)),
    );
    home.fullLog.add(
      LogEntry(
        time: last,
        text: departureSpeech(_random),
        messageType: LogMessageType.bubble,
        source: LogSource.pet,
      ),
    );
  }

  /// Cold-start check #2 — call after everything else this process is
  /// going to do to [home] on load. Appends the arrival row + bubble
  /// (stamped "now") only if [recordDepartureIfAway] found a real gap, then
  /// always refreshes the persisted timestamp.
  Future<void> recordArrivalIfWasAway(
    OurHomeState home, {
    required String accountName,
  }) async {
    if (_pendingArrival) {
      _pendingArrival = false;
      final now = DateTime.now();
      home.fullLog.add(
        LogEntry(time: now, text: awayArrivalNote(accountName, home.title)),
      );
      home.fullLog.add(
        LogEntry(
          time: now,
          text: arrivalSpeech(_random),
          messageType: LogMessageType.bubble,
          source: LogSource.pet,
        ),
      );
    }
    await touch();
  }
}
