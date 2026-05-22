import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  FlutterTts? _tts;
  AudioPlayer? _player;
  bool _init = false;

  FlutterTts get _ttsInstance => _tts ??= FlutterTts();
  AudioPlayer get _playerInstance => _player ??= AudioPlayer();

  Future<void> init() async {
    if (_init) return;
    _init = true;
    try {
      await _ttsInstance.setLanguage('en-US');
      await _ttsInstance.setSpeechRate(0.4);
      await _ttsInstance.setPitch(1.0);
    } catch (_) {}
  }

  /// 发音：本地缓存 → Free Dictionary mp3 → 系统 TTS
  Future<void> speak(String text) async {
    final word = text.toLowerCase().trim();

    // 1. 本地缓存 mp3
    final localPath = await _localAudioPath(word);
    if (localPath != null) {
      try {
        await _playerInstance.stop();
        await _playerInstance.play(DeviceFileSource(localPath));
        return;
      } catch (_) {}
    }

    // 2. Free Dictionary API 获取 mp3 URL 并下载
    final apiUrl = await _fetchAudioUrlFromApi(word);
    if (apiUrl != null) {
      final saved = await _downloadAudio(word, apiUrl);
      if (saved != null) {
        try {
          await _playerInstance.stop();
          await _playerInstance.play(DeviceFileSource(saved));
          return;
        } catch (_) {}
      }
    }

    // 3. 有道词典 TTS（免费、无需 Key、所有词都有）
    final youdaoUrl =
        'http://dict.youdao.com/dictvoice?audio=${Uri.encodeComponent(word)}&type=1';
    final saved = await _downloadAudio(word, youdaoUrl);
    if (saved != null) {
      try {
        await _playerInstance.stop();
        await _playerInstance.play(DeviceFileSource(saved));
        return;
      } catch (_) {}
    }

    // 4. 降级系统 TTS（离线兜底）
    try {
      await _ttsInstance.speak(text);
    } catch (_) {}
  }

  Future<String?> _localAudioPath(String word) async {
    try {
      final dir = await _audioCacheDir();
      final file = File('$dir/${Uri.encodeComponent(word)}.mp3');
      if (await file.exists()) return file.path;
    } catch (_) {}
    return null;
  }

  /// 从 Free Dictionary API 查发音 mp3 URL
  Future<String?> _fetchAudioUrlFromApi(String word) async {
    try {
      final uri = Uri.https(
        'api.dictionaryapi.dev',
        '/api/v2/entries/en/${Uri.encodeComponent(word)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;

      final list = json.decode(resp.body) as List;
      if (list.isEmpty) return null;

      final phonetics = list[0]['phonetics'] as List?;
      if (phonetics == null) return null;

      for (final p in phonetics) {
        final url = p['audio'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _downloadAudio(String word, String url) async {
    try {
      final existing = await _localAudioPath(word);
      if (existing != null) return existing;

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200 || resp.bodyBytes.length < 500) return null;

      final dir = await _audioCacheDir();
      await Directory(dir).create(recursive: true);

      final file = File('$dir/${Uri.encodeComponent(word)}.mp3');
      await file.writeAsBytes(resp.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String> _audioCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/audio_cache';
  }

  Future<void> dispose() async {
    try {
      await _ttsInstance.stop();
      await _playerInstance.stop();
    } catch (_) {}
  }
}
