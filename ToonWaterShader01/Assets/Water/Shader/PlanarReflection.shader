Shader "Reflection/PlanarReflection"
{	
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off  // 关闭深度缓存写入，就是也渲染后面的物体
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 screenPos : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _ReflectionTex;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_ReflectionTex, i.screenPos.xy / i.screenPos.w);
				//或者
				//fixed4 col = tex2Dproj(_ReflectionTex, i.screenPos);
				return col;
			}
			ENDCG
		}
	}
}