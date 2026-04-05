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
                  Text('エントリー: ${category.entryRegistrationCount}名',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
