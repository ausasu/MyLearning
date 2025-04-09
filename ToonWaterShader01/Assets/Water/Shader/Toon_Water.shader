Shader "Toon/Toon_Water01"
{
    Properties
    {
        [Header(Color)]
        _Color ("漫反射颜色", Color) = (0, 0.15, 0.115, 1)
        _CubeMap ("立方体纹理", Cube) = "_Skybox" {}
        [HideInInspector]_SurfaceNoise ("表面noise贴图", 2D) = "white" {}
        [HideInInspector]_SurfaceNoiseScr ("扰动noise贴图", 2D) = "white" {}
        [HideInInspector]_SurfaceCut   ("noise裁剪", Range(0, 3)) = 0.7
        [Header(Wave)]
        _WaveMap ("扰动图", 2D) = "bump" {}
        _WaveXSpeed ("水平扰动速度", Range(-10, 10)) = 0
        _WaveYSpeed ("垂直扰动速度", Range(-10, 10)) = 0
        _Distortion ("扰动强度", float) = 1
        
        [Header(Depth)]
        _DepthDistance ("水面颜色距离", Float) = 1
        _ColorGradient1 ("水面边缘颜色 (透明度控制扰动)", Color) = (1, 1, 1, 1)
        _ColorGradient2 ("水面中心颜色 (透明度控制扰动)", Color) = (0.5, 1, 1, 1)

        [Header(Fresnel)]
        _FresnelInt ("菲涅尔强度", Range(0, 4)) = 0.1
        _fresnelColor ("菲涅尔颜色", color) = (0.5, 0.5, 0.5, 0.5)
        
        [Header(Specular)]
        [HDR] _SpecularColor ("高光颜色", Color) = (1, 1, 1, 1)
        _Smoothness ("高光粗糙度", Range(0.0, 1.0)) = 0.5
        _Number ("高光边缘（小于高光大小）", float) = 1
        _Number2 ("高光大小", float) = 1

        [Header(SSS)]
        _WaterScatterMap ("水面ramp", 2D) = "white" {}
        _RampColor ("ramp颜色", color) = (1, 1, 1, 1)
        [HideInInspector]_SSSstrength ("SSS强度", float) = 1.0
        _SSSPower ("SSS幂", float) = 1.0
        _SSSscale ("SSS大小", float) = 1.0
        _SSSDistort ("SSS扰动", Range(-1, 1)) = 1.0

        [Header(Foam)]
        _foamSpeed ("泡沫流动速度", float) = 1.0
        _foamDistance ("泡沫宽度", float) = 5
        _foamWidth ("泡沫间距", Range(0.4, 4)) = 1
        _foamFade ("泡沫消失", Range(0, 1)) = 1
        _foamColor ("泡沫颜色", color) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }

        // 将当前屏幕的内容捕获到一个纹理中，这个纹理可以被后续的 Pass 采样和使用
        GrabPass { "_RefractionTex" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off  // 关闭深度缓存写入，就是也渲染后面的物体
            
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma vertex vert
            #pragma fragment frag

            float4 _Color;
            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;
            sampler2D _SurfaceNoiseScr;
            float4 _SurfaceNoiseScr_ST;
            float  _SurfaceCut;
            sampler2D _WaveMap;
            float4   _WaveMap_ST;
            samplerCUBE _CubeMap;
            fixed _WaveXSpeed;
            fixed _WaveYSpeed;
            float _Distortion;
            // 使用的GrabPass { "_RefractionTex" }
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;  // 得到该纹理的大小，确保偏移量与纹理分辨率相匹配

            float _FresnelInt;
            float4 _fresnelColor;
            float4 _SpecularColor;
            float  _Smoothness;

            sampler2D _CameraDepthTexture;  // 脚本附加到摄像机得到深度纹理
            sampler2D _CameraOpaqueTexture; // 记录不透明物体信息

            float  _DepthDistance;
            float4 _ColorGradient1;
            float4 _ColorGradient2;

            sampler2D _ReflectionTex;    // 获得反射纹理

            float _Number;
            float _Number2;

            sampler2D _WaterScatterMap;
            float4 _WaterScatterMap_ST;
            float4 _RampColor;
            float3 _SSSstrength;
            float  _SSSPower;
            float  _SSSscale;
            float  _SSSDistort;

            float _foamSpeed;
            float _foamDistance;
            float _foamWidth;
            float _foamFade;
            float4 _foamColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
                float4 TtoW1 : TEXCOORD3;
                float4 TtoW2 : TEXCOORD4;
                SHADOW_COORDS(5)
                UNITY_FOG_COORDS(6)
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  // 顶点坐标变换到剪切坐标

                o.scrPos = ComputeGrabScreenPos(o.pos);         // 得到被抓取屏幕图像的采样坐标
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _SurfaceNoise);  // xy分量获取漫反射贴图
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);  // zw分量获取法线贴图

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;   // 变换顶点位置
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);    // 变换法线位置
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); // 变换切线位置
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;  // 计算副切线位置

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o);
                UNITY_TRANSFER_FOG(o, o.pos);

                return o;
            }

            /***BRDF高光****/
            half3 Simple_Specular_BRDF(float3 normalWS, float3 viewDirectionWS, float3 lightDir, float3 lightColor, float attenuation)
            {
                float NdotL = saturate(dot(normalWS, lightDir));
                float3 halfDir = normalize(lightDir + viewDirectionWS);
                float NdotH = dot(normalWS, halfDir);
                float NdotV = dot(normalWS, viewDirectionWS);

                
                half3 radiance = lightColor * attenuation * NdotL;

                float denominator = 4 * saturate(dot(normalWS, lightDir)) * saturate(dot(normalWS, viewDirectionWS)) + 0.0001;

                float d1 = (2 / (_Smoothness * _Smoothness + 0.000001)) - 2;
                float d2 = 1 / (UNITY_PI * _Smoothness * _Smoothness + 0.000001);
                float D = d2 * pow(saturate(NdotH), d1);

                float F = _SpecularColor + (1 - _SpecularColor) * pow(saturate(1 - dot(viewDirectionWS, halfDir)), 5);

                float g1 = _Smoothness * 2 / UNITY_PI;
                float gl = saturate(NdotL) * (1 - g1) + g1;
                float gv = saturate(NdotV) * (1 - g1) + g1;
                float G = (1.0 / (gl * gv + 1e-5f)) * 0.25;

                float specular = D * F * G / denominator;

                half3 output = specular * radiance;
                return output;
            }

            /***快速SSS反射***/
            float3 SSS(float DepthWaterDiff, float3 lightDir, float3 viewDir, float3 normal, float3 SSSstrength, float SSSPower, float SSSscale, float SSSDistort){
                float3 halfDir = normalize(lightDir + normal * SSSDistort);
                float  VdotH   = pow(saturate(dot(viewDir, - halfDir)), SSSPower) * SSSscale;
                //float3 I       = SSSstrength * (VdotH ) ;
                float4 colorRamp = tex2D(_WaterScatterMap, float2(DepthWaterDiff, 0.2));
                
                return  _LightColor0  * VdotH *colorRamp * _RampColor.rgb;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 准备向量
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 viewDir  = normalize(UnityWorldSpaceViewDir(worldPos));  // 获取观察方向向量
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir  = normalize(lightDir + viewDir);
                float2 speed    = _Time.y * float2(_WaveXSpeed * 0.01, _WaveYSpeed * 0.01);

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                // 计算深度
                float  Depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r;  // 对深度纹理采样
                float3 positionVS = mul(UNITY_MATRIX_V, float4(worldPos, 1)).xyz;  // 从世界空间转到屏幕空间
                float  d = length(positionVS.xyz / positionVS.z);   // 归一化深度值
                float  DepthBottom = LinearEyeDepth(Depth01) * d;   // 底部的深度值
                float  DepthWater  = length(_WorldSpaceCameraPos - worldPos); // 水面的深度值
                float  DepthDiff   = abs(DepthBottom - DepthWater);  // 求深度差

                // 通过深度混合颜色
                float DepthWaterDiff = saturate(DepthDiff / _DepthDistance);
                float4 ColorGradient = lerp(_ColorGradient1, _ColorGradient2, DepthWaterDiff);  // lerp需要归一化，不然颜色会很怪
                
                // 得到切线空间的法线
                fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
                fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
                fixed3 bump  = normalize(bump1 + bump2);
                
                // 计算切线空间下的偏移（扰动）
                float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy * 100;
                i.scrPos.xy = offset * i.scrPos + i.scrPos.xy;  // 加上w上的分量，确保深度正确
                fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb ;  // 除以深度，进行归一化

                // 计算向量
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                float NdotL = max(0, dot(bump, lightDir));
                float NdotV = max(0, dot(bump, viewDir));
                float NdotH = max(0, dot(bump, halfDir));
                float LdotH = max(0, dot(lightDir, halfDir));
                fixed3 reflDir  = reflect(-viewDir, bump);
                fixed3 CubeCol  = texCUBE(_CubeMap, reflDir).rgb;  // 采样天空球

                // 反射
                float4 ReflectionRT = tex2D(_ReflectionTex, i.scrPos.xy / i.scrPos.w);    // 采样反射贴图
                               
                // 扰动、反射、加上颜色
                float3 RefraScene = lerp(refrCol, ColorGradient.rgb, ColorGradient.a);    // 扰动加上颜色
                float3 ReflecColor = lerp(ReflectionRT, ColorGradient.rgb, ColorGradient.a);   // 平面反射加上颜色
                float3 RefraRefle = lerp(RefraScene, ReflecColor, ColorGradient.a);       // 扰动颜色和平面颜色混合

                // 菲涅尔
                fixed fresnel = 0.02 + (1 - 0.02) * pow(1 - saturate(dot(viewDir, bump)), 5);
                fresnel = saturate(fresnel * _FresnelInt);
                float3 fresnelColor = lerp(RefraRefle, CubeCol, fresnel) * _fresnelColor;
                //float3 Cube = fresnel * CubeCol;
                //float3 fresnelColor = lerp(RefraScene, ReflecColor, fresnel);    // 菲涅尔混合，感觉不好看
                //float fresnelSmo = step(0.01, fresnel);
                //fixed3 finalColor = ReflecColor * fresnelSmo + RefraRefle * (1 - fresnelSmo);
                //float3 f = lerp(RefraScene, RefraRefle, fresnelSmo);

                // 高光
                float3 specularPBL2 = Simple_Specular_BRDF(bump, viewDir, lightDir, _LightColor0.rgb, atten);  // BRDFG高光
                //float3 specularPBL2Step = smoothstep(_Number, _Number2, specularPBL2);
                //float phong = step(_Number, max(0, dot(reflDir, viewDir)) * _SpecularColor.rgb);
                //fixed3 specular = _SpecularColor.rgb * smoothstep(0.8, 0.88, pow(max(0, dot(reflect(-lightDir, bump), viewDir)), 5));
                fixed3 specular2 = smoothstep(_Number, _Number2, pow(max(0, specularPBL2), 5));   // 控制光源大小
                //fixed specular3 = step(0.7, specular2);
                //float3 specular2Color = lerp(RefraRefle, _SpecularColor.rgb, specular2);   // 混合水面颜色
                //fixed4 specular = _SpecularColor.rgba * fresnel;

                // 反光，利用noise图,下次再看
                //float SurfaceNoiCut = step(_SurfaceCut, SurNoise);

                // 次表面散射
                float3 SSSColor = SSS(DepthWaterDiff, lightDir, viewDir, bump, _SSSstrength, _SSSPower, _SSSscale, _SSSDistort);

                // 泡沫
                //float2 noiseUV = i.scrPos.xy;

                //float SurfaceCut = DepthWaterDiff * _SurfaceCut;
                //fixed SurNoise = normalize(step(SurfaceCut, tex2D(_SurfaceNoise, i.scrPos.xy / i.scrPos.w ).r)); // 采样

                //float foamTexCol = tex2D(_SurfaceNoise, float2(DepthWaterDiff , DepthWaterDiff));
                float foamScope = 1 - saturate(DepthDiff / _foamFade);
                float foam = _foamWidth * sin(_foamDistance * DepthWaterDiff - _Time.y * _foamSpeed);
                float foamstep = smoothstep(0.5, 0.4, foam);
                float4 foamColor = foamstep * foamScope * _foamColor.rgba;
                
                float4 waterFincol = (float4(specular2 + (RefraRefle + SSSColor + fresnelColor) * _LightColor0, 1) + foamColor * _LightColor0)* _Color;
                
                UNITY_APPLY_FOG(i.fogCoord, waterFincol);  // 雾效
                return waterFincol;
                //return fixed4(specular2 + (RefraRefle + SSSColor + fresnelColor) * _LightColor0 + foamColor * _LightColor0, 1);
            }
            ENDCG
        }
    }
    Fallback Off
}
