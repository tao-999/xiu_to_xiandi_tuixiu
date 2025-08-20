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

// A/B 混合控制（占位）
uniform float uABBlend;         // 33
uniform float uMixMode;         // 34

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

// ===== UV/导数：平铺 & 护边 =====
void tiledUVGrad(vec2 world, float period, out vec2 uv, out vec2 ddx, out vec2 ddy) {
  float p = max(period, 1.0e-6);
  vec2 unwrapped = (world + uWorldBase) / p; // tile-space
  uv  = fract(unwrapped);
  ddx = dFdx(unwrapped);
  ddy = dFdy(unwrapped);
}

vec2 insetFromPixels(vec2 grid, float px){
  ivec2 asz = textureSize(uAtlasA, 0);
  vec2  tilePx = vec2(asz) / max(grid, vec2(1.0));
  vec2  inset  = vec2(px) / tilePx;
  return clamp(inset, vec2(0.0), vec2(0.45));
}

vec3 sampleAtlasAGrad(vec2 baseUV, vec2 ddx, vec2 ddy, int tileIndex) {
  vec2 grid = max(uAtlasGrid, vec2(1.0));
  float cols = grid.x;
  float fi   = float(tileIndex);
  float col  = mod(fi, cols);
  float row  = floor(fi / cols);

  // 护边：每瓦片四周裁 2px + 导数补偿
  vec2 insetPix  = insetFromPixels(grid, 2.0);
  float deriv    = max(length(ddx), length(ddy));
  vec2 inset     = insetPix + vec2(deriv * 2.0);

  vec2 local     = baseUV * (1.0 - 2.0*inset) + inset;
  vec2 dlocaldx  = ddx    * (1.0 - 2.0*inset);
  vec2 dlocaldy  = ddy    * (1.0 - 2.0*inset);

  vec2 uvAtlas   = (local + vec2(col, row)) / grid;
  vec2 duvAdx    = dlocaldx / grid;
  vec2 duvAdy    = dlocaldy / grid;

  return textureGrad(uAtlasA, uvAtlas, duvAdx, duvAdy).rgb;
}

// ======== 海洋专用：双层滚动 + 流向扭曲（就地动画） ========
struct LayerUV { vec2 uv; vec2 ddx; vec2 ddy; };

// 在 tile-space 中计算两层滚动 + 扭曲；扭曲依赖 tile-space + 时间（不是纯色）
LayerUV oceanLayerUV(vec2 world, float period, vec2 scroll, float amp, vec2 freq, vec2 speed) {
  float p = max(period, 1.0e-6);

  // 1) 进入 tile 空间并加入滚动（滚动 = 每秒滚动多少个 tile）
  vec2 s = (world + uWorldBase) / p + scroll * uTime; // tile-space 坐标
  vec2 uv = fract(s);
  vec2 dsdx = dFdx(s);
  vec2 dsdy = dFdy(s);

  // 2) 生成“流向”扭曲（随时间变化），用两组相位叠加
  float phx = TAU * (freq.x * s.x + 0.7 * s.y) + speed.x * uTime;
  float phy = TAU * (0.8 * s.x + freq.y * s.y) + speed.y * uTime;
  vec2  warp = amp * vec2(sin(phx), cos(phy));

  // 3) 提供扭曲后的导数（链式法则）
  vec2 dphx_ds = TAU * vec2(freq.x, 0.7);
  vec2 dphy_ds = TAU * vec2(0.8,    freq.y);

  // J = ∂warp/∂s
  vec2 dw_ds_x = amp * vec2( cos(phx)*dphx_ds.x, -sin(phy)*dphy_ds.x );
  vec2 dw_ds_y = amp * vec2( cos(phx)*dphx_ds.y, -sin(phy)*dphy_ds.y );

  vec2 dlocaldx = dsdx + vec2( dw_ds_x.x*dsdx.x + dw_ds_y.x*dsdx.y,
  dw_ds_x.y*dsdx.x + dw_ds_y.y*dsdx.y );
  vec2 dlocaldy = dsdy + vec2( dw_ds_x.x*dsdy.x + dw_ds_y.x*dsdy.y,
  dw_ds_x.y*dsdy.x + dw_ds_y.y*dsdy.y );

  LayerUV outv;
  outv.uv  = fract(uv + warp);
  outv.ddx = dlocaldx;
  outv.ddy = dlocaldy;
  return outv;
}

// ===== 统一采样入口（对海洋做动画，其他静态） =====
vec3 sampleBiome(int idx, vec2 world, float mixedValue){
  int count = int(floor(max(varCountF(idx), 0.0)));
  if (count <= 0) return vec3(0.0, 0.5, 0.75);

  float period = biomePeriod(idx);

  // 变体选择（稳定不抖）
  vec2 tileId = floor((world + uWorldBase) / max(period, 1.0e-6));
  float h = fract(sin(dot(tileId, vec2(12.9898,78.233))) * 43758.5453);
  int sub = int(floor(h * float(count))); // 0..count-1

  int baseIndex = int(floor(max(varOffset(idx), 0.0)));
  int first = baseIndex;
  int last  = baseIndex + imax(count - 1, 0);
  int tileIndexA = iclamp(baseIndex + sub, first, last);
  int tileIndexB = (count >= 2) ? iclamp(baseIndex + ((sub + 1) % count), first, last) : tileIndexA;

  if (idx == 5) {
    // —— Layer A —— //
    LayerUV A = oceanLayerUV(world, period, OCEAN_SCROLL_A, OCEAN_WARP_AMP_A, OCEAN_WARP_FREQ_A, OCEAN_WARP_SPEED_A);
    vec3 colA = sampleAtlasAGrad(A.uv, A.ddx, A.ddy, tileIndexA);

    // —— Layer B —— //
    LayerUV B = oceanLayerUV(world, period, OCEAN_SCROLL_B, OCEAN_WARP_AMP_B, OCEAN_WARP_FREQ_B, OCEAN_WARP_SPEED_B);
    vec3 colB = sampleAtlasAGrad(B.uv, B.ddx, B.ddy, tileIndexB);

    // —— 动态混合（轻微呼吸感），不改贴图能量 —— //
    float w = 0.5 + clamp(OCEAN_BLEND_WOBBLE, 0.0, 0.5) * sin(uTime * 0.7 + dot(tileId, vec2(0.1, -0.07)));
    return mix(colA, colB, w);
  }

  // 非海洋：静态
  vec2 uv, ddx, ddy;
  tiledUVGrad(world, max(period, 1.0e-6), uv, ddx, ddy);
  return sampleAtlasAGrad(uv, ddx, ddy, tileIndexA);
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
