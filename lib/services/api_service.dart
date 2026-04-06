import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';
import '../models/entry.dart';
import '../models/rated_player.dart';

class ApiService {
  static const String baseUrl = 'https://api.playonmatch.com';
  static const String tokenKey = '__session';
  static const _storage = FlutterSecureStorage();

  // トークン管理
  // SupabaseセッションのアクセストークンをSecureStorageにキャッシュ
  static Future<String?> getToken() async {
    // Supabaseのセッションが有効なら自動でリフレッシュされた最新トークンを返す
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // SecureStorageにも更新しておく
      await _storage.write(key: tokenKey, value: session.accessToken);
      return session.accessToken;
    }
    // フォールバック: SecureStorageのキャッシュ
    return await _storage.read(key: tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
    await Supabase.instance.client.auth.signOut();
  }

  static Future<bool> isLoggedIn() async {
    // Supabaseセッションが有効かどうかを優先確認
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return true;

    // フォールバック: SecureStorageのJWTを確認
    final token = await _storage.read(key: tokenKey);
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);
      final exp = data['exp'] as int?;
      if (exp == null) return true;
      return DateTime.now().millisecondsSinceEpoch / 1000 < exp;
    } catch (_) {
      return false;
    }
  }

  // 共通ヘッダー
  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // 大会一覧
  static Future<List<Game>> getGames({int pageSize = 100}) async {
    final token = await getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse('$baseUrl/games/?page_size=$pageSize');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final results = data['results'] as List<dynamic>;
      return results.map((g) => Game.fromJson(g)).toList();
    }
    throw Exception('大会一覧の取得に失敗しました: ${response.statusCode}');
  }

  // 大会詳細
  static Future<Game> getGame(String slug) async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/games/$slug/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Game.fromJson(data);
    }
    throw Exception('大会詳細の取得に失敗しました');
  }

  // プロフィール更新
  static Future<RatedPlayer> updateMyRatedPlayer({
    String? name,
    String? birthday,
    String? gender,
    String? place,
  }) async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/v1/my/rated_player/');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (birthday != null) body['birthday'] = birthday;
    if (gender != null) body['gender'] = gender;
    if (place != null) body['place'] = place;

    final response = await http.patch(
      uri,
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return RatedPlayer.fromJson(data);
    }
    throw Exception('プロフィールの更新に失敗しました: ${response.statusCode}');
  }

  // マイプロフィール（RatedPlayer）
  static Future<RatedPlayer> getMyRatedPlayer() async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/v1/my/rated_player/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return RatedPlayer.fromJson(data);
    }
    throw Exception('プロフィールの取得に失敗しました: ${response.statusCode}');
  }

  // エントリー一覧
  static Future<List<EntryRegistration>> getMyEntries() async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/v1/my/entry_registrations/');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final results = data['results'] as List<dynamic>;
      return results.map((e) => EntryRegistration.fromJson(e)).toList();
    }
    throw Exception('エントリー一覧の取得に失敗しました');
  }

  // エントリーキャンセル
  static Future<void> cancelEntry(int entryId) async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/v1/my/entry_registrations/$entryId/cancel/');
    final response = await http.post(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('キャンセルに失敗しました');
    }
  }

  // レーティング一覧
  static Future<List<RatedPlayer>> getRatings() async {
    final headers = await _headers(auth: true);
    final uri = Uri.parse('$baseUrl/v1/rated_players/?ordering=-point');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final results = data['results'] as List<dynamic>;
      return results.map((r) => RatedPlayer.fromJson(r)).toList();
    }
    throw Exception('レーティング一覧の取得に失敗しました');
  }
}
