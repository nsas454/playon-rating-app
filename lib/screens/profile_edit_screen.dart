import 'package:flutter/material.dart';
import '../models/rated_player.dart';
import '../services/api_service.dart';

const _genderChoices = [
  ('', '未設定'),
  ('1', '男性'),
  ('2', '女性'),
];

const _placeChoices = [
  ('', '未設定'),
  ('1', '北海道'), ('2', '青森県'), ('3', '岩手県'), ('4', '宮城県'),
  ('5', '秋田県'), ('6', '山形県'), ('7', '福島県'), ('8', '茨城県'),
  ('9', '栃木県'), ('10', '群馬県'), ('11', '埼玉県'), ('12', '千葉県'),
  ('13', '東京都'), ('14', '神奈川県'), ('15', '新潟県'), ('16', '富山県'),
  ('17', '石川県'), ('18', '福井県'), ('19', '山梨県'), ('20', '長野県'),
  ('21', '岐阜県'), ('22', '静岡県'), ('23', '愛知県'), ('24', '三重県'),
  ('25', '滋賀県'), ('26', '京都府'), ('27', '大阪府'), ('28', '兵庫県'),
  ('29', '奈良県'), ('30', '和歌山県'), ('31', '鳥取県'), ('32', '島根県'),
  ('33', '岡山県'), ('34', '広島県'), ('35', '山口県'), ('36', '徳島県'),
  ('37', '香川県'), ('38', '愛媛県'), ('39', '高知県'), ('40', '福岡県'),
  ('41', '佐賀県'), ('42', '長崎県'), ('43', '熊本県'), ('44', '大分県'),
  ('45', '宮崎県'), ('46', '鹿児島県'), ('47', '沖縄県'), ('48', '海外'),
];

class ProfileEditScreen extends StatefulWidget {
  final RatedPlayer player;
  const ProfileEditScreen({super.key, required this.player});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _gender;
  late String _place;
  DateTime? _birthday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.player.name);
    _gender = widget.player.gender ?? '';
    _place = widget.player.place ?? '';
    if (widget.player.birthday != null) {
      try {
        _birthday = DateTime.parse(widget.player.birthday!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
      helpText: '生年月日を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateMyRatedPlayer(
        name: _nameCtrl.text.trim(),
        birthday: _birthday != null
            ? '${_birthday!.year.toString().padLeft(4, '0')}-'
              '${_birthday!.month.toString().padLeft(2, '0')}-'
              '${_birthday!.day.toString().padLeft(2, '0')}'
            : null,
        gender: _gender,
        place: _place.isEmpty ? null : _place,
      );
      if (mounted) {
        Navigator.pop(context, updated); // 更新されたプレイヤーを返す
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました ✓')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthdayText = _birthday != null
        ? '${_birthday!.year}年${_birthday!.month}月${_birthday!.day}日'
        : '未設定';

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 名前
            _SectionHeader('基本情報'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '名前',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 性別
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: '性別',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: _genderChoices.map((c) => DropdownMenuItem(
                    value: c.$1,
                    child: Text(c.$2),
                  )).toList(),
                  onChanged: (v) => setState(() => _gender = v ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 生年月日
            Card(
              child: ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('生年月日'),
                subtitle: Text(birthdayText),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickBirthday,
              ),
            ),
            const SizedBox(height: 12),

            // 都道府県
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _place,
                  decoration: const InputDecoration(
                    labelText: '都道府県',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: _placeChoices.map((c) => DropdownMenuItem(
                    value: c.$1,
                    child: Text(c.$2),
                  )).toList(),
                  onChanged: (v) => setState(() => _place = v ?? ''),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('保存する', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5)),
    );
  }
}
