Shader "LSky/Skydome/Preetham And Hoffman Atmosphere"
{
    //Properties{}
    SubShader
    {

        Tags{ "Queue"="Background+1000" "RenderType"="Background" "IgnoreProjector"="True" }
        Pass
        {
            Cull Front 
            ZWrite Off
            ZTest LEqual
            Blend One One
            Fog{ Mode Off }
            
            CGPROGRAM
            #define LSKY_ENABLEMIEPHASE 1

            #include "UnityCG.cginc"   
            #include "LSky_Include.hlsl"
            #include "LSky_PreeHoffAtmosphericScatteringCommon.hlsl"   

            #pragma vertex vert
            #pragma fragment frag 
            #pragma target 2.0

            #pragma multi_compile __ LSKY_PER_PIXEL_ATMOSPHERE
            #pragma multi_compile __ LSKY_ENABLE_MOON_RAYLEIGH
            #pragma multi_compile __ LSKY_APPLY_FAST_TONEMAP 

            const fixed _one = 1.0;

            struct appdata
            {
                float4 vertex   : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float3 nvertex    : TEXCOORD0; 
                half3 sunMiePhase : TEXCOORD1;
                half4 moonMiePhase: TEXCOORD2;
                #ifndef LSKY_PER_PIXEL_ATMOSPHERE
                half3 scatter : TEXCOORD3;
                #endif
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };
    
            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = LSky_DomeToClipPos(v.vertex);
                o.nvertex = normalize(v.vertex.xyz);

                #ifndef LSKY_PER_PIXEL_ATMOSPHERE
                o.scatter.rgb = RenderAtmosphere(o.nvertex.xyz, o.sunMiePhase, o.moonMiePhase.rgb, _one, _one);
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {

                half4 col = half4(0.0, 0.0, 0.0, 1.0);

                #ifndef LSKY_PER_PIXEL_ATMOSPHERE
                col.rgb = i.scatter;
                #else
                i.nvertex.xyz = normalize(i.nvertex.xyz);
                col.rgb = RenderAtmosphere(i.nvertex.xyz, i.sunMiePhase, i.moonMiePhase.rgb, _one, _one);
                #endif

                return col;
            }
            ENDCG
        }
    }

}