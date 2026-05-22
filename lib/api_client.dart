import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'db_helper.dart';

class ApiClient {
  static const _defaultUrl = 'http://localhost:8080';
  static String _baseUrl = _defaultUrl;
  static String? _token;

  static String get baseUrl => _baseUrl;
  static bool get isLoggedIn => _token != null;
  static String? get token => _token;

  static Future<void> init() async {
    final saved = await DbHelper.getSyncInfo('server_url');
    _baseUrl = saved ?? _defaultUrl;
    _token = await DbHelper.getSyncInfo('jwt_token');
  }

  static void _saveToken(String token) async {
    _token = token;
    await DbHelper.setSyncInfo('jwt_token', token);
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await DbHelper.setSyncInfo('server_url', url);
  }

  /// 注册，成功返回 token
  static Future<String> register(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 201) {
      final data = json.decode(resp.body);
      _saveToken(data['token']);
      return _token!;
    }
    final err = json.decode(resp.body);
    throw Exception(err['error'] ?? '注册失败');
  }

  /// 登录，成功返回 token
  static Future<String> login(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      _saveToken(data['token']);
      return _token!;
    }
    final err = json.decode(resp.body);
    throw Exception(err['error'] ?? '登录失败');
  }

  static Future<void> logout() async {
    _token = null;
    await DbHelper.setSyncInfo('jwt_token', '');
  }

  /// 增量拉取，返回 (words, serverTime)
  static Future<(List<Word>, int)> pullWords(int since) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/words?since=$since'),
      headers: _authHeaders(),
    );
    if (resp.statusCode != 200) throw Exception('拉取失败');
    final data = json.decode(resp.body);
    final list = data['words'] as List;
    final words = list
        .map((w) => Word.fromMap(Map<String, dynamic>.from(w)))
        .toList();
    final serverTime = (data['server_time'] as int?) ?? 0;
    return (words, serverTime);
  }

  /// 批量推送，返回服务端时间戳
  static Future<int> pushWords(List<Word> words) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/words'),
      headers: _authHeaders(),
      body: json.encode(words.map((w) => w.toMap()).toList()),
    );
    if (resp.statusCode != 200) throw Exception('推送失败');
    final data = json.decode(resp.body);
    return (data['server_time'] as int?) ?? 0;
  }

  /// 更新单个
  static Future<void> updateWord(Word word) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/api/words/${word.id}'),
      headers: _authHeaders(),
      body: json.encode({
        'word': word.word,
        'translation': word.translation,
        'pronunciation': word.pronunciation,
        'part_of_speech': word.partOfSpeech,
        'example_sent': word.exampleSent,
        'tags': word.tags,
        'mastery_level': word.masteryLevel,
        'updated_at': word.updatedAt,
        'deleted': word.deleted ? 1 : 0,
      }),
    );
    if (resp.statusCode != 200) throw Exception('更新失败');
  }

  /// 删除单个
  static Future<void> deleteWord(String id) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/api/words/$id'),
      headers: _authHeaders(),
    );
    if (resp.statusCode != 200) throw Exception('删除失败');
  }

  static Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      };
}
