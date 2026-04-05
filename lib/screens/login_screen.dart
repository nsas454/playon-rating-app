import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static const _loginUrl =
      'https://account.playonmatch.com/login?redirect=https://rating.playonmatch.com/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          setState(() => _loading = false);
          _checkForToken(url);
        },
      ))
      ..loadRequest(Uri.parse(_loginUrl));
  }

  Future<void> _checkForToken(String url) async {
    // URLにaccess_tokenが含まれる場合（ログイン後リダイレクト）
    final uri = Uri.parse(url);
    String? token = uri.queryParameters['access_token'] ??
        uri.queryParameters['session'];

    // フラグメントからも確認
    if (token == null && url.contains('#')) {
      final fragment = Uri.splitQueryString(url.split('#').last);
      token = fragment['access_token'] ?? fragment['session'];
    }

    // クッキーからトークンを取得
    if (token == null) {
      final cookieJs = await _controller.runJavaScriptReturningResult(
          'document.cookie');
      final cookieStr = cookieJs.toString().replaceAll('"', '');
      final match = RegExp(r'__session=([^;]+)').firstMatch(cookieStr);
      token = match?.group(1);
    }

    if (token != null && token.isNotEmpty) {
      await ApiService.saveToken(token);
      if (mounted) context.go('/my');
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
