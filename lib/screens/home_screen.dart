import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/game.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Game> _games = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      setState(() { _loading = true; _error = null; });
      final games = await ApiService.getGames();
      setState(() {
        _games = games.where((g) => g.acceptingCategories.isNotEmpty).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大会情報'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchGames,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        ElevatedButton(onPressed: _fetchGames, child: const Text('再読み込み')),
                      ],
                    ),
                  )
                : _games.isEmpty
                    ? const Center(child: Text('エントリーできる大会がありません'))
                    : ListView.builder(
                        itemCount: _games.length,
                        itemBuilder: (context, index) {
                          final game = _games[index];
                          return _GameCard(game: game);
                        },
                      ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/game/${game.slug}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game.placeAddress.isNotEmpty ? game.placeAddress : game.place,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${game.startDate} 〜 ${game.endDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: game.acceptingCategories.map((cat) {
                  final count = cat.entryRegistrationCount;
                  final max = cat.entryMax;
                  final isFull = max != null && count >= max;
                  final fillRatio = max != null && max > 0 ? count / max : null;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFull ? Colors.red.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.name, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.person,
                          size: 12,
                          color: isFull ? Colors.red : Colors.green.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          max != null ? '$count/$max' : '$count人',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFull ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                        if (isFull) ...[
                          const SizedBox(width: 4),
                          Text('満員',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                        ] else if (fillRatio != null && fillRatio >= 0.8) ...[
                          const SizedBox(width: 4),
                          Text('残りわずか',
                              style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
