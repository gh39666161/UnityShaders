Shader "Musa/MusaPBR"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        _MetallicMap("Metallic", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD_BASE"
            Tags {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vertForwardBase
            #pragma fragment fragForwardBase
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

            #include "MusaFwdBase.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags {
                "LightMode"="ForwardAdd"
            }
            CGPROGRAM
            #pragma vertex vertForwardAdd
            #pragma fragment fragForwardAdd
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

            #include "MusaFwdAdd.cginc"
            ENDCG
        }
    }
}
