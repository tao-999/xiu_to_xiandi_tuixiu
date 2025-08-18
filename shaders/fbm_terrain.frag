#include <flutter/runtime_effect.glsl>

// ---------- uniforms (与 Dart setFloat 顺序一致) ----------
uniform vec2  uResolution;    // 0,1
uniform vec2  uWorldTopLeft;  // 2,3
uniform float uScale;         // 4 (px/world)
uniform float uFreq;          // 5
uniform float uTime;          // 6  // 目前未使用，但保留接口
uniform float uOctaves;       // 7
uniform float uPersistence;   // 8
uniform float uSeed;          // 9
uniform float uDebug;         // 10
uniform float uLodEnable;     // 11
uniform float uLodNyquist;    // 12
uniform vec2  uWorldBase;     // 13,14

// 海洋参数 15~23（接口保留，不参与渲染逻辑）
uniform float uOceanEnable;   // 15
uniform float uSeaLevel;      // 16
uniform float uOceanAmp;      // 17
uniform float uOceanSpeed;    // 18
uniform float uOceanChoppy;   // 19
uniform float uSunTheta;      // 20
uniform float uSunStrength;   // 21
uniform float uFoamWidth;     // 22
uniform float uFoamIntensity; // 23

uniform sampler2D uPerm1;     // 0
uniform sampler2D uPerm2;     // 1
uniform sampler2D uPerm3;     // 2

out vec4 fragColor;

// ---------- 常量 & 调色 ----------
const float SAFE_SHIFT = 1048576.0;   // 2^20，用于 decorrelate
const float INV_256    = 1.0/256.0;
const int   MAX_OCT    = 8;

// 与 Dart 端 _terrainDefs 顺序一致（0..7）
const vec3 C0=vec3(0.937,0.937,0.937); // snow
const vec3 C1=vec3(0.608,0.796,0.459); // grass
const vec3 C2=vec3(0.427,0.416,0.373); // rock
const vec3 C3=vec3(0.231,0.373,0.294); // forest
const vec3 C4=vec3(0.800,0.757,0.608); // flower_field
const vec3 C5=vec3(0.309,0.639,0.780); // shallow_ocean
const vec3 C6=vec3(0.918,0.843,0.714); // beach
const vec3 C7=vec3(0.494,0.231,0.231); // volcanic

// ---------- Perlin fBm（与 CPU 三通道 decorrelate 一致） ----------
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
  float pY =(which==1?permAt1(Y):which==2?permAt2(Y):permAt3(Y));
  float pY1=(which==1?permAt1(Y+1.0):which==2?permAt2(Y+1.0):permAt3(Y+1.0));
  float aa =(which==1?permAt1(X+pY):which==2?permAt2(X+pY):permAt3(X+pY));
  float ab =(which==1?permAt1(X+pY1):which==2?permAt2(X+pY1):permAt3(X+pY1));
  float ba =(which==1?permAt1(X+1.0+pY):which==2?permAt2(X+1.0+pY):permAt3(X+1.0+pY));
  float bb =(which==1?permAt1(X+1.0+pY1):which==2?permAt2(X+1.0+pY1):permAt3(X+1.0+pY1));
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa,f.x,f.y),     gradDot(ba,f.x-1.0,f.y),     u);
  float x2=mix(gradDot(ab,f.x,f.y-1.0), gradDot(bb,f.x-1.0,f.y-1.0), u);
  return mix(x1,x2,v);
}

float fbm_core(vec2 p,int oct,float freq,float pers,float pxPerWorld,float lodEnable,float lodNyquist,int ch){
  float total=0.0, amp=1.0, sumAmp=0.0, f=freq;
  // worldBase 取模以实现“重基无缝”
  float period = 256.0 / f;
  vec2 pEff = p + mod(uWorldBase, vec2(period));

  for(int i=0;i<MAX_OCT;++i){
    float base=step(float(i),float(oct-1));
    // 视距自适应：超 Nyquist 的 octave 直接跳过（减少采样）
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

// ---------- 行带亮度 & 调色 ----------
float rowBrightness(float y){
  float segment=200.0, group=100.0, range=0.10;
  float block=floor(y/segment);
  float local=mod(block,group);
  float mir=(local<=group*0.5)?local:(group-local);
  float stepv=range/(group*0.5);
  return mir*stepv;
}
vec3 pickPalette(int idx){
  float fi=float(idx);
  float w0=1.0-step(0.5,abs(fi-0.0));
  float w1=1.0-step(0.5,abs(fi-1.0));
  float w2=1.0-step(0.5,abs(fi-2.0));
  float w3=1.0-step(0.5,abs(fi-3.0));
  float w4=1.0-step(0.5,abs(fi-4.0));
  float w5=1.0-step(0.5,abs(fi-5.0));
  float w6=1.0-step(0.5,abs(fi-6.0));
  float w7=1.0-step(0.5,abs(fi-7.0));
  return C0*w0+C1*w1+C2*w2+C3*w3+C4*w4+C5*w5+C6*w6+C7*w7;
}

// ---------- main（纯色渲染，性能优先） ----------
void main(){
  vec2 frag=FlutterFragCoord().xy;
  float pxPerWorld=max(uScale,1e-6);
  vec2  world=uWorldTopLeft + frag/pxPerWorld;

  // Debug 0：网格噪声预览
  if(uDebug>0.5 && uDebug<1.5){ vec2 n=fract(world*0.01); fragColor=vec4(n,0.0,1.0); return; }

  // Octave/LOD 参数
  int   oct=int(clamp(floor(uOctaves+0.5),1.0,float(MAX_OCT)));
  float per=clamp(uPersistence,0.2,0.9);
  float f   =max(uFreq,1e-12);
  float le  =(uLodEnable>0.5)?1.0:0.0;
  float ln  =max(uLodNyquist,1e-6);

  // 与 Dart 完全一致的混合高度
  float h1=(fbm1(world,                  oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h2=(fbm2(world+vec2(SAFE_SHIFT), oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h3=(fbm3(world-vec2(SAFE_SHIFT), oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float mixed=clamp(h1*0.4 + h2*0.3 + h3*0.3, 0.0, 1.0);

  // idx 判定：与 Dart 一致（0..7；浅海=5）
  int idx;
  if (mixed < 0.40 || mixed > 0.60) {
    idx = 5; // shallow_ocean
  } else {
    float norm = (mixed - 0.40) / 0.20; // 0..1
    idx = int(clamp(floor(norm * 8.0), 0.0, 7.0));
  }

  // Debug 1：海 mask（白=idx==5）
  if (uDebug > 2.5 && uDebug < 3.5) { fragColor = vec4(vec3(idx==5?1.0:0.0), 1.0); return; }
  // Debug 2：idx 灰度预览（0..7）
  if (uDebug > 3.5 && uDebug < 4.5) { fragColor = vec4(vec3(float(idx)/7.0), 1.0); return; }

  // —— 纯色最终输出（含行带亮度），不做任何海浪/砂石/法线/高光等重特效 —— //
  float bright=rowBrightness(world.y);
  vec3 base = pickPalette(idx);
  vec3 col  = clamp(base + vec3(bright), 0.0, 1.0);

  fragColor = vec4(col, 1.0);
}
