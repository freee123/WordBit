import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'secrets.dart';

class TranslationResult {
  final String translation;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? exampleSent;
  final String? audioUrl;
  final bool spellOk;

  TranslationResult({
    required this.translation,
    this.pronunciation,
    this.partOfSpeech,
    this.exampleSent,
    this.audioUrl,
    this.spellOk = true,
  });
}

class TranslationService {
  static const String _appId = secrets_appId;
  static const String _key = secrets_key;

  static bool get isConfigured => _appId != 'YOUR_BAIDU_APPID';

  /// 合并翻译结果：Free Dictionary 取音标/词性/例句，百度取中文翻译
  static Future<TranslationResult> translate(String text) async {
    final results = await Future.wait([
      _fetchFreeDictionary(text),
      _fetchBaidu(text),
    ]);

    final freeDict = results[0];
    final baidu = results[1];

    return TranslationResult(
      translation: baidu.translation,
      pronunciation: freeDict.pronunciation ?? baidu.pronunciation,
      partOfSpeech: freeDict.partOfSpeech ?? baidu.partOfSpeech,
      exampleSent: freeDict.exampleSent ?? baidu.exampleSent,
      spellOk: freeDict.spellOk,
    );
  }

  /// Free Dictionary API — 音标 + 词性 + 例句 + 拼写校验
  /// https://dictionaryapi.dev/
  static Future<TranslationResult> _fetchFreeDictionary(String text) async {
    final uri = Uri.https(
      'api.dictionaryapi.dev',
      '/api/v2/entries/en/${Uri.encodeComponent(text)}',
    );

    final response = await http.get(uri);

    // 404 → 拼写错误
    if (response.statusCode == 404) {
      return TranslationResult(translation: '', spellOk: false);
    }

    if (response.statusCode != 200) {
      return TranslationResult(translation: '', spellOk: true);
    }

    try {
      final list = json.decode(response.body) as List;
      if (list.isEmpty) return TranslationResult(translation: '', spellOk: true);

      final data = list[0] as Map<String, dynamic>;

      // 音标
      final phonetic = data['phonetic'] as String?;

      // 发音 mp3 URL
      String? audioUrl;
      final phonetics = data['phonetics'] as List?;
      if (phonetics != null) {
        for (final p in phonetics) {
          final url = p['audio'] as String?;
          if (url != null && url.isNotEmpty) {
            audioUrl = url;
            break;
          }
        }
      }

      // 词性 + 例句（取第一个有例句的释义）
      String? pos;
      String? example;
      final meanings = data['meanings'] as List?;
      if (meanings != null) {
        for (final m in meanings) {
          final defs = m['definitions'] as List?;
          if (defs != null) {
            for (final d in defs) {
              final ex = d['example'] as String?;
              if (ex != null && ex.isNotEmpty) {
                pos = m['partOfSpeech'];
                example = ex;
                break;
              }
            }
            if (example != null) break;
          }
          pos ??= m['partOfSpeech'] as String?;
        }
      }

      return TranslationResult(
        translation: '',
        pronunciation: phonetic,
        partOfSpeech: pos,
        exampleSent: example,
        audioUrl: audioUrl,
        spellOk: true,
      );
    } catch (_) {
      return TranslationResult(translation: '', spellOk: true);
    }
  }

  /// 百度翻译 API — 中文翻译
  static Future<TranslationResult> _fetchBaidu(String text) async {
    if (!isConfigured) {
      return TranslationResult(
        translation: '[请先配置百度翻译 API Key]',
      );
    }

    final salt = Random().nextInt(1000000).toString();
    final signRaw = '$_appId$text$salt$_key';
    final sign = md5.convert(utf8.encode(signRaw)).toString();

    final uri = Uri.https(
      'fanyi-api.baidu.com',
      '/api/trans/vip/translate',
      {
        'q': text,
        'from': 'en',
        'to': 'zh',
        'appid': _appId,
        'salt': salt,
        'sign': sign,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return TranslationResult(translation: '翻译请求失败');
    }

    final data = json.decode(response.body);
    if (data['error_code'] != null) {
      return TranslationResult(translation: '翻译错误: ${data['error_msg']}');
    }

    final transResults = data['trans_result'] as List;
    final translation =
        transResults.map((r) => r['dst'] as String).join('；');

    return TranslationResult(translation: translation);
  }
}
