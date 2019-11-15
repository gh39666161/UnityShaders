#include "UnityCG.cginc"
#include"Lighting.cginc"
#include "AutoLight.cginc"

sampler2D _MainTex;
uniform float4 _MainTex_ST;
float _BumpScale;
sampler2D _BumpMap;
uniform float4 _BumpMap_ST;
sampler2D _MetallicMap;
uniform float4 _MetallicMap_ST;
// struct appdata
// {
//     float4 vertex : POSITION;
//     float2 uv : TEXCOORD0;
//     float2 uv1 : TEXCOORD1;
//     float3 normal: NORMAL;
//     float4 tangent : TANGENT;
// };

// struct v2f
// {
//     float4 pos : SV_POSITION;
//     float4 uv : TEXCOORD0;
//     float4 posWorld : TEXCOORD1;
//     float3 normal : TEXCOORD2;
//     float3 tangent : TEXCOORD3;
//     float3 bitangent : TEXCOORD4;
//     SHADOW_COORDS(5)
//     UNITY_FOG_COORDS(6)
// };

// #if !defined(VERT_SETUP_TANGENT_TO_WORLD_MATRIX)
// #define VERT_SETUP_TANGENT_TO_WORLD_MATRIX(i, o)\
//     o.normal = UnityObjectToWorldNormal(i.normal);\
//     o.tangent = normalize(mul(unity_ObjectToWorld, float4(i.tangent.xyz, 0.0)).xyz);\
//     o.bitangent = normalize(cross(o.normal, o.tangent) * i.tangent.w);
// #endif

// inline float Pow2(float x)
// {
//     return x*x;
// }

// inline float Pow5(float x)
// {
//     return x*x * x*x * x;
// }

// inline float3x3 makeMatrixTBN(v2f i)
// {
//     return float3x3(normalize(i.tangent), normalize(i.bitangent), normalize(i.normal));
// }

inline float3 PixelWorldNormal(float4 normalTex, float4 tangentToWorld[3], float bumpScale)
{
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;
    half3x3 tbn = half3x3(normalize(tangent), normalize(binormal), normalize(normal));

    float3 tangentNormal = UnpackScaleNormal(normalTex, bumpScale);
    return normalize(mul(tangentNormal, tbn)); // 最终的世界空间归一化法线
}

// inline float CustomLambertDiffuseTerm()
// {
//     return 1/UNITY_PI;
// }

// inline float CustomDisneyDiffuseTerm(float roughness, float nv, float nl, float lh)
// {
//     float fd90 = 0.5 + 2 * lh * lh * sqrt(roughness);
//     // Two schlick fresnel term
//     float lightScatter   = (1 + (fd90 - 1) * Pow5(1 - nl));
//     float viewScatter    = (1 + (fd90 - 1) * Pow5(1 - nv));

//     return lightScatter * viewScatter * rcp(UNITY_PI);
// }

// inline float CustomGGXTerm(float a, float nh)
// {
//     //GGX
//     //                a^2
//     //D(h) = --------------------------------
//     //         pi*((a^2-1)*(n·h)^2 + 1)^2
//     float a2 = Pow2(a);
//     return a2*rcp(UNITY_PI*Pow2((a2 - 1)*Pow2(nh) + 1));
// }

// inline float CustomSmithSchlickTerm(float a, float nl, float nv)
// {
//     //in smith model G(l,v,h) = rcp(G(n, l)*G(n, v))

//     //                  1
//     //G(l,v,h) = -----------------
//     //            G(n, l)*G(n, v)
//     //G(n, x) = (n·x)*(1 - k) + k

//     float a2 = Pow2(a);
//     //float k = a2*sqrt(2/UNITY_PI);         //Schlick-Beckmann
//     //float k = a2/2;                        //Schlick-GGX
//     float k =(a2 + 1)*(a2 + 1)/8;            //UE4，就挑NB的抄
//     float GL = rcp(nl*(1 - k) + k);
//     float GV = rcp(nv*(1 - k) + k);
//     return GL*GV;
// }

// inline float CustomFresnelTerm(float F0, float lh)
// {
//     //F(l, h) = F0 + (1 - F0)*(1 - l·h)^5
//     return F0 + (1-F0) * Pow5(1 - lh);
// }

// inline float CustomGGXSpecularTerm(float metallic, float a, float nl, float nv, float nh, float lh)
// {
//     //微表面BRDF公式
//     //            D(h) F(v,h) G(l,v,h)
//     //f(l,v) = ---------------------------
//     //                4(n·l)(n·v)
//     float D = CustomGGXTerm(a, nh);
//     float G = CustomSmithSchlickTerm(a, nl, nv);
//     float F = CustomFresnelTerm(metallic, lh);
//     return 0.25*D*G*F;
// }

// float3 BRDF_GGX(fixed4 albedo, float metallic, float roughness, float3 c, float nl, float nv, float nh, float lh)
// {
//     float a = Pow2(roughness);
//     // float diffuseTerm = CustomLambertDiffuseTerm();
//     float diffuseTerm = CustomDisneyDiffuseTerm(roughness, nv, nl, lh);
//     float specularTerm = CustomGGXSpecularTerm(metallic, a, nl, nv, nh, lh);
//     float3 diffuse = UNITY_PI * c * diffuseTerm * nl;
//     float3 specular = UNITY_PI * c * specularTerm * nl;
//     return albedo.rgb * (diffuse*(1 - metallic) + specular*metallic);
// }

// float3 BRDF_GGX_GI(fixed4 albedo, float metallic, float roughness, float3 c, float nl, float nv, float nh, float lh, float3 ambient, fixed3 skyColor, float reflectAmount)
// {
//     float a = Pow2(roughness);
//     // float diffuseTerm = CustomLambertDiffuseTerm();
//     float diffuseTerm = CustomDisneyDiffuseTerm(roughness, nv, nl, lh);
//     float specularTerm = CustomGGXSpecularTerm(metallic, a, nl, nv, nh, lh);
//     float3 diffuse = UNITY_PI * c * diffuseTerm * nl + ambient;
//     float3 specular = UNITY_PI * c * specularTerm * nl;
//     float3 diffuseColor = albedo.rgb * diffuse * (1 - metallic);
//     float3 specularColor = albedo.rgb * specular * metallic;
//     return lerp(diffuseColor, skyColor, reflectAmount) + specularColor;
// }