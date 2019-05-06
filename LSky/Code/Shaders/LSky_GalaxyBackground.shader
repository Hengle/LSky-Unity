Shader "LSky/Deep Space/LDR/Galaxy Background"
{

    //Properties{}
    CGINCLUDE  
    #include "UnityCG.cginc"
    #include "LSky_Include.hlsl"
    #include "LSky_DeepSpaceCommon.hlsl"
    ENDCG

    SubShader
    {
        Tags{ "Queue"="Background+5" "RenderType"="Background" "IgnoreProjector"= "true" }
        Pass
        {
            Cull Front
            ZWrite Off
            ZTest Lequal
            Blend One One
            Fog{ Mode Off }

            CGPROGRAM

            #pragma vertex vert_gb
            #pragma fragment frag_gb
            #pragma target 2.0

            ENDCG
        }
    }

}