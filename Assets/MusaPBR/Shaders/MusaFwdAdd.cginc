#include "MusaFwdCore.cginc"
struct ForwardAddInput
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal: NORMAL;
    float4 tangent : TANGENT;
};

struct ForwardAddOutput
{
    float4 pos : SV_POSITION;
};

ForwardAddOutput vertForwardAdd(ForwardAddInput i)
{
    ForwardAddOutput o;
    UNITY_INITIALIZE_OUTPUT(ForwardAddOutput, o);
    return o;
}

half4 fragForwardAdd(ForwardAddOutput i): SV_Target
{
    return half4(1, 1, 1, 1);
}