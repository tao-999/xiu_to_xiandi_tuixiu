import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/drag_map.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/disciple_node_component.dart';
import 'package:xiu_to_xiandi_tuixiu/services/zongmen_storage.dart';
import 'package:xiu_to_xiandi_tuixiu/services/role_service.dart';

import '../../services/player_storage.dart';
import '../../services/weapons_storage.dart';
import '../../utils/cultivation_level.dart';

class ZongmenPositionMapGame extends FlameGame {
  late final Vector2 mapSize;
  final Vector2 cameraOffset = Vector2.zero();
  late SpriteComponent bg;

  /// ✅ 外部传入的点击回调（触发弹窗）
  final void Function(
      String discipleId,
      String discipleName,
      String? currentRole,
      String? currentRealm,
      void Function(String? newRole) onAppointed,
      )? onAppointRequested;

  ZongmenPositionMapGame({this.onAppointRequested});

  static const Size discipleNodeSize = Size(48, 48);
  static const Size avatarSize = Size(32, 32);

  @override
  Future<void> onLoad() async {
    final screenHeight = size.y;
    mapSize = Vector2.all(screenHeight);

    bg = SpriteComponent()
      ..sprite = await loadSprite('bg_zongmen_zhiwei.webp')
      ..size = mapSize
      ..position = cameraOffset;
    cameraOffset.setFrom(Vector2((size.x - mapSize.x) / 2, 0));
    bg.position = cameraOffset.clone();

    final disciples = await ZongmenStorage.loadDisciples();
    final regions = await RoleService.loadAllRegions();
    final usedRects = regions.values.toList();

    // ✅ 补上宗主默认占位（居中）
    final center = mapSize / 2;
    final zongzhuRect = Rect.fromLTWH(
      center.x,
      center.y,
      discipleNodeSize.width,
      discipleNodeSize.height,
    );
    usedRects.add(zongzhuRect);

    for (final d in disciples) {
      if (d.role == '宗主') continue; // 宗主单独处理
      Rect? region = regions[d.id];

      if (region == null) {
        region = _findFreeSlotInEllipse(usedRects)
            ?? _findFreeSlotInTopSquare(usedRects)
            ?? _findFreeSlotInTrapezoid(usedRects);
        if (region == null) continue;
        await RoleService.saveRegion(d.id, region);
        usedRects.add(region);
      }

      final node = DiscipleNodeComponent(
        id: d.id,
        name: d.name,
        realm: d.realm,
        role: d.role, // ✅ 直接使用字段
        imagePath: d.imagePath,
        position: Vector2(region.left, region.top),
        size: Vector2(
          discipleNodeSize.width,
          discipleNodeSize.height,
        ),
      );

      bg.add(node);
    }

    await _addZongzhuNode();
    add(bg);

    // ✅ 加上 DragMap 并处理点击事件
    add(DragMap(
      onDragged: (delta) {
        cameraOffset.add(delta);
        _clampCameraOffset();
        bg.position = cameraOffset;
      },
        onTap: (tapPosition) {
          final worldTap = tapPosition - cameraOffset;
          for (final child in bg.children) {
            if (child is DiscipleNodeComponent && child.containsPoint(worldTap)) {
              if (child.role == '宗主') return;
              debugPrint('🎯 命中弟子：${child.name}（ID: ${child.id}）');

              onAppointRequested?.call(
                child.id,
                child.name,
                child.role,
                child.realm,
                    (newRole) async {
                  child.updateRole(newRole);
                  await ZongmenStorage.setDiscipleRole(child.id, newRole ?? '弟子');
                    },
              );
              break;
            }
          }
        }
    ));
  }

  /// 🔧 在宗门职位图中添加宗主节点（居中显示，统一尺寸）
  Future<void> _addZongzhuNode() async {
    final display = await getDisplayLevelFromPrefs();
    final player = await PlayerStorage.getPlayer();
    if (player == null) return; // ⛔ 没玩家就别画了

    final isFemale = player.gender == 'female';
    final baseName = isFemale ? 'dazuo_female' : 'dazuo_male';

    final equipped = await WeaponsStorage.loadWeaponsEquippedBy(player.id); // ✅ 注意 import

    final hasWeapon = equipped.any((w) => w.type == 'weapon');
    final hasArmor = equipped.any((w) => w.type == 'armor');

    String suffix = '';
    if (hasWeapon && hasArmor) {
      suffix = '_weapon_armor';
    } else if (hasWeapon) {
      suffix = '_weapon';
    } else if (hasArmor) {
      suffix = '_armor';
    }

    final imagePath = 'assets/images/${baseName}${suffix}.png';

    final zongzhu = DiscipleNodeComponent(
      id: player.id,
      name: player.name,
      realm: display.realm,
      role: '宗主',
      imagePath: imagePath,
      position: mapSize / 2,
      size: Vector2.all(48),
    );

    bg.add(zongzhu);
  }

  void _clampCameraOffset() {
    final minX = size.x - mapSize.x;
    final minY = size.y - mapSize.y;
    cameraOffset.x = cameraOffset.x.clamp(minX, 0.0);
    cameraOffset.y = cameraOffset.y.clamp(minY, 0.0);
  }

  Rect? _findFreeSlotInEllipse(List<Rect> used) {
    const maxTry = 300;
    final nodeSize = discipleNodeSize;
    final center = mapSize / 2;
    final rx = mapSize.x * 0.75 / 2;
    final ry = rx * 0.4;
    final rng = Random();

    for (int i = 0; i < maxTry; i++) {
      final t = 2 * pi * rng.nextDouble();
      final u = rng.nextDouble() + rng.nextDouble();
      final r = u > 1 ? 2 - u : u;
      final x = rx * r * cos(t);
      final y = ry * r * sin(t);

      final px = center.x + x - nodeSize.width / 2;
      final py = center.y + y - nodeSize.height / 2;

      final rect = Rect.fromLTWH(px, py, nodeSize.width, nodeSize.height);
      final avatarRect = Rect.fromLTWH(
        rect.left + (nodeSize.width - avatarSize.width) / 2,
        rect.top + 20,
        avatarSize.width,
        avatarSize.height,
      );

      if (used.every((r) {
        final other = Rect.fromLTWH(
          r.left + (r.width - avatarSize.width) / 2,
          r.top + 20,
          avatarSize.width,
          avatarSize.height,
        );
        return !other.overlaps(avatarRect);
      })) {
        return rect;
      }
    }
    return null;
  }

  Rect? _findFreeSlotInTrapezoid(List<Rect> used) {
    const colSpacing = 8.0;
    const rowSpacing = 10.0;
    final nodeSize = discipleNodeSize;
    final topY = (mapSize.y * 0.5).clamp(0, mapSize.y);
    final bottomY = mapSize.y - 20;
    final cols = (mapSize.x / (nodeSize.width + colSpacing)).floor();
    final rows = ((bottomY - topY) / (nodeSize.height + rowSpacing)).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final px = col * (nodeSize.width + colSpacing) + 10;
        final py = topY + row * (nodeSize.height + rowSpacing);

        final rect = Rect.fromLTWH(px, py, nodeSize.width, nodeSize.height);
        final avatarRect = Rect.fromLTWH(
          px + (nodeSize.width - avatarSize.width) / 2,
          py + 20,
          avatarSize.width,
          avatarSize.height,
        );

        if (used.every((r) {
          final other = Rect.fromLTWH(
            r.left + (r.width - avatarSize.width) / 2,
            r.top + 20,
            avatarSize.width,
            avatarSize.height,
          );
          return !other.overlaps(avatarRect);
        })) {
          return rect;
        }
      }
    }
    return null;
  }

  Rect? _findFreeSlotInTopSquare(List<Rect> used) {
    const colSpacing = 8.0;
    const rowSpacing = 10.0;
    final nodeSize = discipleNodeSize;
    final ellipseWidth = mapSize.x * 0.75;
    final ellipseHeight = ellipseWidth * 0.4;
    final center = mapSize / 2;

    final ellipseTopY = center.y - ellipseHeight / 2;
    final topY = 0.0;
    final bottomY = ellipseTopY - 10;
    final squareWidth = ellipseWidth;
    final squareLeft = (mapSize.x - squareWidth) / 2;
    final cols = (squareWidth / (nodeSize.width + colSpacing)).floor();
    final rows = ((bottomY - topY) / (nodeSize.height + rowSpacing)).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final px = squareLeft + col * (nodeSize.width + colSpacing);
        final py = bottomY - row * (nodeSize.height + rowSpacing) - nodeSize.height;

        final rect = Rect.fromLTWH(px, py, nodeSize.width, nodeSize.height);
        if (used.every((r) => !r.overlaps(rect))) return rect;
      }
    }
    return null;
  }
}
