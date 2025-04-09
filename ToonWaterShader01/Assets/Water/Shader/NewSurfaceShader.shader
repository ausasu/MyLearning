Shader "Custom/TranslucentShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _TranslucencyColor ("Translucency Color", Color) = (1,1,1,1)
        _TranslucencyPower ("Translucency Power", Range(0.0,1.0)) = 0.5
        _Distortion ("Distortion", Range(0.0,1.0)) = 0.5
        _Power ("Power", Range(0.0,10.0)) = 2.0
        _Scale ("Scale", Range(0.0,1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf StandardTranslucent fullforwardshadows
        #include "UnityPBSLighting.cginc"

        sampler2D _MainTex;
        float4 _TranslucencyColor;
        float _TranslucencyPower;
        float _Distortion;
        float _Power;
        float _Scale;

        struct Input
        {
            float2 uv_MainTex;
        };

        inline fixed4 LightingStandardTranslucent(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
        {
            // Original colour
            fixed4 pbr = LightingStandard(s, viewDir, gi);

            // --- Translucency ---
            float3 L = gi.light.dir; // Light direction
            float3 V = viewDir; // View direction
            float3 N = s.Normal; // Normal direction
            float3 H = normalize(L + N * _Distortion); // Half vector with distortion
            float I = pow(saturate(dot(V, -H)), _Power) * _Scale; // Intensity of the backlight

            // Final add
            pbr.rgb = pbr.rgb + gi.light.color * I * _TranslucencyColor.rgb; // Add translucency color
            return pbr;
        }

        inline void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandard_GI(s, data, gi); // 调用标准 GI 函数处理光照贴图和光照探针[^32^]
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _TranslucencyColor;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}