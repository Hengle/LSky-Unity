Shader "LSky/Simple Clouds"
{

    //Properties{}
    CGINCLUDE
    #include "UnityCG.cginc"
    #include "LSky_Include.hlsl"

    struct appdata
    {
        float4 vertex   : POSITION;
        float2 texcoord : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float2 texcoord : TEXCOORD0;
        half4  col      : TEXCOORD3;
        float4 vertex   : SV_POSITION;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    uniform sampler2D lsky_CloudsTex;
    float4 lsky_CloudsTex_ST;

    uniform half4 lsky_CloudsTint;
    uniform half  lsky_CloudsIntensity;
    
    uniform half lsky_CloudsDensity;
    uniform half lsky_CloudsCoverage;

    uniform half lsky_CloudsSpeed, lsky_CloudsSpeed2;

    v2f vert(appdata_base v)
    {
        v2f o;
        UNITY_INITIALIZE_OUTPUT(v2f, o);

        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        //----------------------------------------------------------------------------

        o.vertex   = LSky_DomeToClipPos(v.vertex);
        o.texcoord = TRANSFORM_TEX(v.texcoord, lsky_CloudsTex);
        //----------------------------------------------------------------------------
             
        o.col.rgb = lsky_CloudsTint.rgb * lsky_CloudsIntensity * lsky_GlobalExposure;
        o.col.a   = normalize(v.vertex.xyz-float3(0.0, 0.05, 0.0)).y*2;
        //----------------------------------------------------------------------------

        return o;
    }

    fixed4 frag(v2f i) : SV_TARGET
    {
        half4 col   = half4(0.0, 0.0, 0.0, 1.0);
        fixed noise  = tex2D(lsky_CloudsTex, i.texcoord + _Time.x * lsky_CloudsSpeed).r;
        fixed noise2 = tex2D(lsky_CloudsTex, i.texcoord + _Time.x * lsky_CloudsSpeed2).r;
        //------------------------------------------------------------------------------

        // Get clouds coverage.
        fixed coverage = ((((noise+noise2) * 0.5) - lsky_CloudsCoverage)); 

        // Get clouds color
        col.rgb  += (1.0 - coverage * lsky_CloudsTint.a) * i.col.rgb;

        // Get clouds alpha.
        col.a   = saturate(coverage * lsky_CloudsDensity * i.col.a);
        //------------------------------------------------------------------------------

        return col;
    }
    ENDCG

    SubShader
    {
        
        Tags{ "Queue"="Background+1745" "RenderType"="Background" "IgnoreProjector"="true" }

        Pass
        {

            Cull Front
            ZWrite Off
            ZTest Lequal
            Blend SrcAlpha OneMinusSrcAlpha
            Fog{ Mode Off }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            ENDCG
        }

    }

}