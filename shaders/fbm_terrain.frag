#include <flutter/runtime_effect.glsl>

// ===== 海面动画参数（不增加/更改任何 uniform） =====
const float TAU = 6.28318530718;

// —— 两层平移（单位：每秒“多少个瓦片”的UV位移）——
const vec2  OCEAN_SCROLL_A = vec2( 0.22, 0.03);
const vec2  OCEAN_SCROLL_B = vec2(-0.09, 0.00);

// —— 扭曲幅度（相对每瓦片 0..1 的比例）——
const float OCEAN_WARP_AMP_A = 0.050; // 0.02~0.08
const float OCEAN_WARP_AMP_B = 0.030;

// —— 扭曲频率与相位速度 ——
const vec2  OCEAN_WARP_FREQ_A = vec2(1.6, 2.4);
const vec2  OCEAN_WARP_FREQ_B = vec2(3.2, 2.1);
const vec2  OCEAN_WARP_SPEED_A = vec2( 0.60,-0.45); // rad/s
const vec2  OCEAN_WARP_SPEED_B = vec2(-0.55, 0.40); // rad/s

// —— A/B 动态混合轻微起伏 ——
const float OCEAN_BLEND_WOBBLE = 0.35; // 0~0.5，0=恒定0.5

// ===== 基础 uniforms（与 Dart setFloat 顺序一致） =====
uniform vec2  uResolution;    // 0,1
uniform vec2  uWorldTopLeft;  // 2,3
uniform float uScale;         // 4
uniform float uFreq;          // 5
uniform float uTime;          // 6
uniform float uOctaves;       // 7
uniform float uPersistence;   // 8
uniform float uSeed;          // 9
uniform float uDebug;         // 10
uniform float uLodEnable;     // 11
uniform float uLodNyquist;    // 12
uniform vec2  uWorldBase;     // 13,14

// ===== 每个地形平铺周期 =====
uniform float uPeriodSnow;     // 15
uniform float uPeriodGrass;    // 16
uniform float uPeriodRock;     // 17
uniform float uPeriodForest;   // 18
uniform float uPeriodFlower;   // 19
uniform float uPeriodShallow;  // 20  <-- 海
uniform float uPeriodBeach;    // 21
uniform float uPeriodVolcanic; // 22

// ===== 占位（保持索引） =====
uniform float uTexModeSnow;     // 23
uniform float uTexModeGrass;    // 24
uniform float uTexModeRock;     // 25
uniform float uTexModeForest;   // 26
uniform float uTexModeFlower;   // 27
uniform float uTexModeShallow;  // 28
uniform float uTexModeBeach;    // 29
uniform float uTexModeVolcanic; // 30

// Atlas 网格（列、行）
uniform vec2  uAtlasGrid;       // 31,32

// A/B 混合控制（占位）→ 这里借来传 Atlas 像素宽高（替代 textureSize）
uniform float uABBlend;         // 33 -> atlasWidth(px)
uniform float uMixMode;         // 34 -> atlasHeight(px)

// ===== 变体偏移/数量 =====
uniform float uVarOffsetSnow;     // 35
uniform float uVarOffsetGrass;    // 36
uniform float uVarOffsetRock;     // 37
uniform float uVarOffsetForest;   // 38
uniform float uVarOffsetFlower;   // 39
uniform float uVarOffsetShallow;  // 40
uniform float uVarOffsetBeach;    // 41
uniform float uVarOffsetVolcanic; // 42

uniform float uVarCountSnow;      // 43
uniform float uVarCountGrass;     // 44
uniform float uVarCountRock;      // 45
uniform float uVarCountForest;    // 46
uniform float uVarCountFlower;    // 47
uniform float uVarCountShallow;   // 48
uniform float uVarCountBeach;     // 49
uniform float uVarCountVolcanic;  // 50

// ===== 区间（占位） =====
uniform float uRangeMinSnow;      // 51
uniform float uRangeMinGrass;     // 52
uniform float uRangeMinRock;      // 53
uniform float uRangeMinForest;    // 54
uniform float uRangeMinFlower;    // 55
uniform float uRangeMinShallow;   // 56
uniform float uRangeMinBeach;     // 57
uniform float uRangeMinVolcanic;  // 58
uniform float uRangeMaxSnow;      // 59
uniform float uRangeMaxGrass;     // 60
uniform float uRangeMaxRock;      // 61
uniform float uRangeMaxForest;    // 62
uniform float uRangeMaxFlower;    // 63
uniform float uRangeMaxShallow;   // 64
uniform float uRangeMaxBeach;     // 65
uniform float uRangeMaxVolcanic;  // 66

// ===== samplers =====
uniform sampler2D uPerm1;   // 0
uniform sampler2D uPerm2;   // 1
uniform sampler2D uPerm3;   // 2
uniform sampler2D uAtlasA;  // 3

out vec4 fragColor;

// ===== 常量 =====
const float SAFE_SHIFT = 1048576.0;
const float INV_256    = 1.0/256.0;
const int   MAX_OCT    = 8;
const float ATLAS_PAD_PX = 2.0;

// ==== int helpers ====
int imax(int a, int b) { return (a > b) ? a : b; }
int imin(int a, int b) { return (a < b) ? a : b; }
int iclamp(int x, int a, int b) { return imin(imax(x, a), b); }

// ===== fBm / Perlin =====
float fade5(float t){ return t*t*t*(t*(t*6.0-15.0)+10.0); }
float permAt1(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm1, vec2(x,0.5)).r*255.0; }
float permAt2(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm2, vec2(x,0.5)).r*255.0; }
float permAt3(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm3, vec2(x,0.5)).r*255.0; }

float gradDot(float h,float x,float y){
  float idx=mod(h,8.0);
  vec2 g=(idx<0.5)?vec2(1,1):(idx<1.5)?vec2(-1,1):(idx<2.5)?vec2(1,-1):(idx<3.5)?vec2(-1,-1)
  :(idx<4.5)?vec2(1,0):(idx<5.5)?vec2(-1,0):(idx<6.5)?vec2(0,1):vec2(0,-1);
  return dot(g, vec2(x,y));
}

float perlinX(vec2 p,int which){
  vec2 pf=floor(p), f=p-pf;
  float X=mod(pf.x,256.0), Y=mod(pf.y,256.0);
  float pY  = (which==1?permAt1(Y):which==2?permAt2(Y):permAt3(Y));
  float pY1 = (which==1?permAt1(Y+1.0):which==2?permAt2(Y+1.0):permAt3(Y+1.0));
  float aa  = (which==1?permAt1(X+pY)      :which==2?permAt2(X+pY)      :permAt3(X+pY));
  float ab  = (which==1?permAt1(X+pY1)     :which==2?permAt2(X+pY1)     :permAt3(X+pY1));
  float ba  = (which==1?permAt1(X+1.0+pY)  :which==2?permAt2(X+1.0+pY)  :permAt3(X+1.0+pY));
  float bb  = (which==1?permAt1(X+1.0+pY1) :which==2?permAt2(X+1.0+pY1) :permAt3(X+1.0+pY1));
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa,f.x,    f.y),     gradDot(ba,f.x-1.0,f.y),     u);
  float x2=mix(gradDot(ab,f.x,    f.y-1.0), gradDot(bb,f.x-1.0,f.y-1.0), u);
  return mix(x1,x2,v);
}

float fbm_core(vec2 p,int oct,float freq,float pers,float pxPerWorld,float lodEnable,float lodNyquist,int ch){
  float total=0.0, amp=1.0, sumAmp=0.0, f=freq;
  float period = 256.0 / f;
  vec2 pEff = p + mod(uWorldBase, vec2(period));
  for(int i=0;i<MAX_OCT;++i){
    float base=step(float(i),float(oct-1));
    float span=f/pxPerWorld;
    float vis=mix(1.0, step(span,lodNyquist), lodEnable);
    float m=base*vis;
    float n=perlinX(pEff*f, ch);
    total+=n*amp*m; sumAmp+=amp*m;
    amp*=pers; f*=2.0;
  }
  return (sumAmp>0.0)?(total/sumAmp):0.0;
}
float fbm1(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,1);}
float fbm2(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,2);}
float fbm3(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,3);}

// ===== period / 变体 =====
float biomePeriod(int idx){
  if (idx==0) return uPeriodSnow;
  if (idx==1) return uPeriodGrass;
  if (idx==2) return uPeriodRock;
  if (idx==3) return uPeriodForest;
  if (idx==4) return uPeriodFlower;
  if (idx==5) return uPeriodShallow;  // 海
  if (idx==6) return uPeriodBeach;
  return uPeriodVolcanic;
}
float varOffset(int idx){
  if (idx==0) return uVarOffsetSnow;
  if (idx==1) return uVarOffsetGrass;
  if (idx==2) return uVarOffsetRock;
  if (idx==3) return uVarOffsetForest;
  if (idx==4) return uVarOffsetFlower;
  if (idx==5) return uVarOffsetShallow;
  if (idx==6) return uVarOffsetBeach;
  return uVarOffsetVolcanic;
}
float varCountF(int idx){
  if (idx==0) return uVarCountSnow;
  if (idx==1) return uVarCountGrass;
  if (idx==2) return uVarCountRock;
  if (idx==3) return uVarCountForest;
  if (idx==4) return uVarCountFlower;
  if (idx==5) return uVarCountShallow;
  if (idx==6) return uVarCountBeach;
  return uVarCountVolcanic;
}

// ===== UV/导数：平铺 & 护边（SkSL 不支持导数 → 置零） =====
void tiledUVGrad(vec2 world, float period, out vec2 uv, out vec2 ddx, out vec2 ddy) {
  float p = max(period, 1.0e-6);
  vec2 unwrapped = (world + uWorldBase) / p; // tile-space
  uv  = fract(unwrapped);
  ddx = vec2(0.0); // dFdx(unwrapped);
  ddy = vec2(0.0); // dFdy(unwrapped);
}

// 用占位 33/34 传 atlas 像素宽高（替代 textureSize）
vec2 insetFromPixels(vec2 grid, float px){
  vec2 atlasPx = vec2(uABBlend, uMixMode);  // 33=width, 34=height
  atlasPx = max(atlasPx, vec2(256.0));      // 兜底，避免 0
  vec2  tilePx = atlasPx / max(grid, vec2(1.0));
  vec2  inset  = vec2(px) / tilePx;
  return clamp(inset, vec2(0.0), vec2(0.45));
}

// 名字保留 sampleAtlasAGrad，但内部用普通 texture（SkSL 无 textureGrad）
vec3 sampleAtlasAGrad(vec2 baseUV, vec2 ddx, vec2 ddy, int tileIndex) {
  vec2 grid = max(uAtlasGrid, vec2(1.0));
  float cols = grid.x;
  float fi   = float(tileIndex);
  float col  = mod(fi, cols);
  float row  = floor(fi / cols);

  // 单元格像素（含边框）
  vec2 atlasPx = max(vec2(uABBlend, uMixMode), vec2(1.0));
  vec2 cellPx  = atlasPx / grid;
  vec2 padNrm  = vec2(ATLAS_PAD_PX) / cellPx;     // 归一化边框

  // 将 [0,1] 的 tile-UV 映射到“单元格内内容区”
  // 注意：这里不是“再裁一次边”，而是**恰好剔除掉挤出的 2px 边框**，内容仍然完整 0..1 周期
  vec2 local = mix(padNrm, 1.0 - padNrm, baseUV);

  vec2 uvAtlas = (local + vec2(col, row)) / grid;
  return texture(uAtlasA, uvAtlas).rgb;
}

// ======== 海洋专用：双层滚动 + 流向扭曲（就地动画；导数置零） ========
struct LayerUV { vec2 uv; vec2 ddx; vec2 ddy; };

LayerUV oceanLayerUV(vec2 world, float period, vec2 scroll, float amp, vec2 freq, vec2 speed) {
  float p = max(period, 1.0e-6);

  vec2 s = (world + uWorldBase) / p + scroll * uTime; // tile-space 坐标
  vec2 uv = fract(s);

  float phx = TAU * (freq.x * s.x + 0.7 * s.y) + speed.x * uTime;
  float phy = TAU * (0.8 * s.x + freq.y * s.y) + speed.y * uTime;
  vec2  warp = amp * vec2(sin(phx), cos(phy));

  LayerUV outv;
  outv.uv  = fract(uv + warp);
  outv.ddx = vec2(0.0); // 原本 dFdx 链式法则，这里统一置零
  outv.ddy = vec2(0.0);
  return outv;
}

// ===== 二次均分：同一地形的概率区间 → 均分到该地形的 N 张纹理 =====
vec3 sampleBiome(int idx, vec2 world, float mixedValue){
  int count = int(floor(max(varCountF(idx), 0.0)));
  if (count <= 0) return vec3(0.0, 0.5, 0.75);

  float period = biomePeriod(idx);
  float p = max(period, 1.0e-6);

  // 1) 把 "mixedValue" 映射到【当前地形的本地 0..1 概率轴】localT
  float localT;
  if (idx == 5) {
    // 海洋是两段并集：[0,0.40) 和 (0.60,1.0]，各占 40%。
    // 折叠到同一个 [0,1) 区间保证均匀：
    if (mixedValue < 0.40) localT = mixedValue / 0.40;               // 0..1
    else                   localT = (mixedValue - 0.60) / 0.40;       // 0..1
  } else {
    // 非海洋：直接把中间带 [0.40, 0.60] 压成本地 [0,1)
    localT = (mixedValue - 0.40) / 0.20;                              // 可能越界
  }
  localT = clamp(localT, 0.0, 1.0 - 1e-6);

  // 2) 二次均分：[0,1) 均分为 count 段，落在哪段就用第几张纹理
  float k  = localT * float(count);
  int   sub = int(floor(k));                       // 0..count-1

  int baseIndex = int(floor(max(varOffset(idx), 0.0)));
  int first = baseIndex;
  int last  = baseIndex + imax(count - 1, 0);
  int tileIndex = iclamp(baseIndex + sub, first, last);

  // 3) 采样——非海洋静态平铺，海洋维持双层滚动扭曲（两层同一张索引，保证概率不乱）
  if (idx == 5) {
    LayerUV A = oceanLayerUV(world, p, OCEAN_SCROLL_A, OCEAN_WARP_AMP_A, OCEAN_WARP_FREQ_A, OCEAN_WARP_SPEED_A);
    LayerUV B = oceanLayerUV(world, p, OCEAN_SCROLL_B, OCEAN_WARP_AMP_B, OCEAN_WARP_FREQ_B, OCEAN_WARP_SPEED_B);
    vec3 colA = sampleAtlasAGrad(A.uv, A.ddx, A.ddy, tileIndex);
    vec3 colB = sampleAtlasAGrad(B.uv, B.ddx, B.ddy, tileIndex);
    vec2 tileId = floor((world + uWorldBase) / p); // 只用于呼吸相位
    float wob = 0.5 + clamp(OCEAN_BLEND_WOBBLE, 0.0, 0.5)
    * sin(uTime * 0.7 + dot(tileId, vec2(0.1, -0.07)));
    return mix(colA, colB, wob);
  } else {
    vec2 uv, ddx, ddy;
    tiledUVGrad(world, p, uv, ddx, ddy);
    return sampleAtlasAGrad(uv, ddx, ddy, tileIndex);
  }
}

// ===== main（你的群系选择保持不变） =====
void main(){
  vec2 frag=FlutterFragCoord().xy;
  float pxPerWorld=max(uScale,1.0e-6);
  vec2  world=uWorldTopLeft + frag/pxPerWorld;

  int   oct=int(clamp(floor(uOctaves+0.5),1.0,float(MAX_OCT)));
  float per=clamp(uPersistence,0.2,0.9);
  float f   =max(uFreq,1.0e-12);
  float le  =(uLodEnable>0.5)?1.0:0.0;
  float ln  =max(uLodNyquist,1.0e-6);

  // fBm 只用于索引混合，不直接上色
  float h1=(fbm1(world,                  oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h2=(fbm2(world+vec2(SAFE_SHIFT), oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h3=(fbm3(world-vec2(SAFE_SHIFT), oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float mixed=clamp(h1*0.4 + h2*0.3 + h3*0.3, 0.0, 1.0);

  int idx;
  if (mixed < 0.40 || mixed > 0.60) { idx = 5; } // 海
  else {
    float norm = (mixed - 0.40) / 0.20;
    idx = int(clamp(floor(norm * 8.0), 0.0, 7.0));
  }

  vec3 base = sampleBiome(idx, world, mixed);
  fragColor = vec4(base, 1.0);
}
