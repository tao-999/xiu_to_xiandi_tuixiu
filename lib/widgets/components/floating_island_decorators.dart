import 'package:flame/components.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/terrain_decoration_spawner_component.dart';
import 'package:xiu_to_xiandi_tuixiu/widgets/components/infinite_content_spawner_component.dart';
import 'floating_island_dynamic_spawner_component.dart';
import 'noise_tile_map_generator.dart';

class FloatingIslandDecorators extends Component {
  final Component grid;
  final Vector2 Function() getLogicalOffset;
  final Vector2 Function() getViewSize;
  final NoiseTileMapGenerator noiseMapGenerator;
  final int seed;

  FloatingIslandDecorators({
    required this.grid,
    required this.getLogicalOffset,
    required this.getViewSize,
    required this.noiseMapGenerator,
    this.seed = 8888,
  });

  @override
  Future<void> onLoad() async {
    // 🌟 怪物生成器
    add(
      InfiniteContentSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (worldPos) => noiseMapGenerator.getTerrainTypeAtPosition(worldPos),
        allowedTerrains: {'mud'}, // 你可以改成你想刷怪的地形
        tileSize: 64.0,
      ),
    );

    // 🌲 森林
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'forest'},
        staticSpritesMap: {
          'forest': [
            StaticSpriteEntry('floating_island/tree_1.png', 3),
            StaticSpriteEntry('floating_island/tree_2.png', 2),
            StaticSpriteEntry('floating_island/tree_3.png', 2),
            StaticSpriteEntry('floating_island/tree_4.png', 1),
            StaticSpriteEntry('floating_island/tree_5.png', 2),
          ],
        },
        dynamicSpritesMap: {}, // 禁用动态
        staticTileSize: 84.0,  // 对应原来的 tileSize
        dynamicTileSize: 64.0, // 无用但必须填
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 9,
        minDynamicObjectsPerTile: 0, // 禁用动态
        maxDynamicObjectsPerTile: 0,
        minStaticObjectSize: 16.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 0.0,
        maxDynamicObjectSize: 0.0,
        minSpeed: 0.0,
        maxSpeed: 0.0,
      ),
    );

    // 🌴 沙滩
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'beach'},
        staticSpritesMap: {
          'beach': [
            StaticSpriteEntry('floating_island/beach_1.png', 1),
          ],
        },
        dynamicSpritesMap: {}, // 禁用动态
        staticTileSize: 80.0,  // 这里对应你原来的 tileSize
        dynamicTileSize: 64.0, // 无用但必须填
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 8,
        minDynamicObjectsPerTile: 0, // 禁用动态
        maxDynamicObjectsPerTile: 0,
        minStaticObjectSize: 16.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 0.0,
        maxDynamicObjectSize: 0.0,
        minSpeed: 0.0,
        maxSpeed: 0.0,
      ),
    );

    // 🌿 草地
    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'grass'},
        staticSpritesMap: {
          'grass': [
            StaticSpriteEntry('floating_island/grass_1.png', 6),
            StaticSpriteEntry('floating_island/grass_2.png', 1),
            StaticSpriteEntry('floating_island/grass_3.png', 3),
          ],
        },
        dynamicSpritesMap: {}, // 不要动态
        staticTileSize: 64.0, // 新版这里要用 staticTileSize
        dynamicTileSize: 64.0, // 随便填不会用
        seed: seed,
        minStaticObjectsPerTile: 1,
        maxStaticObjectsPerTile: 7,
        minDynamicObjectsPerTile: 0, // 禁用动态
        maxDynamicObjectsPerTile: 0, // 禁用动态
        minStaticObjectSize: 16.0,
        maxStaticObjectSize: 48.0,
        minDynamicObjectSize: 0.0,
        maxDynamicObjectSize: 0.0,
        minSpeed: 0.0,
        maxSpeed: 0.0,
      ),
    );

    add(
      FloatingIslandDynamicSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        allowedTerrains: {'shallow_ocean'},
        staticSpritesMap: {
          'shallow_ocean': [
            StaticSpriteEntry('floating_island/shallow_ocean_1.png', 1),
          ],
        },
        dynamicSpritesMap: {
          'shallow_ocean': [
            DynamicSpriteEntry('floating_island/shallow_ocean_2.png', 10),
          ],
        },
        staticTileSize: 256,
        dynamicTileSize: 128,
        // 🌿静态尺寸
        minStaticObjectSize: 64,
        maxStaticObjectSize: 64,
        // 🌿动态尺寸
        minDynamicObjectSize: 16,
        maxDynamicObjectSize: 48,
        // 🌿动态速度
        minSpeed: 10,
        maxSpeed: 30,
        // 🌿静态数量（自己设定）
        minStaticObjectsPerTile: 0,
        maxStaticObjectsPerTile: 1,
        // 🌿动态数量（自己设定）
        minDynamicObjectsPerTile: 1,
        maxDynamicObjectsPerTile: 3,
        seed: seed,
      ),
    );
  }
}
