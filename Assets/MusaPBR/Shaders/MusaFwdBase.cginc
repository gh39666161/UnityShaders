#include "MusaFwdCore.cginc"
struct ForwardBaseInput
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal: NORMAL;
    float4 tangent : TANGENT;
};

struct ForwardBaseOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 tangentToWorldAndPackedData[3] : TEXCOORD1;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
};

ForwardBaseOutput vertForwardBase(ForwardBaseInput v)
{
    ForwardBaseOutput o;
    UNITY_INITIALIZE_OUTPUT(ForwardBaseOutput, o);
    o.pos = UnityObjectToClipPos(v.vertex);
    float3 posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.tangentToWorldAndPackedData[0].w = posWorld.x;
    o.tangentToWorldAndPackedData[1].w = posWorld.y;
    o.tangentToWorldAndPackedData[2].w = posWorld.z;

    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    o.uv.xy = v.uv;
    return o;
}

half4 fragForwardBase(ForwardBaseOutput i): SV_Target
{
    half4 albedo = tex2D(_MainTex, TRANSFORM_TEX(i.uv.xy, _MainTex));
    half4 metallicTex = tex2D(_MetallicMap, TRANSFORM_TEX(i.uv.xy, _MetallicMap));
    float4 normalTex = tex2D(_BumpMap, TRANSFORM_TEX(i.uv.xy, _BumpMap));

    half metallic = metallicTex.r;
    half smoothness = metallicTex.a;
    half perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
    half roughness = perceptualRoughness*perceptualRoughness;

    float3 N = PixelWorldNormal(normalTex, i.tangentToWorldAndPackedData, _BumpScale);
    float3 posWorld = float3(i.tangentToWorldAndPackedData[0].w, i.tangentToWorldAndPackedData[1].w, i.tangentToWorldAndPackedData[2].w);
    float3 V = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
    float3 L = normalize(_WorldSpaceLightPos0.xyz);
    //预先计算一些常量
    fixed3 R = reflect(-V, N);
    float3 H = normalize(L + V);//h，l和v的半角向量
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));
    float NdotH = saturate(dot(N, H));
    float VdotH = saturate(dot(V, H));
    float LdotH = saturate(dot(L, H));
    
    float3 lightColor =  _LightColor0.xyz;
    half3 diffuse = NdotL*lightColor*albedo.rgb;
    return half4(diffuse, 1);
}