import 'package:flutter/foundation.dart';
import 'models.dart';
import 'db_helper.dart';

class ReviewProvider extends ChangeNotifier {
  List<Word> _queue = [];
  int _currentIndex = 0;
  bool _finished = false;

  List<Word> get queue => _queue;
  int get currentIndex => _currentIndex;
  Word? get currentWord =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;
  bool get finished => _finished;
  int get remaining => _queue.length - _currentIndex;
  int get total => _queue.length;

  int _correctCount = 0;
  int _fuzzyCount = 0;
  int _forgotCount = 0;

  int get correctCount => _correctCount;
  int get fuzzyCount => _fuzzyCount;
  int get forgotCount => _forgotCount;

  /// 今天凌晨 4:00 的时间戳(ms)
  static int get today4am {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day, 4);
    return d.millisecondsSinceEpoch;
  }

  /// 今天4点 + N天的凌晨4点时间戳
  static int _nextDays4am(int days) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day, 4);
    return d.add(Duration(days: days)).millisecondsSinceEpoch;
  }

  Future<void> loadReviewQueue() async {
    final now4am = today4am;

    final allWords = await DbHelper.getWords();

    _queue = [];
    _currentIndex = 0;
    _finished = false;
    _correctCount = 0;
    _fuzzyCount = 0;
    _forgotCount = 0;

    for (final word in allWords) {
      final latest = await DbHelper.getLatestReviewForWord(word.id);
      if (latest == null || latest.nextReview <= now4am) {
        _queue.add(word);
      }
    }

    _queue.sort((a, b) => a.masteryLevel.compareTo(b.masteryLevel));

    notifyListeners();
  }

  /// result: 0=忘记, 1=模糊, 2=记得
  Future<void> rateWord(int result) async {
    if (currentWord == null) return;

    final word = currentWord!;
    final latest = await DbHelper.getLatestReviewForWord(word.id);

    final (nextReview, repetition, efactor, masteryLevel) =
        _sm2(latest, result);

    final record = ReviewRecord(
      wordId: word.id,
      result: result,
      nextReview: nextReview,
      repetition: repetition,
      efactor: efactor,
    );
    await DbHelper.insertReviewRecord(record);

    final updated = word.copyWith(
        masteryLevel: masteryLevel.clamp(0, 5));
    await DbHelper.updateWord(updated);

    switch (result) {
      case 0:
        _forgotCount++;
      case 1:
        _fuzzyCount++;
      case 2:
        _correctCount++;
    }

    _currentIndex++;
    if (_currentIndex >= _queue.length) {
      _finished = true;
    }

    notifyListeners();
  }

  /// SM-2 算法（以"天"为单位，对齐到凌晨4点）
  (int nextReview, int repetition, double efactor, int masteryLevel)
      _sm2(ReviewRecord? latest, int result) {
    int intervalDays;

    if (latest == null) {
      // 第一次学习
      if (result >= 2) {
        intervalDays = 1;
      } else if (result == 1) {
        intervalDays = 1;
      } else {
        intervalDays = 0;
      }
      final nr = _nextDays4am(intervalDays);
      final mastery = _calcMastery(result >= 2 ? 1 : 0, result);
      return (nr, result >= 2 ? 1 : 0, 2.5, mastery);
    }

    // 计算之前的天数间隔
    int prevDays =
        ((latest.nextReview - latest.reviewedAt) / (24 * 60 * 60 * 1000))
            .round()
            .clamp(0, 365);

    double efactor = latest.efactor;
    int repetition = latest.repetition;

    // 更新 efactor
    efactor += (0.1 - (3 - result) * (0.08 + (3 - result) * 0.02));
    if (efactor < 1.3) efactor = 1.3;

    if (result >= 2) {
      // 记得
      if (repetition == 0) {
        intervalDays = 1;
      } else if (repetition == 1) {
        intervalDays = 3;
      } else {
        intervalDays = (prevDays * efactor).round().clamp(1, 365);
      }
      repetition++;
    } else if (result == 1) {
      // 模糊
      repetition = 0;
      intervalDays = 1;
    } else {
      // 忘记
      repetition = 0;
      intervalDays = 0;
    }

    final nextReview = _nextDays4am(intervalDays);
    final masteryLevel = _calcMastery(repetition, result);

    return (nextReview, repetition, efactor, masteryLevel);
  }

  int _calcMastery(int repetition, int result) {
    if (result == 0) return 0;
    if (repetition >= 5) return 5;
    if (repetition >= 3) return 4;
    if (repetition >= 2) return 3;
    if (repetition >= 1) return 2;
    return 1;
  }
}
