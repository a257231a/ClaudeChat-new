import 'dart:async';
import 'dart:math' as math;

import 'economy_data.dart';
import 'our_home_actions.dart';
import 'our_home_state.dart';

/// Keeps "我们的家"'s autonomous simulation (idle decisions, work/travel
/// settlement, mood upkeep) advancing for as long as the app process is
/// alive — not just while the 我们的家 page happens to be the visible
/// section. Owned by `AppController` (app-session lifetime), so switching
/// to Chat/Workspaces/等 no longer pauses the pet's own life.
///
/// The 我们的家 page itself still owns the *visual* layer (walk animations,
/// chat bubbles, emote overlays): while it's mounted it calls
/// [acquireForPage] and drives the same shared [state] directly through its
/// own richer, animated ticking loop, and this service's plain headless
/// tick stands down (see [_pausedForPage]) so state is only ever advanced
/// from one place at a time — never both, which would double-apply
/// mood/coin changes.
///
/// The headless tick deliberately skips anything purely cosmetic (ambient
/// wander position, walk-to-door/desk animations, festival-replay chance,
/// spoken bubbles) — nothing is on screen to show it, so only the actual
/// economy-relevant state transitions (settlement, autonomous choice,
/// log entries) run here. Existing action/settlement text is written
/// straight to [OurHomeState.fullLog], which the page already knows how to
/// display (as plain log rows) whenever it's next opened — the same path
/// already used to reconcile time that passed while the app was fully
/// closed.
class OurHomeSimulationService {
  OurHomeSimulationService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  OurHomeState? _state;
  Timer? _timer;
  Future<OurHomeState>? _loading;
  int _workStreak = 0;
  double _idleTimer = 3;
  DateTime? _lastTick;
  bool _pausedForPage = false;

  static const _tickInterval = Duration(seconds: 5);

  /// The shared, always-up-to-date state once loaded — null until [start]
  /// or [acquireForPage] has completed at least once.
  OurHomeState? get state => _state;

  Future<OurHomeState> _ensureLoaded() {
    final existing = _state;
    if (existing != null) return Future.value(existing);
    return _loading ??= _load();
  }

  Future<OurHomeState> _load() async {
    final data = await OurHomeEconomyData.load();
    final home = await OurHomeState.load(data);
    final settled = home.resolvePendingLongActivity();
    if (settled != null) {
      home.fullLog.add(LogEntry(time: DateTime.now(), text: settled.summary));
      await home.save();
    }
    _state = home;
    return home;
  }

  /// Starts the app-lifetime headless ticker. Call once, from
  /// `AppController.bootstrap()` — safe to call multiple times (a no-op
  /// after the first).
  Future<void> start() async {
    await _ensureLoaded();
    _timer ??= Timer.periodic(_tickInterval, (_) => unawaited(_tick()));
  }

  /// Called by the 我们的家 page when it becomes the visible section — hands
  /// ticking authority to the page's own richer loop and returns the shared
  /// state for it to drive directly (never load a separate copy).
  Future<OurHomeState> acquireForPage() {
    _pausedForPage = true;
    return _ensureLoaded();
  }

  /// Called by the 我们的家 page when it's no longer the visible section —
  /// resumes this service's own headless ticking of the same shared state.
  void releaseFromPage() {
    _pausedForPage = false;
    _lastTick = null; // avoid one big dt jump counted against the paused span
  }

  Future<void> _tick() async {
    if (_pausedForPage) return;
    final home = _state;
    if (home == null) return;
    final now = DateTime.now();
    final dt = _lastTick == null
        ? _tickInterval.inMilliseconds / 1000
        : now.difference(_lastTick!).inMilliseconds / 1000;
    _lastTick = now;

    if (home.isWorking) {
      final summary = home.tickWork(now);
      if (summary != null) {
        home.fullLog.add(LogEntry(time: now, text: summary));
        await home.save();
      }
      return;
    }
    final activity = home.longActivity;
    if (activity != null) {
      if (!now.isBefore(activity.endsAt)) {
        final result = home.resolvePendingLongActivity(now);
        if (result != null) {
          home.fullLog.add(LogEntry(time: now, text: result.summary));
          await home.save();
        }
      }
      return; // still en route / away either way — no autonomous decision
    }

    _idleTimer -= dt;
    if (_idleTimer > 0) return;
    _idleTimer = 3 + _random.nextDouble() * 4;
    final choice = pickAutonomousChoice(home, _workStreak, _random);
    if (choice != 'work') _workStreak = 0;
    switch (choice) {
      case 'wander':
        return; // purely cosmetic, nothing to simulate headlessly
      case 'hobby':
        final pick = autonomousHobbyPool[_random.nextInt(autonomousHobbyPool.length)];
        home.fullLog.add(LogEntry(time: now, text: pick.$2));
        await home.save();
      case 'work':
        _workStreak++;
        final result = await performOurHomeAction(home, 'work');
        home.fullLog.add(LogEntry(time: now, text: result.summary));
        await home.save();
      case 'meal':
        final wantsCook = preferCookingForMeal(home, _random);
        final result = await performOurHomeAction(
          home,
          wantsCook ? 'cook' : 'eat',
        );
        home.fullLog.add(LogEntry(time: now, text: result.summary));
        await home.save();
      default:
        final result = await performOurHomeAction(home, choice);
        home.fullLog.add(LogEntry(time: now, text: result.summary));
        await home.save();
    }
  }
}
