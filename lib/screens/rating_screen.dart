import 'package:flutter/material.dart';
import '../models/rated_player.dart';
import '../services/api_service.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  List<RatedPlayer> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      setState(() { _loading = true; _error = null; });
      final players = await ApiService.getRatings();
      setState(() { _players = players; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('レーティング')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchRatings,
                  child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (ctx, i) {
                      final p = _players[i];
                      final rank = i + 1;
                      return ListTile(
                        leading: _RankBadge(rank: rank),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          p.rating?.toStringAsFixed(0) ?? '-',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (rank == 1) color = const Color(0xFFFFD700);
    if (rank == 2) color = const Color(0xFFC0C0C0);
    if (rank == 3) color = const Color(0xFFCD7F32);

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Text(
        '$rank',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
