import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/api_service.dart';

class EntryListScreen extends StatefulWidget {
  const EntryListScreen({super.key});

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  List<EntryRegistration> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    try {
      setState(() { _loading = true; _error = null; });
      final entries = await ApiService.getMyEntries();
      setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cancel(EntryRegistration entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('キャンセル確認'),
        content: Text('${entry.gameName ?? '-'}（${entry.categoryName}）\nエントリーをキャンセルしますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('戻る')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('キャンセルする', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.cancelEntry(entry.id);
      await _fetchEntries();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エントリーをキャンセルしました')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('キャンセルに失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('エントリー一覧')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchEntries,
                  child: _entries.isEmpty
                      ? const Center(child: Text('エントリーはありません'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _entries.length,
                          itemBuilder: (ctx, i) => _EntryCard(
                            entry: _entries[i],
                            onCancel: () => _cancel(_entries[i]),
                          ),
                        ),
                ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EntryRegistration entry;
  final VoidCallback onCancel;

  const _EntryCard({required this.entry, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!entry.isCancel)
                  _badge('エントリー済み', Colors.green)
                else
                  _badge('キャンセル', Colors.grey),
                const SizedBox(width: 8),
                if (!entry.isCancel)
                  entry.paid
                      ? _badge('支払済', Colors.green)
                      : _badge('未払い', Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.gameName ?? '-',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(entry.categoryName, style: const TextStyle(color: Colors.grey)),
            if (entry.gameStartDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(entry.gameStartDate!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
            if (!entry.isCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('キャンセル'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
