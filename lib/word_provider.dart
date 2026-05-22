import 'package:flutter/foundation.dart';
import 'models.dart';
import 'db_helper.dart';

class WordProvider extends ChangeNotifier {
  List<Word> _words = [];
  bool _loading = false;

  List<Word> get words => _words;
  bool get loading => _loading;

  Future<void> loadWords() async {
    _loading = true;
    notifyListeners();
    _words = await DbHelper.getWords();
    _loading = false;
    notifyListeners();
  }

  Future<void> addWord(Word word) async {
    await DbHelper.insertWord(word);
    _words.insert(0, word);
    notifyListeners();
  }

  Future<void> updateWord(Word word) async {
    await DbHelper.updateWord(word);
    final idx = _words.indexWhere((w) => w.id == word.id);
    if (idx != -1) {
      _words[idx] = word;
      notifyListeners();
    }
  }

  Future<void> deleteWord(String id) async {
    await DbHelper.softDeleteWord(id);
    _words.removeWhere((w) => w.id == id);
    notifyListeners();
  }
}
