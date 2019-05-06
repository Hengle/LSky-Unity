#ifndef LSKY_DEEP_SPACE_COMMON
#define LSKY_DEEP_SPACE_COMMON

///////////////////////////////////////////////////
/// Variables.
///////////////////////////////////////////////////

// Cubemaps.
uniform samplerCUBE lsky_GalaxyBackgroundCubemap;
uniform samplerCUBE lsky_StarsFieldCubemap;
uniform samplerCUBE lsky_StarsFieldNoiseCubemap;

// HDR Cubemap.
half4 lsky_StarsFieldCubemap_HDR;
half4 lsky_GalaxyBackgroundCubemap_HDR;

// Galaxy Background.
uniform half3 lsky_GalaxyBackgroundTint;
uniform half  lsky_GalaxyBackgroundIntensity;
uniform half  lsky_GalaxyBackgroundContrast;

// Stars Field.
uniform half3 lsky_StarsFieldTint;
uniform half  lsky_StarsFieldIntensity;
uniform half  lsky_StarsFieldScintillation;
uniform half  lsky_StarsFieldScintillationSpeed;
uniform float4x4 lsky_StarsFieldNoiseMatrix;

///////////////////////////////////////////////////
///
///////////////////////////////////////////////////
#define LSKY_STARS_FIELD_NOISE_COORDS(vertex) mul((float3x3) lsky_StarsFieldNoiseMatrix, vertex.xyz)

///////////////////////////////////////////////////
/// Structs
///////////////////////////////////////////////////
struct v2f_gb
{
    float4 vertex    : SV_POSITION;
    float3 texcoord  : TEXCOORD0;
    half3  col       : TEXCOORD2;
    UNITY_VERTEX_OUTPUT_STEREO
};

struct v2f_sf
{
    float4 vertex    : SV_POSITION;
    float3 texcoord  : TEXCOORD0;
    float3 texcoord2 : TEXCOORD2;
    half3  col       : TEXCOORD3;
    UNITY_VERTEX_OUTPUT_STEREO
};

////////////////////////////////////////////////
/// Vertex 
////////////////////////////////////////////////

// Galaxy background
v2f_gb vert_gb(appdata_base v)
{
    v2f_gb o;
    UNITY_INITIALIZE_OUTPUT(v2f_gb, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.vertex = LSky_DomeToClipPos(v.vertex);
    o.texcoord = v.vertex.xyz;
    o.col.rgb = LSKY_HORIZON_FADE(v.vertex);

    return o;
}

// Stars Field
v2f_sf vert_sf(appdata_base v)
{
    v2f_sf o;
    UNITY_INITIALIZE_OUTPUT(v2f_sf, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.vertex    = LSky_DomeToClipPos(v.vertex);
    o.texcoord  = v.vertex.xyz;
    o.texcoord2 = LSKY_STARS_FIELD_NOISE_COORDS(v.vertex);
    o.col.rgb   = LSKY_HORIZON_FADE(v.vertex);

    return o;
}

////////////////////////////////////////
/// Fragment
////////////////////////////////////////

// Galaxy Background
fixed4 frag_gb(v2f_gb i) : SV_Target
{
    half4 re = half4(0.0, 0.0, 0.0, 1.0);
    re.rgb   = LSky_CUBE(lsky_GalaxyBackgroundCubemap, lsky_GalaxyBackgroundContrast, i.texcoord.xyz);
    re.rgb  *= lsky_GalaxyBackgroundTint.rgb * i.col.rgb * lsky_GalaxyBackgroundIntensity;

    return re;
}

half4 frag_gb_hdr(v2f_gb i) : SV_Target
{
    half4 re = half4(0.0, 0.0, 0.0, 1.0);
    re.rgb   = LSky_CUBEHDR(lsky_GalaxyBackgroundCubemap, lsky_GalaxyBackgroundCubemap_HDR, lsky_GalaxyBackgroundContrast, i.texcoord.xyz);
    re.rgb  *= lsky_GalaxyBackgroundTint.rgb * i.col.rgb * lsky_GalaxyBackgroundIntensity;

    return re;
}

inline half3 ApplyScintillation(half3 c, float3 coords)
{
    fixed noiseCube = texCUBE(lsky_StarsFieldNoiseCubemap, coords).r;
    return lerp(c.rgb, 2.0 * c.rgb * noiseCube, lsky_StarsFieldScintillation);
}

// Stars Field
fixed4 frag_sf(v2f_sf i) : SV_Target
{
    fixed4 re = half4(0.0, 0.0, 0.0, 1.0);
    re.rgb   = LSky_CUBE(lsky_StarsFieldCubemap, i.texcoord).rgb;
    re.rgb   = ApplyScintillation(re.rgb, i.texcoord2.xyz);
    re.rgb *= lsky_StarsFieldTint.rgb * i.col.rgb * lsky_StarsFieldIntensity;

    return re;
}

half4 frag_sf_hdr(v2f_sf i) : SV_Target
{
    half4 re = half4(0.0, 0.0, 0.0, 1.0);
    re.rgb   = LSky_CUBEHDR(lsky_StarsFieldCubemap, lsky_StarsFieldCubemap_HDR, i.texcoord).rgb;
    re.rgb   = ApplyScintillation(re.rgb, i.texcoord2.xyz);
    re.rgb  *= lsky_StarsFieldTint.rgb * i.col.rgb * lsky_StarsFieldIntensity;

    return re;
}

#endif // LSKY DEEP SPACE COMMON.
