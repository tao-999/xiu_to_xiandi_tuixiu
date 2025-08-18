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

// ---------- fBm（保留你的陆地生成） ----------
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

// ---------- 工具 ----------
float hash11(float n){ return fract(sin(n*127.1 + uSeed*0.123)*43758.5453); }
vec2  rot(vec2 v,float a){ float c=cos(a),s=sin(a); return vec2(c*v.x - s*v.y, s*v.x + c*v.y); }

// ========== 海面（保留你之前的 Gerstner + 预滤） ==========
float k_from_lambda_px(float lambdaPx, float pxPerWorld){
  float lambdaW = lambdaPx / max(pxPerWorld, 1e-6);
  return 6.2831853 / max(lambdaW, 1e-6);
}
float atten_by_samples(float lambdaPx, float minSamples){
  return smoothstep(minSamples, minSamples*3.0, lambdaPx);
}
vec3 flowField(vec2 p,float t){
  float n1=fbm1(p*0.015+vec2(10.3,-7.1)+vec2(t*0.010),4,1.0,0.55,uScale,0.0,1.0);
  float n2=fbm2(p*0.015+vec2(-2.9,12.4)-vec2(t*0.009),4,1.0,0.55,uScale,0.0,1.0);
  vec2 v=vec2(n1,n2);
  float ang=atan(v.y,v.x);
  float mag=clamp(length(v)*0.6,0.05,0.5);
  vec2 vel=normalize(v+1e-6)*mag;
  return vec3(ang,vel.x,vel.y);
}
void gerstner_sum(
vec2 p, float t, float pxw, float baseDir, float ampScale, float chop, float spd,
out float H, out vec2 gradF, out vec2 gradC
){
  H=0.0; gradF=vec2(0.0); gradC=vec2(0.0);

  float screenMin = min(uResolution.x, uResolution.y);
  float LONG_MIN  = 1.10*screenMin, LONG_MAX  = 2.20*screenMin;
  float MID_MIN   = 0.35*screenMin, MID_MAX   = 0.70*screenMin;
  float SHORT_MIN = 0.12*screenMin, SHORT_MAX = 0.22*screenMin;

  const float W_LONG  = 1.00;
  const float W_MID   = 0.30;
  const float W_SHORT = 0.05;

  const float SAMPLES_FINE   = 3.5;
  const float SAMPLES_COARSE = 7.0;

  float speedMul = max(spd, 0.0) * 0.82;

  for(int i=0;i<10;i++){
    float r = hash11(50.0 + float(i) + uSeed*3.7);
    int band = (i<4) ? 0 : (i<8 ? 1 : 2);

    float lambdaPx =
    (band==0) ? mix(LONG_MIN,  LONG_MAX,  hash11(60.0 + float(i)+uSeed)) :
    (band==1) ? mix(MID_MIN,   MID_MAX,   hash11(70.0 + float(i)+uSeed)) :
    mix(SHORT_MIN, SHORT_MAX, hash11(80.0 + float(i)+uSeed));

    float aFine   = atten_by_samples(lambdaPx, SAMPLES_FINE);
    float aCoarse = atten_by_samples(lambdaPx, SAMPLES_COARSE);

    float jitter  = (band==0) ? 0.18 : (band==1 ? 0.55 : 1.00);
    vec2  dir     = rot(vec2(cos(baseDir), sin(baseDir)), (r-0.5)*jitter);
    dir = normalize(dir);

    float k  = k_from_lambda_px(lambdaPx, pxw);
    float w  = sqrt(9.8*k);
    float A0 = (band==0)? W_LONG : (band==1? W_MID : W_SHORT);
    float A  = ampScale * A0 * mix(0.85,1.20,hash11(81.0+float(i)+uSeed));

    float phase = k*dot(p, dir) - w*t*speedMul;

    float s = sin(phase);
    float c = cos(phase);
    H += A * s * aFine;

    vec2 g = A * k * dir * c;
    gradF += g * aFine;
    gradC += g * aCoarse;

    float q = clamp(chop, 0.0, 1.0);
    p += dir * (q*A*c) * aFine * 0.65;
  }
}
vec3 normal_from_grad(vec2 grad){ return normalize(vec3(-grad.x, -grad.y, 1.0)); }
float filteredSpecular(vec3 nCoarse, float fresnel){
  vec3 L = normalize(vec3(cos(uSunTheta), sin(uSunTheta), 0.7));
  vec3 V = vec3(0.0, 0.0, 1.0);
  vec3 H = normalize(L + V);
  float base = pow(max(dot(nCoarse, H), 0.0), 14.0);
  float NdotL = clamp(dot(nCoarse, L), 0.0, 1.0);
  float grazingGate = smoothstep(0.0, 0.30, NdotL);
  float spec = base * grazingGate * clamp(uSunStrength, 0.0, 1.2);
  spec = min(spec, 0.28);
  spec *= mix(0.35, 1.0, fresnel);
  return spec;
}
float foamFactor(float terrainDepth01, float slope, float chop){
  float width=max(uFoamWidth,0.0);
  float nearShore=1.0 - smoothstep(0.0, width+1e-6, terrainDepth01);
  float crest    = smoothstep(0.70, 1.10, slope * (0.95 + 0.75*chop));
  float f = nearShore*0.80 + crest*0.55;
  return clamp(f * uFoamIntensity, 0.0, 1.0);
}

// ========== 带宽安全噪声（沙滩/熔岩共用，静态） ==========
float bandNoise01(vec2 world, float targetPx, int ch){
  float pxw     = max(uScale, 1.0/1024.0);
  float lambdaW = targetPx / pxw;
  float f       = 1.0 / max(lambdaW, 1e-6);
  float vis     = atten_by_samples(targetPx, 2.5);
  float n = perlinX(world * f, ch); // [-1,1]
  n = n*0.5 + 0.5;                  // 0..1
  return mix(0.5, n, vis);          // 采样不足时回中性
}

// ========== 沙滩（idx==6）：颗粒+轻拉丝，静态 ==========
vec3 shadeSand(vec2 world, float pxPerWorld){
  vec3 base = C6;

  float ang = flowField(world*0.05, 0.0).x + 1.5707963;
  vec2  T = vec2(cos(ang), sin(ang));        // 切向（沿岸）
  vec2  B = vec2(-T.y, T.x);                 // 法向（离岸）

  // 静态域扭曲（破相干）
  float wA = bandNoise01(world + vec2(7.2,-3.1), 280.0, 1);
  float wB = bandNoise01(world + vec2(-5.6,8.4), 420.0, 2);
  vec2  disp = ((wA-0.5)*T + (wB-0.5)*B) * (28.0 / max(pxPerWorld,1e-6));
  vec2  p    = world + disp;

  // 大尺度起伏
  float h1 = bandNoise01(p,                  160.0, 3);
  float h2 = bandNoise01(p + vec2(11.3,4.7), 260.0, 1);
  float hill = mix(h1, h2, 0.35);

  // 沿岸“拉丝”：方向导数
  float stepW = 4.0 / max(pxPerWorld,1e-6);
  float hf = bandNoise01(p + T*stepW, 160.0, 3);
  float hb = bandNoise01(p - T*stepW, 160.0, 3);
  float streak  = smoothstep(0.03, 0.10, abs(hf - hb));

  // 细颗粒
  float gA = bandNoise01(world + vec2(9.1,3.7),   4.0, 1);
  float gB = bandNoise01(world + vec2(-4.2,6.8),  5.5, 2);
  float grains = (gA - 0.5) + (gB - 0.5);

  // 极细“沙屑”
  float speck  = bandNoise01(world*1.6 + vec2(21.1,-17.3), 3.2, 2) - 0.5;

  vec3 col = base;
  col *= 0.95 + 0.10*hill;
  col *= 0.97 + 0.06*streak;
  col += vec3(grains) * 0.05;
  col += vec3(speck)  * 0.02;
  col += (hill - 0.5) * vec3(0.03, 0.024, 0.015);

  return clamp(col, 0.0, 1.0);
}

// 更强层级 + 深坑洞（静态）
float ridge(float x){ x = clamp(x,0.0,1.0); return 1.0 - abs(2.0*x - 1.0); }

float basaltHeight(vec2 w){
  // 屏幕像素标定的尺度（大形体/中/小/微）
  float hL = bandNoise01(w + vec2(13.1,-7.9), 220.0, 1);
  float hM = bandNoise01(w + vec2(-9.7,5.3),  110.0, 2);
  float hS = bandNoise01(w + vec2(4.6,11.2),   56.0, 3);
  float hV = bandNoise01(w*1.3 + vec2(-17.0,8.0), 24.0, 1);

  // “气泡孔”感：用 ridged 变形加强坑洞
  float pits = pow(ridge(hS), 1.75) * 0.65 + pow(ridge(hV), 2.2) * 0.35;

  // 高度合成（加权略偏向中小尺度，利于局部起伏）
  float h = 0.42*hL + 0.40*hM + 0.36*pits + 0.18*hV;
  return clamp(h, 0.0, 1.0);
}

// 双尺度法线 + 增益，让凹凸更“立体”
vec3 basaltNormal(vec2 w, float pxPerWorld, float gain){
  float s1 = 1.5 / max(pxPerWorld,1e-6);  // 细
  float s2 = 4.0 / max(pxPerWorld,1e-6);  // 粗

  float hC = basaltHeight(w);
  float hX1 = basaltHeight(w + vec2(s1,0.0));
  float hY1 = basaltHeight(w + vec2(0.0,s1));
  vec2  g1  = vec2(hX1-hC, hY1-hC) / s1;  // 细梯度

  float hX2 = basaltHeight(w + vec2(s2,0.0));
  float hY2 = basaltHeight(w + vec2(0.0,s2));
  vec2  g2  = vec2(hX2-hC, hY2-hC) / s2;  // 粗梯度

  // 混合：把粗形体当主、细节当辅
  vec2 g = mix(g2, g1, 0.6) * gain;

  return normalize(vec3(-g.x, -g.y, 1.0));
}

vec3 shadeLavaBasalt(vec2 world, float pxPerWorld){
  // 基色（暗、微暖）
  const vec3 BASALT_DARK = vec3(0.06, 0.05, 0.05);
  const vec3 BASALT_MID  = vec3(0.12, 0.10, 0.10);
  const vec3 BASALT_WARM = vec3(0.16, 0.13, 0.12);

  // 1) 高度 & 法线（把增益调高些，凹凸更明显）
  float h = basaltHeight(world);
  const float NORMAL_GAIN = 2.25;                  // ← 拉高凹凸
  vec3 n  = basaltNormal(world, pxPerWorld, NORMAL_GAIN);

  // 2) 曲率近似（四邻域拉普拉斯）→ 腔体更暗、鼓包更亮
  float s  = 2.0 / max(pxPerWorld,1e-6);
  float hC = h;
  float hL = basaltHeight(world - vec2(s,0.0));
  float hR = basaltHeight(world + vec2(s,0.0));
  float hD = basaltHeight(world - vec2(0.0,s));
  float hU = basaltHeight(world + vec2(0.0,s));
  float lap = (hL + hR + hD + hU - 4.0*hC);        // >0 鼓包，<0 凹陷
  float cavity = smoothstep(0.00, 0.10, max(0.0, -lap)); // 凹陷AO
  float bulge  = smoothstep(0.00, 0.10, max(0.0,  lap)); // 鼓包提亮

  // 3) 斜率阴影（越陡越暗，类似微自阴影）
  float slope = length(vec2(hR-hL, hU-hD)) / (2.0*s);
  float slopeShadow = 1.0 - smoothstep(0.15, 0.9, slope);

  // 4) 光照（静态）+ 极弱高光（只为增加“石质”质感）
  vec3 L = normalize(vec3(cos(uSunTheta), sin(uSunTheta), 0.55));
  float ndl = dot(n, L);
  float diff = smoothstep(-0.15, 0.9, ndl);        // 包裹式漫反，避免大面积死黑
  vec3  V = vec3(0.0,0.0,1.0);
  vec3  H = normalize(L + V);
  float spec = pow(max(dot(n, H), 0.0), 22.0) * 0.035; // 非常弱

  // 5) 基色随高度略偏暖 + 微孔暗斑
  vec3 base = mix(BASALT_DARK, BASALT_MID, h);
  base = mix(base, BASALT_WARM, 0.14*h);
  float micro = bandNoise01(world*1.7 + vec2(8.3,-6.1), 6.0, 2) - 0.5;
  base += vec3(micro) * (-0.06);

  // 6) AO & 阴影 & 提亮整合
  float amb = 0.34;
  float ao  = clamp(1.0 - 0.65*cavity - 0.25*slope, 0.45, 1.0);
  float lift = 0.10*bulge;                          // 鼓包轻微提亮

  vec3 col = base * (amb + 0.78*diff) * ao * (1.0 + lift) + spec;

  return clamp(col, 0.0, 1.0);
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

  // —— 与 Dart 完全一致的 idx 判定 —— //
  int idx;
  if (mixed < 0.40 || mixed > 0.60) {
    idx = 5; // shallow_ocean
  } else {
    float norm = (mixed - 0.40) / 0.20;       // 0..1
    idx = int(clamp(floor(norm * 8.0), 0.0, 7.0));
  }

  // —— 海洋启用只看 idx==5（统一！）—— //
  float seaLevel=(uSeaLevel>0.0)?clamp(uSeaLevel,0.0,1.0):0.43; // 仍可用于深浅色
  bool isOcean = (uOceanEnable > 0.5) && (idx == 5);

  // ===== 可选调试 =====
  if (uDebug > 7.5 && uDebug < 8.5) { vec3 sand=shadeSand(world, pxPerWorld); fragColor=vec4(sand,1.0); return; }
  if (uDebug > 5.5 && uDebug < 6.5) { vec3 lava=shadeLavaBasalt(world, pxPerWorld); fragColor=vec4(lava,1.0); return; }
  // ===== 调试结束 =====

  if(isOcean){
    // 用 seaLevel 继续生成“深浅感”（不影响是否为海的判定）
    float dLow = clamp((seaLevel - mixed)/max(seaLevel,1e-6), 0.0, 1.0);
    float dHigh= clamp((mixed - (1.0-seaLevel))/max(seaLevel,1e-6), 0.0, 1.0);
    float depth01=max(dLow,dHigh);

    vec2 wpos=world+uWorldBase;
    float t=uTime;

    vec3 ff=flowField(wpos*0.18, t);
    float baseDir = ff.x;
    float amp     = max(uOceanAmp, 0.0);
    float chop    = clamp(uOceanChoppy, 0.0, 1.0);
    float spd     = max(uOceanSpeed, 0.0);

    float H; vec2 gradF, gradC;
    gerstner_sum(wpos, t, pxPerWorld, baseDir, amp, chop, spd, H, gradF, gradC);

    vec3 nFine   = normal_from_grad(gradF);
    vec3 nCoarse = normal_from_grad(gradC);

    vec3 V = vec3(0.0,0.0,1.0);
    float NdotV = clamp(dot(nCoarse, V), 0.0, 1.0);
    float F0 = 0.06;
    float fresnel = F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0);

    vec3 col = mix(WATER_SHALLOW, WATER_DEEP, depth01);
    col *= (0.88 + 0.12*pow(nCoarse.z, 1.6));
    col += vec3(H) * 0.006;

    col += filteredSpecular(nCoarse, fresnel);

    float slope = length(gradF);
    float foamBase = foamFactor(1.0 - depth01, slope, chop);
    float whitecap = smoothstep(0.55, 0.90, 1.0 - nCoarse.z) * (0.4 + 0.6*chop);
    float foamNoise = 0.5 + 0.5 * fbm1(wpos*0.05 + vec2(13.1,-7.2), 2, 1.0, 0.5, pxPerWorld, 0.0, 1.0);
    float foamAll = clamp(max(foamBase, whitecap) * mix(0.88, 1.12, foamNoise), 0.0, 1.0);
    col = mix(col, FOAM_COLOR, foamAll);
    col = mix(col, col*1.15 + vec3(0.03), fresnel*0.15);

    fragColor=vec4(clamp(col,0.0,1.0),1.0);
    return;
  }

  // —— 陆地 —— 沙滩/熔岩写实，其它照旧
  float bright=rowBrightness(world.y);
  if (idx == 6) {
    vec3 sand = shadeSand(world, pxPerWorld);
    fragColor = vec4(clamp(sand + vec3(bright*0.3), 0.0, 1.0), 1.0);
  } else if (idx == 7) {
    vec3 lava = shadeLavaBasalt(world, pxPerWorld); // 暗色玄武岩，静态
    fragColor = vec4(lava, 1.0);
  } else {
    vec3 base=pickPalette(idx);
    fragColor=vec4(clamp(base+vec3(bright), vec3(0.0), vec3(1.0)),1.0);
  }
}