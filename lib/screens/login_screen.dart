import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

/// Android は URL スキームが小文字必須
/// iOS は大文字小文字混在OK（Info.plist で登録済み）
String get _redirectUrl => defaultTargetPlatform == TargetPlatform.android
    ? 'com.playonmatch.playonratingapp://login-callback'
    : 'com.playonmatch.playonRatingApp://login-callback';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _loading = false;
  String? _error;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // OAuth コールバック後のセッションを監視
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && mounted) {
        await ApiService.saveToken(session.accessToken);
        if (mounted) context.go('/my');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  // アプリがフォアグラウンドに戻ったときにセッションを確認
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && mounted) {
        await ApiService.saveToken(session.accessToken);
        if (mounted) context.go('/my');
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
      );
      // ブラウザが開く。アプリに戻ったら didChangeAppLifecycleState で検知
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // 手動でセッション確認（フォールバック用）
  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await ApiService.saveToken(session.accessToken);
      if (mounted) context.go('/my');
    } else {
      if (mounted) setState(() => _error = 'セッションが見つかりません。ログインしてから戻ってきてください。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('スキップ'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_tennis, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'PLAYONレーティング',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ログインしてエントリーや\nレーティングを確認しましょう',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(_loading ? 'ブラウザでログイン中...' : 'Googleでログイン'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    elevation: 1,
                  ),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _checkSession,
                  child: const Text('ログイン済みの場合はここをタップ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
