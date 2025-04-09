Shader "Custom/SimpleSpecularBRDF"
{
    Properties
    {
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Specular("Specular", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc" // 包含内置管线的光照相关函数和变量
            #include "AutoLight.cginc" // 包含光照衰减和阴影相关函数

            // 定义PI常量
            #define PI 3.141592653589793

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldViewDir : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3) // 用于阴影计算
            };

            float _Smoothness;
            float _Specular;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldViewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                TRANSFER_SHADOW(o); // 传递阴影坐标
                return o;
            }

            half3 Simple_Specular_BRDF(float3 normalWS, float3 viewDirectionWS, float3 lightDir, float3 lightColor, float attenuation)
            {
                float NdotL = saturate(dot(normalWS, lightDir));
                float3 halfDir = normalize(lightDir + viewDirectionWS);
                float NdotH = dot(normalWS, halfDir);
                float NdotV = dot(normalWS, viewDirectionWS);

                // attenuated radiance
                half3 radiance = lightColor * attenuation * NdotL;

                // specular term
                float denominator = 4 * saturate(dot(normalWS, lightDir)) * saturate(dot(normalWS, viewDirectionWS)) + 0.0001;

                float d1 = (2 / (_Smoothness * _Smoothness + 0.000001)) - 2;
                float d2 = 1 / (PI * _Smoothness * _Smoothness + 0.000001);
                float D = d2 * pow(saturate(NdotH), d1);

                float F = _Specular + (1 - _Specular) * pow(saturate(1 - dot(viewDirectionWS, halfDir)), 5);

                float g1 = _Smoothness * 2 / PI;
                float gl = saturate(NdotL) * (1 - g1) + g1;
                float gv = saturate(NdotV) * (1 - g1) + g1;
                float G = (1.0 / (gl * gv + 1e-5f)) * 0.25;

                float specular = D * F * G / denominator;

                half3 output = specular * radiance;
                return output;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 normalWS = normalize(i.worldNormal);
                float3 viewDirectionWS = normalize(i.worldViewDir);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 使用 UNITY_LIGHT_ATTENUATION 宏计算光照衰减
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                half3 specular = Simple_Specular_BRDF(normalWS, viewDirectionWS, lightDir, _LightColor0.rgb, atten);

                // 基础漫反射
                float3 diffuse = saturate(dot(normalWS, lightDir)) * _LightColor0.rgb * atten;

                // 最终颜色
                float3 finalColor = diffuse + specular;
                return fixed4(finalColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}