Shader "Water"
{
    Properties
    {
		_WaterShallowColr("WaterShallowColr", Color) = (1,1,1,1)//浅处水的颜色
		_WaterDeepColr("WaterDeepColr", Color) = (1,1,1,1) //深处水的颜色
		_TranAmount("TranAmount",Range(0.001,100)) = 10 //透明度控制。超过这个数值时α设为1。未超过时按与这个的比例获得α。
		_DepthRange("DepthRange",Range(0.001,100)) = 1 //最大显示深度，超过这个时显示为一个颜色(深处水的颜色)。未超过时，按与这个深度的比例进行显示颜色。
		_NormalTex("Normal",2D) = "bump"{} //水波纹的法线
		_WaterSpeed("WaterSpeed" ,float) = 5 //水面法线的移动速度、水面波纹的速度
		_SurfaceScale("SurfaceScale",float)=0.5 //水表面波纹密集程度
		_Specular("Specular",float) = 1 //控制高光，越小高光越明显
		_Gloss("Gloss", float)=0.5 //控制高光，越大高光越明显
		_SpecularColor("SpecularColor", Color) = (1,1,1,1) //高光颜色
		_WaveTex("WaveTex",2D) = "white"{} //波浪纹理
		_NoiseTex("NoiseTex",2D) = "white"{} //噪声图，波浪用，让波浪看起来有更多变化。
		_WaveSpeed("WaveSpeed",float) = 1 //波浪速度
		_WaveRangeA("WaveRangeA",float) = 1 //水深超过这个值的区域无波浪。
		_WaveDelta("WaveDelta",float) = 0.5 //波浪的两次采样的偏差
		_Distortion("Distortion",float) = 0.5 //折射幅度
		_Cubemap("Cubemap",Cube) = "_Skybox"{} //制作反射用
		_FresnelScale("Fresnel",Range(0,1)) = 0.5  //菲涅尔系数，控制折射和反射的比例
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 200
 
		GrabPass{"GrabPass"} //抓屏，设名称为"GrabPass",使用这个名称读取抓屏结果。
 
		Zwrite off
        CGPROGRAM
 
		//自定义光照模型并命名为Water2。因为是透明的所以加alpha。
        #pragma surface surf WaterLight vertex:vert alpha noshadow
 
        #pragma target 3.0
 
		//深度值。固定变量名。老版本需要在摄像机上开启深度才会赋值(现在默认开启了)。加_float可以提高精度。
		//比如可得到水底的土地对相机的深度。如果再减去水面对相机的深度，即可得到水的深度。
		sampler2D_float  _CameraDepthTexture;
 
		sampler2D _NormalTex;
		sampler2D _WaveTex;
		sampler2D _NoiseTex;
		sampler2D GrabPass;
		float4 GrabPass_TexelSize;//GrabPass的图片大小
		samplerCUBE _Cubemap;
 
        struct Input
        {
			float4 proj;//屏幕坐标，得到水的深度用
			float2 uv_NormalTex;
			float2 uv_WaveTex;
			float2 uv_NoiseTex;
			float3 worldRefl;
			float3 viewDir;
			float3 worldNormal; 
			INTERNAL_DATA  //需要获得世界空间的法线向量或反射向量时需要这句。
        };
 
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		fixed4 _WaterDeepColr;
		fixed4 _WaterShallowColr;
		half _TranAmount;
		half _DepthRange;
		half _WaterSpeed;
		half _SurfaceScale;
		half _Specular;
		half _Gloss;
		fixed4 _SpecularColor;
		sampler2D _GTex;
		float _WaveSpeed;
		float _WaveRange;
		float _WaveRangeA;
		float _WaveDelta;
		float _Distortion;
		float _FresnelScale;
 
 
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)
 
		//自定义光照模型，名称为Lighting+上面命名的名称
		fixed4 LightingWaterLight(SurfaceOutput s, fixed3 lightDir, half3 viewDir, fixed atten) 
		{
			float diffuseFactor = max(0, dot(normalize(lightDir), s.Normal)); //漫反射强度
			half3 halfDir = normalize(lightDir + viewDir);
			float nh = max(0, dot(halfDir, s.Normal));
			float spec = pow(nh, s.Specular * 128) * s.Gloss;//高光强度。Specular是材料镜面光泽度越小亮斑越大，Gloss是材料镜面反射颜色强度，Gloss调大高光更加明显。
			fixed4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diffuseFactor + _SpecularColor.rgb * spec * _LightColor0.rgb) * atten;
			c.a = s.Alpha + spec * _SpecularColor.a;
			return c;
		}
 
		void vert(inout appdata_full v, out Input i) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, i);//初始化i
 
			//将裁剪空间下的顶点坐标作为屏幕坐标
			//ComputeScreenPos的结果不是屏幕坐标或uv坐标，而是把裁剪空间坐标从[-w,w]转成 [0,w]。 tex2Dproj在采样的时候会除以w分量。
			i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
			//计算视口空间的depth储存到浮点数变量。其实就是-UnityObjectToViewPos( v.vertex ).z。
			COMPUTE_EYEDEPTH(i.proj.z);
			
			
		}
 
        void surf (Input IN, inout SurfaceOutput o)
        {
			//tex2Dproj采样屏幕空间。
			//LinearEyeDepth与SAMPLE_DEPTH_TEXTURE_PROJ或DECODE_EYEDEPTH等同？传入深度纹理中的深度值（范围0~1）,即可计算出实际的深度值(视角深度的线性值)。补充：Linear01Depth：转换为世界空间下0~1的深度值。
			//tex2dproj 与tex2d基本一样，只是在采样前，tex2Dproj将输入的UV xy坐标除以其w坐标，为了将坐标映射到透视投影(裁剪空间坐标分量w归一的时候使用)
			//UNITY_PROJ_COORD:处理平台差异，一般直接返回输入的值；
			//读取_CameraDepthTexture后使用r通道得到深度值。
			half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.proj)).r);
			//用深度减该(水面)片元深度得到水深
			half deltaDepth = depth - IN.proj.z;
 
			//深度超过_DepthRange这个的都显示为一个颜色。未超过的，按与这个深度的比例显示颜色。当然最终显示颜色还和α值有关。
			fixed4 c = lerp(_WaterShallowColr, _WaterDeepColr, min(_DepthRange, deltaDepth)/ _DepthRange);
 
			//如果只是采样一次法线并只进行一个方向的偏移，效果是水向一个方向流动而非水面波光粼粼的感觉。
			//需要两次采样不同点进行融合。这里两次分别采样了两个根据左上到右下的对角线对称的两个点。或许是这个原因，都往x方向偏移也没有明显的向某个方向流动的感觉。
			float4 bumpOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_WaterSpeed * _Time.x, 0));
			float4 bumpOffset2 = tex2D(_NormalTex, float2(1-IN.uv_NormalTex.y,IN.uv_NormalTex.x)  + float2(_WaterSpeed * _Time.x, 0));
			float4 offsetColor = (bumpOffset1 + bumpOffset2) / 2;
			//法线要先偏移融合，再UnpackNormal。
			float2 offset = UnpackNormal(offsetColor).xy * _SurfaceScale;//_SurfaceScale控制水波密集程度。
 
			//如果直接以之前的偏移和融合得到的法线作为法线，看起来像两张移动的图片而非混乱的水面波纹。为了更好的效果，只用之前的法线取得一个偏移，再进行一次采样。
			float4 bumpColor1 = tex2D(_NormalTex, IN.uv_NormalTex + offset + float2(_WaterSpeed * _Time.x, 0));
			float4 bumpColor2 = tex2D(_NormalTex, float2(1 - IN.uv_NormalTex.y, IN.uv_NormalTex.x) + offset + float2(_WaterSpeed * _Time.x, 0));
			float3 normal = UnpackNormal((bumpColor1 + bumpColor2) / 2).xyz;
			
 
			//岸边的波浪。在水浅处出现。
			half waveIntensity = 1 - min(_WaveRangeA, deltaDepth) / _WaveRangeA;//根据深度控制是否有波浪，让波浪出现在近岸。deltaDepth>=_WaveRangeA时无波浪。
			fixed4 noiserColor = tex2D(_NoiseTex, IN.uv_NoiseTex);//对噪声图采样
			//各部分作用： waveIntensity-让不同深度有区别；三角函数-随时间循环；noiserColor-随机性(随uv变化))；offset-加点变化，也可以不要；_WaveSpeed-两次采样的偏差，形成两组波浪；
			fixed4 waveColor = tex2D(_WaveTex, float2(waveIntensity +  sin(_Time.x * _WaveSpeed + noiserColor.r), 1) + offset);
			//让waveColor的颜色强弱随时间变化
			waveColor.rgb *= (1 - (sin(_Time.x * _WaveSpeed + noiserColor.r) + 1) / 2) * noiserColor.r;
			fixed4 waveColor2 = tex2D(_WaveTex, float2(waveIntensity + sin(_Time.x * _WaveSpeed + _WaveDelta + noiserColor.r), 1) + offset);
			waveColor2.rgb *= (1 - (sin(_Time.x * _WaveSpeed + _WaveDelta + noiserColor.r) + 1) / 2) * noiserColor.r;
			
			
			//抓屏,制作折射效果
			offset = normal.xy * _Distortion * GrabPass_TexelSize.xy;//根据水面波纹的法线进行偏移。
			IN.proj.xy += offset * IN.proj.z;//深度越大，偏移越大。
			//读取偏移位置的颜色作为折射颜色。tex2D与tex2Dproj功能类似，只是需要0~1的uv坐标。
			fixed3 refractionColor = tex2D(GrabPass, IN.proj.xy / IN.proj.w).rgb;
 
			//以反射方向读取_Cubemap中的颜色作为反射颜色。WorldReflectionVector(IN, normal)：世界空间中的反射向量，可理解为这个方向的光能射到水后反射到相机。
			fixed3 reflectionColor = texCUBE(_Cubemap, WorldReflectionVector(IN, normal)).rgb;
 
			//菲涅尔反射,控制折射(水底的光)和反射(水上的光)的比例
			fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(IN.viewDir, WorldNormalVector(IN, normal)), 5);
			//融合折射和反射
			fixed3 refrAndRefl = lerp(reflectionColor, refractionColor, saturate(fresnel));
 
			o.Albedo = (c + (waveColor.rgb + waveColor2.rgb) * waveIntensity) * refrAndRefl;
			
 
		
			o.Normal = normal;
			o.Gloss = _Gloss;
			o.Specular = _Specular;
            
			//透明度控制。超过_TranAmount这个数值的α设为1。未超过的按与这个的比例获得α。
            o.Alpha = min(_TranAmount, deltaDepth) / _TranAmount;
        }
        ENDCG
    }
    FallBack "Diffuse"
}