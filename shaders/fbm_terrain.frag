#include <flutter/runtime_effect.glsl>

// ---- floats（顺序要与 Dart setFloat 对齐）----
uniform vec2  uResolution;    // 0,1
uniform vec2  uWorldTopLeft;  // 2,3
uniform float uScale;         // 4 (px/world)
uniform float uFreq;          // 5
uniform float uTime;          // 6
uniform float uOctaves;       // 7
uniform float uPersistence;   // 8
uniform float uSeed;          // 9
uniform float uDebug;         // 10
uniform float uLodEnable;     // 11
uniform float uLodNyquist;    // 12
uniform vec2  uWorldBase;     // 13,14 ✅ Dart 侧已做基础周期取模

uniform sampler2D uPerm1;     // sampler 0
uniform sampler2D uPerm2;     // sampler 1
uniform sampler2D uPerm3;     // sampler 2

out vec4 fragColor;

const float SAFE_SHIFT = 1048576.0; // 2^20
const float INV_256    = 1.0 / 256.0;
const int   MAX_OCT    = 8;

const vec3 C0 = vec3(0.937,0.937,0.937);
const vec3 C1 = vec3(0.608,0.796,0.459);
const vec3 C2 = vec3(0.427,0.416,0.373);
const vec3 C3 = vec3(0.231,0.373,0.294);
const vec3 C4 = vec3(0.800,0.757,0.608);
const vec3 C5 = vec3(0.309,0.639,0.780);
const vec3 C6 = vec3(0.918,0.843,0.714);
const vec3 C7 = vec3(0.494,0.231,0.231);

float fade5(float t){ return t*t*t*(t*(t*6.0 - 15.0) + 10.0); }

float permAt1(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm1, vec2(x,0.5)).r*255.0; }
float permAt2(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm2, vec2(x,0.5)).r*255.0; }
float permAt3(float i){ float x=(floor(mod(i,256.0))+0.5)*INV_256; return texture(uPerm3, vec2(x,0.5)).r*255.0; }

float gradDot(float h, float x, float y){
  float idx = mod(h, 8.0);
  vec2 g =
  (idx < 0.5) ? vec2( 1.0, 1.0) :
  (idx < 1.5) ? vec2(-1.0, 1.0) :
  (idx < 2.5) ? vec2( 1.0,-1.0) :
  (idx < 3.5) ? vec2(-1.0,-1.0) :
  (idx < 4.5) ? vec2( 1.0, 0.0) :
  (idx < 5.5) ? vec2(-1.0, 0.0) :
  (idx < 6.5) ? vec2( 0.0, 1.0) :
  vec2( 0.0,-1.0);
  return dot(g, vec2(x, y));
}

float perlin1(vec2 p){
  vec2 pf = floor(p), f = p - pf;
  float X = mod(pf.x,256.0), Y = mod(pf.y,256.0);
  float pY=permAt1(Y), pY1=permAt1(Y+1.0);
  float aa=permAt1(X+pY), ab=permAt1(X+pY1), ba=permAt1(X+1.0+pY), bb=permAt1(X+1.0+pY1);
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa, f.x, f.y),     gradDot(ba, f.x-1.0, f.y),     u);
  float x2=mix(gradDot(ab, f.x, f.y-1.0), gradDot(bb, f.x-1.0, f.y-1.0), u);
  return mix(x1, x2, v);
}
float perlin2(vec2 p){
  vec2 pf = floor(p), f = p - pf;
  float X = mod(pf.x,256.0), Y = mod(pf.y,256.0);
  float pY=permAt2(Y), pY1=permAt2(Y+1.0);
  float aa=permAt2(X+pY), ab=permAt2(X+pY1), ba=permAt2(X+1.0+pY), bb=permAt2(X+1.0+pY1);
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa, f.x, f.y),     gradDot(ba, f.x-1.0, f.y),     u);
  float x2=mix(gradDot(ab, f.x, f.y-1.0), gradDot(bb, f.x-1.0, f.y-1.0), u);
  return mix(x1, x2, v);
}
float perlin3(vec2 p){
  vec2 pf = floor(p), f = p - pf;
  float X = mod(pf.x,256.0), Y = mod(pf.y,256.0);
  float pY=permAt3(Y), pY1=permAt3(Y+1.0);
  float aa=permAt3(X+pY), ab=permAt3(X+pY1), ba=permAt3(X+1.0+pY), bb=permAt3(X+1.0+pY1);
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa, f.x, f.y),     gradDot(ba, f.x-1.0, f.y),     u);
  float x2=mix(gradDot(ab, f.x, f.y-1.0), gradDot(bb, f.x-1.0, f.y-1.0), u);
  return mix(x1, x2, v);
}

// ✅ fBm：对每个 octave 用 period=256/f 把 uWorldBase 取模，避免大数带来跳变
float fbm_core(vec2 p, int oct, float freq, float pers, float pxPerWorld, float lodEnable, float lodNyquist, int channel){
  float total=0.0, amp=1.0, sumAmp=0.0, f=freq;
  for (int i=0; i<MAX_OCT; ++i){
    float base = step(float(i), float(oct-1));
    float span = f / pxPerWorld;
    float vis  = mix(1.0, step(span, lodNyquist), lodEnable);
    float m = base * vis;

    float period = 256.0 / f;
    vec2  pEff   = p + mod(uWorldBase, vec2(period));

    float n = (channel==1) ? perlin1(pEff*f)
    : (channel==2) ? perlin2(pEff*f)
    :                perlin3(pEff*f);

    total  += n * amp * m;
    sumAmp += amp * m;
    amp *= pers; f *= 2.0;
  }
  return (sumAmp>0.0)?(total/sumAmp):0.0;
}
float fbm1(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,1);}
float fbm2(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,2);}
float fbm3(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,3);}

float rowBrightness(float worldY){
  float segmentHeight=200.0, groupSize=100.0, offsetRange=0.10;
  float blockIndex=floor(worldY/segmentHeight);
  float localIndex=mod(blockIndex,groupSize);
  float mirrored=(localIndex<=groupSize*0.5)?localIndex:(groupSize-localIndex);
  float maxIndex=groupSize*0.5;
  float stepv=offsetRange/maxIndex;
  return mirrored*stepv;
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
  return C0*w0 + C1*w1 + C2*w2 + C3*w3 + C4*w4 + C5*w5 + C6*w6 + C7*w7;
}

void main(){
  vec2 frag = FlutterFragCoord().xy;

  float pxPerWorld = max(uScale, 1e-6);
  vec2  world      = uWorldTopLeft + frag / pxPerWorld; // 局部世界（基准在 fbm 里加）

  if (uDebug > 0.5 && uDebug < 1.5) {
    vec2 n = fract(world * 0.01);
    fragColor = vec4(n, 0.0, 1.0); return;
  }

  int   oct = int(clamp(floor(uOctaves + 0.5), 1.0, float(MAX_OCT)));
  float per = clamp(uPersistence, 0.2, 0.9);
  float f   = max(uFreq, 1e-12);

  float lodEnable  = (uLodEnable  > 0.5) ? 1.0 : 0.0;
  float lodNyquist = max(uLodNyquist, 1e-6);

  float h1 = (fbm1(world,                    oct, f, per, pxPerWorld, lodEnable, lodNyquist) + 1.0) * 0.5;
  float h2 = (fbm2(world + vec2(SAFE_SHIFT), oct, f, per, pxPerWorld, lodEnable, lodNyquist) + 1.0) * 0.5;
  float h3 = (fbm3(world - vec2(SAFE_SHIFT), oct, f, per, pxPerWorld, lodEnable, lodNyquist) + 1.0) * 0.5;

  float mixed = clamp(h1*0.4 + h2*0.3 + h3*0.3, 0.0, 1.0);

  int idx;
  if (mixed < 0.40 || mixed > 0.60) { idx = 5; }
  else {
    float norm = (mixed - 0.40) / 0.20;
    idx = int(clamp(floor(norm * 8.0), 0.0, 7.0));
  }

  float bright = rowBrightness(world.y);
  vec3  base   = pickPalette(idx);
  vec3  col    = clamp(base + vec3(bright), vec3(0.0), vec3(1.0));
  fragColor    = vec4(col, 1.0);
}
