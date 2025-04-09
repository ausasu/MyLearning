Shader "ToonShader/AlphaShadow" {
	Properties {
		_AlphaScale ("透明程度", Range(0, 1)) = 1
        _ShadowColor ("阴影颜色", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed _AlphaScale;
            fixed4 _ShadowColor;
			
			struct a2v {
				float4 vertex : POSITION;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				SHADOW_COORDS(1)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			 	TRANSFER_SHADOW(o);
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {

			 	fixed atten = SHADOW_ATTENUATION(i);
				return fixed4(_ShadowColor.rgb * unity_IndirectSpecColor * _LightColor0.rgb, saturate(1-atten) * _AlphaScale);
			}
			
			ENDCG
		}
	} 
	FallBack "VertexLit"
}
