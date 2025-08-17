#include <flutter/runtime_effect.glsl>

// ---------- uniforms (与 Dart setFloat 顺序一致) ----------
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
uniform vec2  uWorldBase;     // 13,14

// 海洋参数 15~23（不改名不改序）
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
const float SAFE_SHIFT = 1048576.0;
const float INV_256    = 1.0/256.0;
const int   MAX_OCT    = 8;

const vec3 C0=vec3(0.937,0.937,0.937), C1=vec3(0.608,0.796,0.459),
C2=vec3(0.427,0.416,0.373), C3=vec3(0.231,0.373,0.294),
C4=vec3(0.800,0.757,0.608), C5=vec3(0.309,0.639,0.780),
C6=vec3(0.918,0.843,0.714), C7=vec3(0.494,0.231,0.231);
const vec3 WATER_DEEP=vec3(0.055,0.215,0.345), WATER_SHALLOW=vec3(0.160,0.560,0.675), FOAM_COLOR=vec3(0.95);

// ---------- fBm 基础（保留你原来的） ----------
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
  float pY=(which==1?permAt1(Y):which==2?permAt2(Y):permAt3(Y));
  float pY1=(which==1?permAt1(Y+1.0):which==2?permAt2(Y+1.0):permAt3(Y+1.0));
  float aa=(which==1?permAt1(X+pY):which==2?permAt2(X+pY):permAt3(X+pY));
  float ab=(which==1?permAt1(X+pY1):which==2?permAt2(X+pY1):permAt3(X+pY1));
  float ba=(which==1?permAt1(X+1.0+pY):which==2?permAt2(X+1.0+pY):permAt3(X+1.0+pY));
  float bb=(which==1?permAt1(X+1.0+pY1):which==2?permAt2(X+1.0+pY1):permAt3(X+1.0+pY1));
  float u=fade5(f.x), v=fade5(f.y);
  float x1=mix(gradDot(aa,f.x,f.y),     gradDot(ba,f.x-1.0,f.y),     u);
  float x2=mix(gradDot(ab,f.x,f.y-1.0), gradDot(bb,f.x-1.0,f.y-1.0), u);
  return mix(x1,x2,v);
}
float fbm_core(vec2 p,int oct,float freq,float pers,float pxPerWorld,float lodEnable,float lodNyquist,int ch){
  float total=0.0, amp=1.0, sumAmp=0.0, f=freq;
  for(int i=0;i<MAX_OCT;++i){
    float base=step(float(i),float(oct-1));
    float span=f/pxPerWorld;
    float vis=mix(1.0, step(span,lodNyquist), lodEnable);
    float m=base*vis;
    float period=256.0/f;
    vec2 pEff=p+mod(uWorldBase, vec2(period));
    float n=perlinX(pEff*f, ch);
    total+=n*amp*m; sumAmp+=amp*m;
    amp*=pers; f*=2.0;
  }
  return (sumAmp>0.0)?(total/sumAmp):0.0;
}
float fbm1(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,1);}
float fbm2(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,2);}
float fbm3(vec2 p,int o,float fr,float pe,float s,float le,float ln){return fbm_core(p,o,fr,pe,s,le,ln,3);}

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

// ---------- Ocean（抗“雪花”版） ----------
float hash11(float n){ return fract(sin(n*127.1 + uSeed*0.123)*43758.5453); }
vec2  dirFromHash(float h){ float a=6.2831853*h; return vec2(cos(a),sin(a)); }
vec2  rot(vec2 v,float a){ float c=cos(a),s=sin(a); return vec2(c*v.x - s*v.y, s*v.x + c*v.y); }

// 缓慢流场（只旋转/平移）
vec3 flowField(vec2 p,float t){
  float n1=fbm1(p*0.015+vec2(10.3,-7.1)+vec2(t*0.010),4,1.0,0.55,uScale,0.0,1.0);
  float n2=fbm2(p*0.015+vec2(-2.9,12.4)-vec2(t*0.009),4,1.0,0.55,uScale,0.0,1.0);
  vec2 v=vec2(n1,n2);
  float ang=atan(v.y,v.x);
  float mag=clamp(length(v)*0.6,0.05,0.5);
  vec2 vel=normalize(v+1e-6)*mag;
  return vec3(ang,vel.x,vel.y);
}

// LOD 可见性：像素每波长采样数不足就降权
float lodVis(float k,float pxPerWorld){
  float lambda=6.2831853/max(k,1e-6);
  float samples=lambda*pxPerWorld;           // 每波长像素数
  return smoothstep(1.2, 3.2, samples);      // 阈值略抬高，抑制高频
}

// ① 硬限频：每个波长至少 minSamples 像素（直接掐死走样）
float clampKByScreen(float k, float pxPerWorld, float minSamples){
  float kCrit = (2.0*3.14159265*pxPerWorld)/max(minSamples, 1e-6);
  return min(k, kCrit);
}

// 三波段合成：涌浪(2) + 风浪(4) + 碎浪(3, 极弱)
float oceanHeightCore(vec2 p,float t){
  float speed=max(uOceanSpeed,0.0);
  float ampG =max(uOceanAmp,  0.0);
  float chop =clamp(uOceanChoppy,0.0,1.0);
  float pxw  =max(uScale,1e-6);
  float kBase=0.10/pxw;

  // 轻扭曲（低频，避免规则栅格）
  vec2 warp;
  warp.x=fbm1(p*0.03+vec2(3.7,-2.1)+vec2(t*0.02),3,1.0,0.55,pxw,0.0,1.0);
  warp.y=fbm2(p*0.03+vec2(-1.4,2.9)-vec2(t*0.018),3,1.0,0.55,pxw,0.0,1.0);
  p+=warp*4.0;

  // 局部方向与推进
  vec3 ff=flowField(p*0.22+uWorldBase,t);
  float dir0=ff.x;
  vec2  adv =ff.yz*(0.5*speed)*t;
  vec2  q   =p+adv;

  float sumH=0.0, sumW=0.0;

  // 涌浪（长）
  for(int i=0;i<2;++i){
    float r=hash11(100.0+float(i)+uSeed);
    vec2 d=rot(dirFromHash(r), dir0*0.6+(r-0.5)*0.8);
    float k=kBase*mix(0.18,0.35,hash11(110.0+float(i)+uSeed));
    k = clampKByScreen(k, pxw, 3.0); // ← 新增：硬限频
    float w=lodVis(k,pxw)*mix(0.35,0.55,hash11(120.0+float(i)+uSeed));
    float ph=dot(q,d)*k - t*speed*mix(0.5,0.9,hash11(130.0+float(i)+uSeed));
    sumH+=sin(ph)*w; sumW+=w;
  }

  // 风浪（中）
  for(int i=0;i<4;++i){
    float r=hash11(200.0+float(i)+uSeed);
    vec2 d=rot(dirFromHash(r), dir0+(r-0.5)*0.9);
    float k=kBase*mix(0.7,1.8,hash11(210.0+float(i)+uSeed));
    k = clampKByScreen(k, pxw, 3.0); // ← 新增
    float w=lodVis(k,pxw)*mix(0.6,1.0,hash11(220.0+float(i)+uSeed));
    float ph=dot(q,d)*k - t*speed*mix(0.8,1.4,hash11(230.0+float(i)+uSeed));
    float wv=sin(ph)+0.25*chop*sin(2.0*ph); // ← 略降次谐波
    sumH+=wv*w; sumW+=w;
  }

  // 碎浪（高频，极弱，仅提浪尖）
  for(int i=0;i<3;++i){
    float r=hash11(300.0+float(i)+uSeed);
    vec2 d=rot(dirFromHash(r), dir0+(r-0.5)*1.1);
    float k=kBase*mix(1.9,2.7,hash11(310.0+float(i)+uSeed));
    k = clampKByScreen(k, pxw, 3.2); // ← 新增
    float w=lodVis(k,pxw)*mix(0.08,0.16,hash11(320.0+float(i)+uSeed));
    float ph=dot(q,d)*k - t*speed*mix(1.0,1.6,hash11(330.0+float(i)+uSeed));
    float wv=sin(ph)+0.38*chop*sin(2.0*ph); // ← 略降次谐波
    sumH+=wv*w; sumW+=w;
  }

  return (sumW>0.0?sumH/sumW:0.0)*ampG;
}

// 法线（可指定采样步长倍率）
vec3 oceanNormalWithStep(vec2 wpos,float t,float pxPerWorld,float stepMul){
  float kMin=0.10/max(uScale,1e-6);           // 基准
  float kMax=kMin*3.0;
  float lambdaMin=6.2831853/kMax;
  float eps=clamp(lambdaMin*0.25*stepMul, 1.0/pxPerWorld, 8.0/pxPerWorld);
  float hC=oceanHeightCore(wpos,t);
  float hX=oceanHeightCore(wpos+vec2(eps,0.0),t);
  float hY=oceanHeightCore(wpos+vec2(0.0,eps),t);
  return normalize(vec3(-(hX-hC)/eps, -(hY-hC)/eps, 1.0));
}
vec3 oceanNormal(vec2 wpos,float t,float pxPerWorld){ return oceanNormalWithStep(wpos,t,pxPerWorld,1.0); }

// ② 预滤高光：只用“粗法线”，避免针点闪烁
// 预滤镜面：粗法线 + 屏幕采样限制 + 贴地角抑制 + 强度上限
float filteredSpecular(vec3 nCoarse){
  // 光照向量
  vec3 L = normalize(vec3(cos(uSunTheta), sin(uSunTheta), 0.7));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);

  // 基础高光（只用粗法线，避免针点）
  float base = pow(max(dot(nCoarse, H), 0.0), 14.0);

  // —— 1) 屏幕采样限制：像素对最短波长的“每波长像素数”越少 → 高光越被压 —— //
  float pxw = max(uScale, 1e-6);
  float kMin = 0.10 / pxw;          // 和海面波段一致
  float kMax = kMin * 2.5;          // 海里最高频那档
  float lambdaMin = 6.2831853 / kMax;
  float samples   = lambdaMin * pxw;                 // 每波长像素数
  float lodGate   = smoothstep(1.8, 3.8, samples);   // 要≥~3px/λ 才放得开

  // —— 2) 贴地角抑制：接近地平线的镜面反射最容易出“针点”，拉低 —— //
  float NdotL = clamp(dot(nCoarse, L), 0.0, 1.0);
  float grazingGate = smoothstep(0.0, 0.30, NdotL);  // 地平线附近→0，正对→1

  // —— 3) 强度上限（最后一道保险）—— //
  float spec = base * lodGate * grazingGate * clamp(uSunStrength, 0.0, 1.2);
  return min(spec, 0.35);
}

// ③ 泡沫：近岸为主；远海更苛刻
float foamFactor(float terrainDepth, vec3 nCoarse){
  float width=max(uFoamWidth,0.0);
  float nearShore=1.0 - smoothstep(0.0, width+1e-6, terrainDepth);
  float crest=smoothstep(0.65, 0.90, 1.0 - nCoarse.z);
  float f=nearShore*0.90 + crest*0.10; // 远海权重更低
  return clamp(f*uFoamIntensity, 0.0, 1.0);
}

// ---------- main ----------
void main(){
  vec2 frag=FlutterFragCoord().xy;
  float pxPerWorld=max(uScale,1e-6);
  vec2  world=uWorldTopLeft + frag/pxPerWorld;

  if(uDebug>0.5 && uDebug<1.5){ vec2 n=fract(world*0.01); fragColor=vec4(n,0.0,1.0); return; }

  int   oct=int(clamp(floor(uOctaves+0.5),1.0,float(MAX_OCT)));
  float per=clamp(uPersistence,0.2,0.9);
  float f   =max(uFreq,1e-12);
  float le  =(uLodEnable>0.5)?1.0:0.0;
  float ln  =max(uLodNyquist,1e-6);

  float h1=(fbm1(world,                    oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h2=(fbm2(world+vec2(SAFE_SHIFT),   oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float h3=(fbm3(world-vec2(SAFE_SHIFT),   oct,f,per,pxPerWorld,le,ln)+1.0)*0.5;
  float mixed=clamp(h1*0.4 + h2*0.3 + h3*0.3, 0.0, 1.0);

  int idx;
  if(mixed<0.40 || mixed>0.60) idx=5;
  else { float norm=(mixed-0.40)/0.20; idx=int(clamp(floor(norm*8.0),0.0,7.0)); }

  // —— 保留你的判海逻辑（不会吞掉地形）——
  float seaLevel=(uSeaLevel>0.0)?clamp(uSeaLevel,0.0,1.0):0.43;
  bool isOcean=(uOceanEnable>0.5) && ((mixed<seaLevel) || (idx==5));

  if(isOcean){
    float dLow = clamp((seaLevel - mixed)/max(seaLevel,1e-6), 0.0, 1.0);
    float dHigh= clamp((mixed - (1.0-seaLevel))/max(seaLevel,1e-6), 0.0, 1.0);
    float depth01=max(dLow,dHigh);

    vec2 wpos=world+uWorldBase;
    float t=uTime;

    float h=oceanHeightCore(wpos,t);

    // 细+粗法线（高光/泡沫用粗法线）
    vec3 nFine  = oceanNormalWithStep(wpos,t,pxPerWorld,1.0);
    vec3 nCoarse= oceanNormalWithStep(wpos,t,pxPerWorld,4.0);

    vec3 col = mix(WATER_SHALLOW, WATER_DEEP, depth01);
    col *= (0.88 + 0.12*pow(nCoarse.z, 1.5)); // 用粗法线增强体积感（更稳）
    col += vec3(h)*0.025;                     // 高度轻调色，避免闪

    // 预滤高光（只用粗法线）
    col += filteredSpecular(nCoarse);

    // 近岸泡沫（更保守）
    float foam = foamFactor(1.0 - depth01, nCoarse);
    col = mix(col, FOAM_COLOR, clamp(foam,0.0,1.0));

    fragColor=vec4(clamp(col,0.0,1.0),1.0);
    return;
  }

  // —— 陆地（原调色）——
  float bright=rowBrightness(world.y);
  vec3  base=pickPalette(idx);
  fragColor=vec4(clamp(base+vec3(bright), vec3(0.0), vec3(1.0)),1.0);
}
