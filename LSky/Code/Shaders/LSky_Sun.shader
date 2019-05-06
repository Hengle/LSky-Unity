﻿Shader "LSky/Near Space/Sun"
{

    //Properties{}
    SubShader
    {
        Tags{ "Queue"="Background+15" "RenderType"="Background" "IgnoreProjector"="true" }
        Pass
        {

            Cull Front
            ZWrite Off
            ZTest Lequal
            Blend One One
            Fog{ Mode Off }

            CGPROGRAM

            #include "UnityCG.cginc"
            #include "LSky_Include.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            struct v2f
            {
                float2 texcoord : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                half3 col       : TEXCOORD2;
                float4 vertex   : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform sampler2D lsky_StarTex;
            uniform half4 lsky_StarTint;
            uniform half  lsky_StarIntensity;

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex   = UnityObjectToClipPos(v.vertex);
                o.worldPos = LSKY_WORLD_POS(v.vertex);
                o.texcoord = v.texcoord;

                o.col.rgb = lsky_StarTint.rgb * lsky_StarIntensity * lsky_GlobalExposure;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed4 col = fixed4(0.0, 0.0, 0.0, 1.0);
                col.rgb    = tex2D(lsky_StarTex, i.texcoord).rgb;
                col.rgb   *= i.col.rgb * LSKY_WORLD_HORIZON_FADE(i.worldPos);
                return col;
            }   

            ENDCG
        }
    }

}