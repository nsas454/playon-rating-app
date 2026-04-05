import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/rated_player.dart';
import '../services/api_service.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  RatedPlayer? _player;
  bool _loading = true;
  String? _error;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await ApiService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
    if (loggedIn) _fetchPlayer();
  }

  Future<void> _fetchPlayer() async {
    try {
      setState(() { _loading = true; _error = null; });
      final player = await ApiService.getMyRatedPlayer();
      setState(() { _player = player; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('マイページ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('ログインしてください', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login),
                label: const Text('ログイン'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _player == null
                  ? const Center(child: Text('プロフィールが見つかりません'))
                  : RefreshIndicator(
                      onRefresh: _fetchPlayer,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileCard(player: _player!),
                            const SizedBox(height: 16),
                            _StatsCard(player: _player!),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.list_alt),
                              title: const Text('エントリー一覧'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/my/entry'),
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Future<void> _logout() async {
    await ApiService.deleteToken();
    setState(() { _isLoggedIn = false; _player = null; });
  }
}

class _ProfileCard extends StatelessWidget {
  final RatedPlayer player;
  const _ProfileCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (player.rank != null)
                        Text('ランキング ${player.rank}位',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('性別', player.genderText),
            _infoRow('生年月日', player.birthday ?? '未設定'),
            _infoRow('都道府県', player.placeName ?? '未設定'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final RatedPlayer player;
  const _StatsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('レーティング', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('現在', player.rating?.toStringAsFixed(0) ?? '-', Colors.blue),
                _statItem('最高', player.bestRating?.toStringAsFixed(0) ?? '-', Colors.orange),
                _statItem('試合数', '${player.gameCount ?? 0}', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('勝', '${player.winCount ?? 0}', Colors.green),
                _statItem('負', '${player.loseCount ?? 0}', Colors.red),
                _statItem('勝率', '${player.winRate.toStringAsFixed(1)}%', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
