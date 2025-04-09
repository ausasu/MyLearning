Shader "Custom/Translucent"
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
        Tags { "RenderType"="Translucent" }
        LOD 200

        //Blend SrcAlpha OneMinusSrcAlpha // 使用标准透明度混合模式
        //ZWrite Off // 关闭深度写入，避免透明物体渲染问题

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc" // 包含光照相关函数

            // 顶点输入结构
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            // 顶点到片元的结构
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldLightDir : TEXCOORD3;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _TranslucencyColor;
            float _TranslucencyPower;
            float _Distortion;
            float _Power;
            float _Scale;

            // 顶点着色器
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));
                o.worldLightDir = normalize(UnityWorldSpaceLightDir(mul(unity_ObjectToWorld, v.vertex)));
                return o;
            }

            // 片元着色器
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv) * _TranslucencyColor;

                // 基础光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * c.rgb;
                fixed3 diffuse = _LightColor0.rgb * c.rgb * max(0.0, dot(i.worldNormal, i.worldLightDir));

                // 透光效果
                float3 L = i.worldLightDir; // 光源方向
                float3 V = i.worldViewDir; // 观察方向
                float3 N = i.worldNormal; // 法线方向
                float3 H = normalize(L + N * _Distortion); // 带有失真的半角向量
                float I = pow(saturate(dot(V, -H)), _Power) * _Scale; // 背光强度

                fixed3 translucency = _LightColor0.rgb * I * _TranslucencyColor.rgb;

                // 最终颜色
                fixed4 finalColor;
                finalColor.rgb = ambient + diffuse + translucency;
                finalColor.a = 1;
                //finalColor.a = c.a;

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}