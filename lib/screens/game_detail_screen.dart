import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/game.dart';
import '../services/api_service.dart';

class GameDetailScreen extends StatefulWidget {
  final String slug;
  const GameDetailScreen({super.key, required this.slug});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  Game? _game;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    try {
      setState(() { _loading = true; _error = null; });
      final game = await ApiService.getGame(widget.slug);
      setState(() { _game = game; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openEntry(Category category) {
    // Webブラウザでエントリーページを開く
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EntryWebView(
          url: 'https://rating.playonmatch.com/game/${widget.slug}/entry/${category.id}',
          title: 'エントリー',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_game?.name ?? '大会詳細')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _game == null
                  ? const Center(child: Text('データがありません'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_game!.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _infoRow(Icons.business, _game!.organizationName),
                          _infoRow(Icons.location_on,
                              _game!.placeAddress.isNotEmpty ? _game!.placeAddress : _game!.place),
                          _infoRow(Icons.calendar_today, '${_game!.startDate} 〜 ${_game!.endDate}'),
                          if (_game!.entryDeadline != null)
                            _infoRow(Icons.timer, 'エントリー締切: ${_game!.entryDeadline!.substring(0, 10)}'),
                          const SizedBox(height: 20),
                          const Text('カテゴリ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ..._game!.categories.map((cat) => _CategoryCard(
                                category: cat,
                                onEntry: cat.isAcceptingEntry ? () => _openEntry(cat) : null,
                              )),
                        ],
                      ),
                    ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onEntry;

  const _CategoryCard({required this.category, this.onEntry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (category.entryFee != null)
                    Text('参加費: ¥${category.entryFee}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  _EntryCountRow(category: category),
                ],
              ),
            ),
            if (onEntry != null)
              ElevatedButton(
                onPressed: onEntry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('エントリー', style: TextStyle(color: Colors.white)),
              )
            else if (!category.isAcceptingEntry)
              const Chip(label: Text('受付終了'), backgroundColor: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _EntryCountRow extends StatelessWidget {
  final Category category;
  const _EntryCountRow({required this.category});

  @override
  Widget build(BuildContext context) {
    final count = category.entryRegistrationCount;
    final max = category.entryMax;
    final isFull = max != null && count >= max;
    final fillRatio = max != null && max > 0 ? count / max : null;

    return Row(
      children: [
        Icon(Icons.people, size: 14, color: isFull ? Colors.red : Colors.grey),
        const SizedBox(width: 4),
        Text(
          max != null ? '$count / $max 名' : '$count 名',
          style: TextStyle(
            fontSize: 13,
            color: isFull ? Colors.red.shade700 : Colors.grey.shade700,
            fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
        if (max != null) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fillRatio,
                backgroundColor: Colors.grey.shade200,
                color: isFull
                    ? Colors.red
                    : fillRatio != null && fillRatio >= 0.8
                        ? Colors.orange
                        : Colors.green,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (isFull)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text('満員', style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
          )
        else if (fillRatio != null && fillRatio >= 0.8)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text('残りわずか',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
          ),
      ],
    );
  }
}

class _EntryWebView extends StatefulWidget {
  final String url;
  final String title;
  const _EntryWebView({required this.url, required this.title});

  @override
  State<_EntryWebView> createState() => _EntryWebViewState();
}

class _EntryWebViewState extends State<_EntryWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/17.0 Mobile/15E148 Safari/604.1',
      );
    _loadWithAuth();
  }

  Future<void> _loadWithAuth() async {
    final token = await ApiService.getToken();
    final uri = Uri.parse(widget.url);

    if (token != null) {
      // ページ読み込み前にCookieをセット
      final cookieManager = WebViewCookieManager();
      await cookieManager.setCookie(
        WebViewCookie(
          name: '__session',
          value: token,
          domain: '.playonmatch.com',
          path: '/',
        ),
      );
    }

    await _controller.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
