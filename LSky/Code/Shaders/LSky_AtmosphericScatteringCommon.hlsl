#ifndef LSKY_ATMOSPHERIC_SCATTERING_COMMON
#define LSKY_ATMOSPHERIC_SCATTERING_COMMON

/////////////////////////////////////////////////////////////////////
/// For preetham model and eric brunetton model
/// Mie phase multiplier is 1.0/(PI*4)
/// Rayleigh phase multiplier is 3/(PI*16)
/// I use #define to be able to override the value if another models
/////////////////////////////////////////////////////////////////////

// Mie Phase
#ifndef LSKY_MIE_PHASE_MULTIPLIER
#   define LSKY_MIE_PHASE_MULTIPLIER LSKY_INVPI4 
#endif

// Rayleigh Phase.
#ifndef LSKY_RAYLEIGH_PHASE_MULTIPLIER
#   define LSKY_RAYLEIGH_PHASE_MULTIPLIER LSKY_3PI16
#endif

/////////////////////
/// Rayleigh Phase 
/////////////////////
inline float LSky_RayleighPhase(float cosTheta)
{
    return LSKY_RAYLEIGH_PHASE_MULTIPLIER * (1.0 + cosTheta * cosTheta);    
}

////////////////////
/// Mie Phase
////////////////////
inline float3 LSky_PartialMiePhase(float g)
{
    float g2 = g * g;
    return float3((1.0 - g2) / (2.0 + g2), 1.0 + g2, 2.0 * g);
}

inline float LSky_MiePhase(float cosTheta, float g, half scattering)
{
    float3 PHG = LSky_PartialMiePhase(g);
    return (LSKY_MIE_PHASE_MULTIPLIER * PHG.x * ((1.0 + cosTheta * cosTheta) * pow(PHG.y - (PHG.z * cosTheta), -1.5))) * scattering;
}

inline float LSky_PartialMiePhase(float cosTheta, float3 partialMiePhase, half scattering)
{
    return
    (
        LSKY_MIE_PHASE_MULTIPLIER * partialMiePhase.x * ((1.0 + cosTheta * cosTheta) *
        pow(partialMiePhase.y - (partialMiePhase.z * cosTheta), -1.5))
    ) * scattering;
}

//////////////////////
/// Color Correction 
//////////////////////

inline void ApplyColorCorrection(inout half3 col, half exposure, half contrast)
{
    // Apply tonemap
    #if defined(LSKY_APPLY_FAST_TONEMAP)
    col.rgb = LSky_FastTonemap(col.rgb, exposure);
    #else
    col.rgb *= exposure;
    #endif

    // Contrast
    col.rgb = LSky_Pow2(col.rgb, contrast);

    // Color space
    #if defined(UNITY_COLORSPACE_GAMMA)
    col.rgb = LSKY_LINEAR_TO_GAMMA(col.rgb);
    #endif

}

inline void ApplyColorCorrection(inout half3 col, half3 groundCol, half exposure, half contrast)
{
    ApplyColorCorrection(col.rgb, exposure, contrast);

    #ifdef UNITY_COLORSPACE_GAMMA
    groundCol.rgb *= groundCol.rgb;
    #endif
}

inline half LSky_GroundMask(in float pos)
{
    return saturate(-pos*100);
}

inline half3 ApplyGroundColor(float pos, half3 skyCol)
{
    fixed mask = LSky_GroundMask(pos);
    return lerp(skyCol.rgb, lsky_GroundColor.rgb * skyCol, mask);
}
/*
inline half3 ApplyGroundColor(float pos, half3 skyCol)
{

    fixed mask = LSky_GroundMask(pos);
    half3 skyContribution =  skyCol * smoothstep(-0.42, 4.2, pos + lsky_GroundColor.a) * mask;
    return  lerp(skyCol.rgb, lsky_GroundColor.rgb * min(0.75, skyCol), mask) + skyContribution;
}*/

#endif // LSKY: ATMOSPHERIC SCATTERING COMMON INCLUDED.