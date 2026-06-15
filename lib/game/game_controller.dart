import 'dart:async';
import 'package:flutter/foundation.dart';

/// How a game finished.
enum GameResult { win, lose }

/// All game state + rules live here. The UI ([GameScreen] and its widgets)
/// only reads these fields and calls [tapBoo] / [tapBox]; it never owns rules.
///
/// Extends [ChangeNotifier] so widgets can rebuild via a `ListenableBuilder`.
class GameController extends ChangeNotifier {
  // ---- Tunable config ----
  static const int gameDurationSeconds = 90;
  static const int maxBoos = 4;
  static const int sealPerTapPercent = 5; // 20 box taps => 100%
  static const int comboThreshold = 5; // boo taps in a row to trigger x2
  static const int spawnEverySeconds = 15; // spawn an extra boo on this cadence
  static const int basePointsPerBoo = 10;

  // ---- Live state (read by widgets) ----
  int score = 0;
  int timeLeft = gameDurationSeconds; // seconds remaining
  int sealPercent = 0; // 0..100
  int booCount = 1; // boos currently on screen (1..maxBoos)
  int multiplier = 1; // 1 or 2
  bool showCombo = false; // true briefly when x2 activates -> banner
  bool isRunning = false;
  GameResult? result; // null while playing; set once when the game ends

  int _comboCount = 0; // consecutive boo taps without a "miss" (box tap)
  Timer? _gameTimer;
  Timer? _comboBannerTimer;

  // ---- Convenience getters ----
  /// 0.0 .. 1.0 — drives the seal progress bar fill.
  double get sealProgress => (sealPercent / 100.0).clamp(0.0, 1.0);
  bool get isOver => result != null;
  bool get isWin => result == GameResult.win;

  /// (Re)start a fresh game. Safe to call again to replay.
  void start() {
    _gameTimer?.cancel();
    _comboBannerTimer?.cancel();
    score = 0;
    timeLeft = gameDurationSeconds;
    sealPercent = 0;
    booCount = 1;
    multiplier = 1;
    _comboCount = 0;
    showCombo = false;
    result = null;
    isRunning = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  /// One second elapsed: count down, maybe spawn a boo, maybe lose.
  void _tick() {
    if (!isRunning) return;
    timeLeft--;
    final elapsed = gameDurationSeconds - timeLeft;
    // Every [spawnEverySeconds] seconds an extra Boo joins (capped at maxBoos).
    if (elapsed > 0 &&
        elapsed % spawnEverySeconds == 0 &&
        booCount < maxBoos) {
      booCount++;
    }
    if (timeLeft <= 0) {
      timeLeft = 0;
      _endGame(GameResult.lose);
      return;
    }
    notifyListeners();
  }

  /// Player tapped a Boo: award points (x multiplier) and extend the combo.
  void tapBoo() {
    if (!isRunning) return;
    score += basePointsPerBoo * multiplier;
    _comboCount++;
    // 5 boo taps in a row without "missing" -> activate the x2 multiplier.
    if (_comboCount >= comboThreshold && multiplier == 1) {
      multiplier = 2;
      _flashCombo();
    }
    notifyListeners();
  }

  /// Player tapped the box: advance the seal. A box tap breaks the boo streak,
  /// so it resets the combo (and any active x2) — a little risk/reward tension.
  void tapBox() {
    if (!isRunning) return;
    _comboCount = 0;
    multiplier = 1;
    sealPercent = (sealPercent + sealPerTapPercent).clamp(0, 100);
    if (sealPercent >= 100) {
      sealPercent = 100;
      _endGame(GameResult.win);
      return;
    }
    notifyListeners();
  }

  /// Pause the countdown (e.g. app backgrounded) without losing progress.
  void pause() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Resume a paused, in-progress game. No-op if the game is over or already
  /// ticking (so it never resets state or double-starts the timer).
  void resume() {
    if (!isRunning || isOver || _gameTimer != null) return;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _flashCombo() {
    showCombo = true;
    _comboBannerTimer?.cancel();
    _comboBannerTimer = Timer(const Duration(milliseconds: 1500), () {
      showCombo = false;
      notifyListeners();
    });
  }

  void _endGame(GameResult r) {
    if (result != null) return; // ignore double-finish
    result = r;
    isRunning = false;
    _gameTimer?.cancel();
    _gameTimer = null;
    // Don't let a pending combo banner fire (and notify) after game-over.
    _comboBannerTimer?.cancel();
    showCombo = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _comboBannerTimer?.cancel();
    super.dispose();
  }
}
