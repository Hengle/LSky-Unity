#ifndef LSKY_FOG_COMMON
#define LSKY_FOG_COMMON

///////////////////////////////////////////////////
// Distance
///////////////////////////////////////////////////
inline float LSky_FogDistance(float depth)
{
    float dist = depth * _ProjectionParams.z;
    return dist - _ProjectionParams.y;
}

///////////////////////////////////////////////////
/// Fog Factor
///////////////////////////////////////////////////

// See: https://docs.microsoft.com/en-us/windows/desktop/direct3d9/fog-formulas
inline float LSky_FogExpFactor(float depth, float density)
{
    float dist = LSky_FogDistance(depth);
    return 1.0 - saturate(exp2(-density * dist));
}

inline float LSky_FogExp2Factor(float depth, float density)
{
    float re = LSky_FogDistance(depth);
    re       = density * re;
    return 1.0 - saturate(exp2(-re * re));
}

inline float LSky_FogLinearFactor(float viewDir, float2 startEnd)
{
    float dist = LSky_FogDistance(viewDir);
    dist       = (startEnd.y - dist) / (startEnd.y - startEnd.x);
    return 1.0 - saturate(dist);
}

#endif // LSKY FOG INCLUDED.
