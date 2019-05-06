#ifndef LSKY_PREEHTAM_HOFFMAN_ATMOSPHERIC_SCATTERING
#define LSKY_PREEHTAM_HOFFMAN_ATMOSPHERIC_SCATTERING

//#include "UnityCG.cginc"
#include "LSky_AtmosphericScatteringVariables.hlsl"
#include "LSky_AtmosphericScatteringCommon.hlsl"

//////////////////////////////////////////////////
/// Description: Atmospheric Scattering based on 
/// Naty Hoffman and Arcot. J. Preetham papers.
//////////////////////////////////////////////////

//////////////////////
/// Params 
//////////////////////
uniform float lsky_AtmosphereHaziness;
uniform float lsky_AtmosphereZenith;

uniform float lsky_RayleighZenithLength;
uniform float lsky_MieZenithLength;

uniform float3 lsky_BetaRay;
uniform float3 lsky_BetaMie;

uniform float lsky_SunsetDawnHorizon;
uniform half lsky_DayIntensity;
uniform half lsky_NightIntensity;


//////////////////////
/// Optical Depth
//////////////////////

// Optical depth with small changes for more customization.
inline void CustomOpticalDepth(float pos, inout float2 srm)
{
    pos          = saturate(pos * lsky_AtmosphereHaziness); 
    float zenith = acos(pos);
    zenith       = cos(zenith) + 0.15 * pow(93.885 - ((zenith * 180) / UNITY_PI), -1.253);
    zenith       = _rcp(zenith + (lsky_AtmosphereZenith * 0.5));

    srm.x        = zenith * lsky_RayleighZenithLength;
    srm.y        = zenith * lsky_MieZenithLength;
}

// Optimized for mobile devices.
inline void OptimizedOpticalDepth(float pos, inout float2 srm)
{
    pos   = saturate(pos * lsky_AtmosphereHaziness);
    pos   = _rcp(pos + lsky_AtmosphereZenith);
    srm.x = pos * lsky_RayleighZenithLength;
    srm.y = pos * lsky_MieZenithLength;
}

// Combined extinction facto.
inline float3 ComputeCEF(float2 srm)
{
    return exp(-(lsky_BetaRay * srm.x + lsky_BetaMie * srm.y));
}

inline half3 ComputeAtmosphericScattering(float3 ifex, float sunCosTheta, float3 sunMiePhase, float3 moonMiePhase, float depth)
{

    float sunRayleighPhase = LSky_RayleighPhase(sunCosTheta);
    float3 fex = saturate(lerp(1.0-ifex, (1.0-ifex) * ifex, lsky_SunsetDawnHorizon));

    // Sun/Day calculations
    ////////////////////////

    float3 sunBRT = lsky_BetaRay * sunRayleighPhase;

    // Multiply per zdepth
    #if defined(LSKY_ISPOSTPROCESSING)
    float depthmul = depth * lsky_RayleighDepthMultiplier;
    sunBRT *= depthmul;
    #endif

    float3 sunBMT  = lsky_BetaMie * sunMiePhase;
    float3 sunBRMT = (sunBRT + sunBMT) / (lsky_BetaRay + lsky_BetaMie);

    // Scattering result for sun light
    half3 sunScatter = lsky_DayIntensity * (sunBRMT*fex) * lsky_SunAtmosphereTint;

    sunScatter = lerp(sunScatter * (1.0-ifex), sunScatter, lsky_SunAtmosphereTint.a);

    // Moon/Night calculations
    ///////////////////////////

    // Used simple calculations for more performance
    #if defined(LSKY_ENABLE_MOON_RAYLEIGH)
    half3 moonScatter = lsky_NightIntensity.x * (1.0-ifex) * lsky_MoonAtmosphereTint;

    // Multiply per zdepth
    #if defined(LSKY_ISPOSTPROCESSING)
    moonScatter *= depthmul;
    #endif

    // Add moon mie phase
    moonScatter += moonMiePhase;
    return (sunScatter + moonScatter);
    #else
    return (sunScatter + moonMiePhase);
    #endif
}

inline half3 RenderAtmosphere(float3 pos, out float3 sunMiePhase, out float3 moonMiePhase, float depth, float dist)
{
    half3 re         = half3(0.0, 0.0, 0.0);
    half3 multParams = half3(1.0, 1.0, 1.0);

    // Get common multipliers
    #if defined(LSKY_ISPOSTPROCESSING)
    multParams.x = lsky_FogSunMiePhaseMult * (depth * lsky_SunMiePhaseDepthMultiplier);
    multParams.y = lsky_FogMoonMiePhaseMult * (depth * lsky_MoonMiePhaseDepthMultiplier);
    #else
    multParams.z = 1.0 - LSky_GroundMask(pos.y); // Get upper sky mask
    #endif

    // Get dot product of the sun and moon directions
    float2 cosTheta = float2(
    dot(pos.xyz, lsky_LocalSunDirection.xyz), // Sun
    dot(pos.xyz, lsky_LocalMoonDirection.xyz) // Moon
    );

    // Compute post processing y position
    #if defined(LSKY_ISPOSTPROCESSING)
    float p   = saturate(pos.y);
    float d   = saturate(depth + 1.0);  // Down
    float sbf = smoothstep(d, p, lsky_FogBlendColor);
    pos.y     = lerp(sbf, p, lsky_FogSmoothColor);
    #endif

    // Compute optical depth
    float2 srm;
    #if defined(SHADER_API_MOBILE)
    OptimizedOpticalDepth(pos.y, srm);
    #else
    CustomOpticalDepth(pos.y, srm);
    #endif

    // Get combined extinction factor
    float3 fex = ComputeCEF(srm);

    #if defined(LSKY_ENABLEMIEPHASE)
    sunMiePhase   = LSky_PartialMiePhase(cosTheta.x, lsky_PartialSunMiePhase, lsky_SunMieScattering);
    sunMiePhase  *= multParams.x * lsky_SunMieTint.rgb * multParams.z;
    moonMiePhase  = LSky_PartialMiePhase(cosTheta.y, lsky_PartialMoonMiePhase, lsky_MoonMieScattering);
    moonMiePhase *= multParams.y * lsky_MoonMieTint.rgb * multParams.z;
    re.rgb = ComputeAtmosphericScattering(fex, cosTheta.x, sunMiePhase, moonMiePhase, dist);
    #else
    const fixed3 _zero = fixed3(0.0, 0.0, 0.0);
    sunMiePhase = _zero;
    moonMiePhase = _zero;
    re.rgb = ComputeAtmosphericScattering(fex, cosTheta.x, _zero, _zero, dist);
    #endif
    
    // Apply Color correction
    #if defined(LSKY_ISPOSTPROCESSING)
    ApplyColorCorrection(re.rgb, lsky_GlobalExposure, lsky_AtmosphereContrast);
    #else
    ApplyColorCorrection(re.rgb, lsky_GroundColor.rgb, lsky_GlobalExposure, lsky_AtmosphereContrast);
    re = ApplyGroundColor(pos.y, re);
    #endif
    
    return re;
}
/*
inline half3 ComputeAtmosphere(float3 pos, float depth, float dist)
{
    const fixed3 _zero = fixed3(0.0, 0.0, 0.0);
    return half3 ComputeAtmosphere(pos, _zero, _zero, depth, dist);
}*/

#endif // LSKY: PREETHAM AND HOFFMAN ATMOSPHERIC SCATTERING INCLUDED.
