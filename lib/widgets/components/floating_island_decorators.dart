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
      TerrainDecorationSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        terrainSpritesMap: {
          'forest': [
            SpriteWeightEntry('floating_island/tree_1.png', 3),
            SpriteWeightEntry('floating_island/tree_2.png', 2),
            SpriteWeightEntry('floating_island/tree_3.png', 2),
            SpriteWeightEntry('floating_island/tree_4.png', 1),
            SpriteWeightEntry('floating_island/tree_5.png', 2),
          ],
        },
        tileSize: 84.0,
        seed: seed,
        minObjectsPerTile: 1,
        maxObjectsPerTile: 9,
      ),
    );

    // 🌴 沙滩
    add(
      TerrainDecorationSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        terrainSpritesMap: {
          'beach': [
            SpriteWeightEntry('floating_island/beach_1.png', 1),
          ],
        },
        tileSize: 80.0,
        seed: seed,
        minObjectsPerTile: 1,
        maxObjectsPerTile: 8,
        minObjectSize: 16.0,
        maxObjectSize: 48.0,
      ),
    );

    // 🌿 草地
    add(
      TerrainDecorationSpawnerComponent(
        grid: grid,
        getLogicalOffset: getLogicalOffset,
        getViewSize: getViewSize,
        getTerrainType: (pos) => noiseMapGenerator.getTerrainTypeAtPosition(pos),
        terrainSpritesMap: {
          'grass': [
            SpriteWeightEntry('floating_island/grass_1.png', 6),
            SpriteWeightEntry('floating_island/grass_2.png', 1),
            SpriteWeightEntry('floating_island/grass_3.png', 3),
          ],
        },
        tileSize: 64.0,
        seed: seed,
        minObjectsPerTile: 1,
        maxObjectsPerTile: 7,
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
