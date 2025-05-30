import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/character.dart';
import 'package:xiu_to_xiandi_tuixiu/services/player_storage.dart';

class ResourceBar extends StatefulWidget {
  const ResourceBar({super.key});

  @override
  State<ResourceBar> createState() => _ResourceBarState();
}

class _ResourceBarState extends State<ResourceBar> {
  Character? _player;

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  Future<void> _loadPlayer() async {
    final player = await PlayerStorage.getPlayer();
    if (mounted) {
      setState(() {
        _player = player;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    if (_player == null) {
      return SizedBox(height: topInset + 48); // 留高度 + 占位
    }

    final res = _player!.resources;

    return Padding(
      padding: EdgeInsets.only(top: topInset), // ✅ 关键：避开刘海
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F0E3),
          border: const Border(bottom: BorderSide(color: Colors.brown, width: 0.5)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildItem('下品灵石', res.spiritStoneLow, Icons.circle),
              const SizedBox(width: 16),
              _buildItem('中品灵石', res.spiritStoneMid, Icons.change_history),
              const SizedBox(width: 16),
              _buildItem('上品灵石', res.spiritStoneHigh, Icons.diamond),
              const SizedBox(width: 16),
              _buildItem('极品灵石', res.spiritStoneSupreme, Icons.star),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber[800]),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
