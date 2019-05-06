#ifndef LSKY_INCLUDE
#define LSKY_INCLUDE


///////////////////////////////////////////////////
// PI.
///////////////////////////////////////////////////
#define LSKY_TAU 6.283185307f       // PI*2
#define LSKY_INVTAU 0.159154943f    // 1/(PI*2)
#define LSKY_HALFPI 1.570796326f    // PI/2
#define LSKY_INVHALFPI 0.636619772f // 1/(PI/2)
#define LSKY_PI4 12.56637061f       // PI*4
#define LSKY_INVPI4 0.079577472f    // 1/(PI*4)
#define LSKY_3PIE 0.119366207f      // 3/(PI*8)
#define LSKY_3PI16 0.059683104f     // 3/(PI*16)

///////////////////////////////////////////////////
/// Utility
///////////////////////////////////////////////////

// Reciprocal
inline float _rcp( float x)
{
    return 1.0/x;
}

///////////////////////////////////////////////////
// Horizon Fade
///////////////////////////////////////////////////
#define LSKY_HORIZON_FADE(vertex) saturate(2 * normalize(mul((float3x3)unity_ObjectToWorld, vertex.xyz)).y)
#define LSKY_WORLD_HORIZON_FADE(pos) saturate(normalize(pos).y)


//////////////////////////////////////////////////////
/// Position.
//////////////////////////////////////////////////////

// WorldPos.
#define LSKY_WORLD_POS(vertex) mul(lsky_WorldToObject, mul(unity_ObjectToWorld, vertex)).xyz;

// 4x4 Matrices.
uniform float4x4 lsky_WorldToObject;
uniform float4x4 lsky_ObjectToWorld;

// Dome Clip Pos.
inline float4 LSky_DomeToClipPos(in float3 position)
{
    float4 pos = UnityObjectToClipPos(position);

    #ifdef UNITY_REVERSED_Z
        pos.z = 1e-5f;
    #else
        pos.z = pos.w - 1e-5f;
    #endif

    return pos;
}

// Celestials Directions.
uniform float3 lsky_LocalSunDirection;
uniform float3 lsky_LocalMoonDirection;
uniform float3 lsky_WorldSunDirection;
uniform float3 lsky_WorldMoonDirection;

////////////////////////////////////
/// Color correction
////////////////////////////////////

// Color Space
#ifdef SHADER_API_MOBILE
#define LSKY_LINEAR_TO_GAMMA(color) sqrt(color)
#else
#define LSKY_LINEAR_TO_GAMMA(color) pow(color, 0.45454545f)
#endif

// HDR
uniform half lsky_GlobalExposure; 

// Fast tonemap
inline half LSky_FastTonemap(half c, half exposure)
{
    return 1.0 - exp(exposure * -c);
}

inline half3 LSky_FastTonemap(half3 c, half exposure)
{
    return 1.0 - exp(exposure * -c);
}

inline half4 LSky_FastTonemap(half4 c, half exposure)
{
    return half4(LSky_FastTonemap(c.rgb, exposure).rgb, c.a);
}

// Only for debug.
inline half3 LSky_ACESTonemap(half3 col, half exposure)
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (col * (a * col + b)) / (col *(c * col + d) +e);
}

// Exponent.
inline half LSky_Pow2(half x, in half fade)
{ 
    return lerp(x, x*x, fade);
}

inline half3 LSky_Pow2(half3 x, in half fade)
{ 
    return lerp(x, x*x, fade);
}

inline half LSky_Pow3(half x, in half fade)
{ 
    return lerp(x, x*x*x, fade);
}

inline half3 LSky_Pow3(half3 x, in half fade)
{ 
    return lerp(x, x*x*x, fade);
}

////////////////////////////
/// Cubemap.
////////////////////////////
inline half3 LSky_CUBEHDR(samplerCUBE cubemap, inout float4 cubemapHDR, float3 coords)
{
    half3 re   = half3(0.0, 0.0, 0.0);
    half4 cube = texCUBE(cubemap, coords);
    re         = DecodeHDR(cube, cubemapHDR);
    re        *= unity_ColorSpaceDouble.rgb * lsky_GlobalExposure;

    return re.rgb;
}

inline half3 LSky_CUBE(samplerCUBE cubemap,  float3 coords)
{
    half3 re   = half3(0.0, 0.0, 0.0);
    half4 cube = texCUBE(cubemap, coords);
    re         = cube.rgb * lsky_GlobalExposure;

    return saturate(re.rgb);
}

inline half3 LSky_CUBEHDR(samplerCUBE cubemap, inout float4 cubemapHDR, float contrast, float3 coords)
{
    half3 re   = half3(0.0, 0.0, 0.0);
    half4 cube = texCUBE(cubemap, coords);
    re         = DecodeHDR(cube, cubemapHDR);
    re        *= unity_ColorSpaceDouble.rgb * lsky_GlobalExposure;

    return LSky_Pow3(re.rgb, contrast);
}

inline half3 LSky_CUBE(samplerCUBE cubemap, float contrast, float3 coords)
{
    half3 re   = half3(0.0, 0.0, 0.0);
    half4 cube = texCUBE(cubemap, coords);
    re         = cube.rgb * lsky_GlobalExposure;

    return saturate(LSky_Pow3(re.rgb, contrast));
}


#endif // LSKY INCLUDED.
