Shader "Musa/PBR"
{
    Properties
    {
        _Metal("Metal",2D) = "white"{}
        _Smothness("Smothness", Range(0, 1)) = 1
        _Albedo("Albedo", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump"{}
        _ReflectColor("Reflection Color", Color) = (1, 1, 1, 1)
        _ReflectAmount("Reflection Amount", Range(0, 1)) = 1
        _ReflectCubemap("Reflection Cubemap", Cube) = "_Skybox"{}
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
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //编译所有Pass类型为ForwardBase的shader变体。这些变体会处理不同的光线映射类型和主平行光是否有阴影
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON

            #include "UnityCG.cginc"  
            #include"Lighting.cginc"
            #include "AutoLight.cginc"
            #include "MusaPBR.cginc"

            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Metal;
            float4 _Metal_ST;
            uniform sampler2D _Normal;
            uniform float4 _Normal_ST;
            uniform samplerCUBE _ReflectCubemap;
            uniform float4 _ReflectColor;
            uniform float _ReflectAmount;
            float _Smothness;

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.uv;
                #if defined(LIGHTMAP_ON)
                    o.uv.zw = v.uv1*unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                VERT_SETUP_TANGENT_TO_WORLD_MATRIX(v, o);
                UNITY_TRANSFER_FOG(o, o.pos);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the _Albedo texture
                fixed4 albedo = tex2D(_Albedo, TRANSFORM_TEX(i.uv.xy, _Albedo));
                float3 view = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

                //light & light color
                float3 lightColor = (float3)0;
                float3 light = (float3)0;
                
                #if defined(LIGHTMAP_ON)
                    lightColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv.zw));
                    #ifdef DIRLIGHTMAP_COMBINED
                        fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, i.uv.zw);
                        light = bakedDirTex.xyz;
                        // finalcolor.rgb += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);

                        // #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                        //     ResetUnityLight(o_gi.light);
                        //     o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap (o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
                        // #endif

                    #else // not directional lightmap
                        // o_gi.indirect.diffuse += bakedColor;

                        // #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                        //     ResetUnityLight(o_gi.light);
                        //     o_gi.indirect.diffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld);
                        // #endif

                    #endif
                #else
                    lightColor =  _LightColor0.xyz;
                    light = normalize(_WorldSpaceLightPos0.xyz);
                #endif

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //计算带有ShadowMap采样的光衰信息
                UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld);
                lightColor *= atten;

                //法线转换
                float3x3 tbn = makeMatrixTBN(i);//法线的TBN旋转矩阵
                float4 normalTex = tex2D(_Normal, TRANSFORM_TEX(i.uv.xy, _Normal));
                float3 normal = normalTexToWorldNormal(normalTex, tbn);

                //从metallic图上取数据
                fixed4 metalTex = tex2D(_Metal, TRANSFORM_TEX(i.uv.xy, _Metal));
                float metallic = metalTex.r;//unity metallic 值，是一个grayscale value ，存在 r 通道
                float roughness = 1 - metalTex.a*_Smothness;//unity 用的是smoothness，在metallic map的alpha 通道，这里转换一下

                //预先计算一些常量
                fixed3 r = reflect(-view, normal);
                float3 h = normalize(light + view);//h，l和v的半角向量
                float nl = saturate(dot(normal, light));
                float nv = saturate(dot(normal, view));
                float nh = saturate(dot(normal, h));
                float vh = saturate(dot(view, h));
                float lh = saturate(dot(light, h));

                // fixed3 reflection = texCUBE(_ReflectCubemap, r).rgb * atten;
                half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, r);
                fixed3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

                fixed4 finalcolor = (fixed4)0;
                finalcolor.rgb = BRDF_GGX_GI(albedo, metallic, roughness, lightColor, nl, nv, nh, lh, ambient, skyColor, _ReflectAmount);
                // finalcolor.rgb = lerp(finalcolor.rgb, skyColor, _ReflectAmount);
                // finalcolor.rgb = skyColor;
                finalcolor.a = albedo.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalcolor);
                return finalcolor;
            }
            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //编译所有Pass类型为ForwardAdd的shader变体。这些编译变体用来处理平行光、聚光和点光类型，并且他们的变体会烘焙贴图和光源实时阴影的处理
            #pragma multi_compile_fwdadd_fullshadows

            #include "UnityCG.cginc"  
            #include "AutoLight.cginc"
            #include "MusaPBR.cginc"

            uniform float4 _LightColor0;
            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Metal;
            float4 _Metal_ST;
            uniform sampler2D _Normal;
            uniform float4 _Normal_ST;
            float _Smothness;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.uv;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                VERT_SETUP_TANGENT_TO_WORLD_MATRIX(v, o);
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //light dir & light color
                 float3 light  =(float3)0;
                 float3 lightColor = (float3)0;

                 if(_WorldSpaceLightPos0.w==0)
                 {
                    light = normalize(_WorldSpaceLightPos0.xyz);
                 }
                 else
                 {
                     light =_WorldSpaceLightPos0.xyz- i.posWorld;
                     lightColor =_LightColor0.xyz /(1+length(light));
                     light = normalize(light);
                 }

                float3 view = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

                //法线转换
                float3x3 tbn = makeMatrixTBN(i);//法线的TBN旋转矩阵
                float4 normalTex = tex2D(_Normal, TRANSFORM_TEX(i.uv.xy, _Normal));
                float3 normal = normalTexToWorldNormal(normalTex, tbn);

                //从metallic图上取数据
                fixed4 metalTex = tex2D(_Metal, TRANSFORM_TEX(i.uv.xy, _Metal));
                float metallic = metalTex.r;//unity metallic 值，是一个grayscale value ，存在 r 通道
                float roughness = 1 - metalTex.a*_Smothness;//unity 用的是smoothness，在metallic map的alpha 通道，这里转换一下

                //预先计算一些常量
                float3 h = normalize(light + view);//h，l和v的半角向量
                float nl = saturate(dot(normal, light));
                float nv = saturate(dot(normal, view));
                float nh = saturate(dot(normal, h));
                float vh = saturate(dot(view, h));
                float lh = saturate(dot(light, h));


                // sample the _Albedo texture
                fixed4 albedo = tex2D(_Albedo, TRANSFORM_TEX(i.uv.xy, _Albedo));
                fixed4 finalcolor = (fixed4)0;
                finalcolor.rgb = BRDF_GGX(albedo, metallic, roughness, lightColor, nl, nv, nh, lh);
                finalcolor.a = albedo.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalcolor);
                return finalcolor;
            }
            ENDCG
        }
        
        
        Pass
        {
            Tags { "LightMode"="ShadowCaster" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };
            
            v2f vert (appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
}