import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/models/disciple.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import '../../utils/aptitude_color_util.dart';

class ZhushouDiscipleSlot extends StatefulWidget {
  final String roomName;

  const ZhushouDiscipleSlot({super.key, required this.roomName});

  @override
  State<ZhushouDiscipleSlot> createState() => _ZhushouDiscipleSlotState();
}

class _ZhushouDiscipleSlotState extends State<ZhushouDiscipleSlot> {
  Disciple? _selected;

  @override
  void initState() {
    super.initState();
    _loadAssignedDisciple();
  }

  @override
  void didUpdateWidget(covariant ZhushouDiscipleSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomName != widget.roomName) {
      _loadAssignedDisciple();
    }
  }

  void _loadAssignedDisciple() async {
    final all = await ZongmenStorage.loadDisciples();

    final matches = all.where((d) => d.assignedRoom == widget.roomName);
    final match = matches.isNotEmpty ? matches.first : null;

    setState(() => _selected = match);
  }

  void _removeDisciple() async {
    if (_selected != null) {
      await ZongmenStorage.removeDiscipleFromRoom(_selected!.id, widget.roomName);
      setState(() => _selected = null);
    }
  }

  void _showSelectDialog() async {
    final all = await ZongmenStorage.loadDisciples();
    final list = all.where((d) =>
    d.assignedRoom == null ||
        d.assignedRoom == widget.roomName ||
        d.id == _selected?.id).toList();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择驻守弟子 - ${widget.roomName}',
                style: const TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'ZcoolCangEr'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: GridView.builder(
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (_, index) {
                    final d = list[index];
                    final isSelected = _selected?.id == d.id;

                    return GestureDetector(
                      onTap: () async {
                        await ZongmenStorage.setDiscipleAssignedRoom(d.id, widget.roomName);
                        setState(() => _selected = d);
                        Navigator.pop(context);
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude).copyWith(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      d.imagePath.isNotEmpty
                                          ? d.imagePath
                                          : 'assets/images/default_card.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: AptitudeColorUtil.getBackgroundDecoration(d.aptitude).copyWith(
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${d.aptitude}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontFamily: 'ZcoolCangEr',
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                    ),
                                    child: Text(
                                      d.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'ZcoolCangEr',
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.check, color: Colors.greenAccent, size: 20),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = _selected != null
        ? AptitudeColorUtil.getBackgroundDecoration(_selected!.aptitude).copyWith(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white30),
    )
        : const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white10,
      border: Border.fromBorderSide(BorderSide(color: Colors.white24)),
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: _showSelectDialog,
          child: Container(
            width: 72,
            height: 72,
            decoration: decoration,
            child: ClipOval(
              child: _selected != null
                  ? Image.asset(
                _selected!.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
                  : const Center(
                child: Icon(Icons.add, size: 28, color: Colors.white54),
              ),
            ),
          ),
        ),
        if (_selected != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _removeDisciple,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 14, color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }
}
