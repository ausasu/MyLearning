Shader "LearnForShader/Genshin" {
    Properties {
        [Space(20.0)]
        _GenShinShader          ("1身体 2头发 3脸部", Range(1, 3)) = 1
        
        [Space(15.0)]
        [NoScaleOffset]_Diffuse ("颜色贴图", 2D) = "white" {}  // 不显示缩放和偏移面板
        _Fresnel                ("边缘光范围", Range(0.0, 10.0)) = 1.7
        _EdgeLight              ("边缘光强度", Range(0.0, 1.0)) = 0.02
        
        [Space(8.0)]
        [Toggle]_DiffuseAlpha   ("Alpha(是透明 否自发光)", Float) = 0
        _CutOff                 ("透明阈值", Range(0.0, 1.0)) = 1.0
        [HDR]_glow              ("自发光强度", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Space(30.0)]
        [NoScaleOffset]_LightMap  ("LightMap/FaceLight(脸部光照贴图)", 2D) = "white" {}
        _Bright                   ("亮面范围", Float) = 0.99
        _Grey                     ("灰面范围", Float) = 1.08
        _Dark                     ("暗面范围", Float) = 0.55
        _SDFRampColor             ("Face阴影", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Space(30.0)]
        [NoScaleOffset][Normal]_BumpMap  ("法线贴图", 2D) = "bump" {}
        _BumpScale                       ("法线程度", Float) = 1.0

        [Space(30.0)]
        [NoScleOffset]_ramp("Shadow_Ramp", 2D) = "white"{}
        _dayAndNight ("1为白天 0为晚上", Range(0, 1)) = 1
        
        [Space(8.0)]
        _RampIndex0               ("Ramp条数_1.0", Range(1, 5)) = 1
        _RampIndex1               ("Ramp条数_0.7", Range(1, 5)) = 4
        _RampIndex2               ("Ramp条数_0.5", Range(1, 5)) = 3
        _RampIndex3               ("Ramp条数_0.3", Range(1, 5)) = 5
        _RampIndex4               ("Ramp条数_0.0", Range(1, 5)) = 2
        
        [Space(30.0)]
        [NoScaleOffset]_MetalMap  ("金属贴图", 2D) = "white" {}
        _Gloss                    ("高光范围", Range(1.0, 256.0)) = 1.0
        _GlossStrength            ("高光强度", Range(0.0, 1.0)) = 1.0
        _MetalMapColor            ("金属反射颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Space(30.0)]
        _Outline         ("描边粗细", Range(0.0, 2.0)) = 0.3
        _OutlineColor0   ("描边颜色1", Color) = (1.0, 0.0, 0.0, 0.0)
        _OutlineColor1   ("描边颜色2", Color) = (0.0, 1.0, 0.0, 0.0)
        _OutlineColor2   ("描边颜色3", Color) = (0.0, 0.0, 1.0, 0.0)
        _OutlineColor3   ("描边颜色4", Color) = (1.0, 0.5, 1.0, 0.0)
        _OutlineColor4   ("描边颜色5", Color) = (0.5, 1.0, 0.5, 0.0)
        [HideInInspector]_Color   ("Main Color", Color) = (1.0, 0.0, 0.0, 0.0)
        [HideInInspector]_Front   ("Front", Vector) = (0, 0, 0)
        [HideInInspector]_Up      ("Up", Vector) = (0, 0, 0)
        [HideInInspector]_LeftDir ("LeftDir", Vector) = (0, 0, 0)

    }

    SubShader {
        Tags { "RenderType" = "Opaque" "Queue"="Geometry"}
        
        Pass {
            NAME "OUNTLINE"   // 这个pass是渲染描边的

            Cull Front
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float  _CutOff;
            float  _DiffuseAlpha;
            
            sampler2D _LightMap;
            sampler2D _Diffuse;
            
            float  _Outline;
            float4 _OutlineColor0;
            float4 _OutlineColor1;
            float4 _OutlineColor2;
            float4 _OutlineColor3;
            float4 _OutlineColor4;

            // 输入结构
            struct a2v {
                float4 vertex    : POSITION;
                float3 normal    : NORMAL;
                float4 vertColor : COLOR;
                float4 tangent   : TANGENT;
                float4 uv        : TEXCOORD0;
            };

            // 输出结构
            struct v2f {
                float4 pos : SV_POSITION;
                float3 vertColor : COLOR;
                float4 uv : TEXCOORD0;

            };

            // 输入结构>>顶点>>输出结构
            v2f vert(a2v v) {
                v2f o;

                UNITY_INITIALIZE_OUTPUT(v2f, o);  // 确保变量初始化为0
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.tangent.xyz); // 转换到视角方向
                float2 OffNormal = mul(UNITY_MATRIX_P, float4(viewNormal.xy, 0, 1)).xy;  // 变换法线到NDC空间

                pos.xy += _Outline * OffNormal.xy * v.vertColor.a * 0.0001;//顶点色a通道控制粗细
                o.pos = pos;
                o.uv = v.uv;
                o.vertColor = v.vertColor.rgb;

                return o;
            }

            // 输出结构>>像素shader
            fixed4 frag(v2f i) : SV_TARGET {
                // 采样贴图
                float4 lightMap  = tex2D(_LightMap, i.uv).rgba;
                float  diffuseA  = tex2D(_Diffuse, i.uv).a;

                // 分离lightmap.a各材质
                float lightMapA2 = step(0.25, lightMap.a);  // 0.3
                float lightMapA3 = step(0.45, lightMap.a);  // 0.5
                float lightMapA4 = step(0.65, lightMap.a);  // 0.7
                float lightMapA5 = step(0.95, lightMap.a);  // 1.0

                // 重组lightmap.a
                float3 OutlineColor = _OutlineColor0;  // 0.0
                OutlineColor = lerp(OutlineColor, _OutlineColor1, lightMapA2);  // 0.3
                OutlineColor = lerp(OutlineColor, _OutlineColor2, lightMapA3);  // 0.5
                OutlineColor = lerp(OutlineColor, _OutlineColor3, lightMapA4);  // 0.7
                OutlineColor = lerp(OutlineColor, _OutlineColor4, lightMapA5);  // 1.0
                
                if(_DiffuseAlpha){
                    diffuseA = smoothstep(0.05, 0.7, diffuseA);   // 去除噪点
                    clip(diffuseA - _CutOff);
                }
                
                return float4 (OutlineColor , 0.0);
            }

            ENDCG
        }
        
        // 这个pass只处理平行光，不处理其他光源
        Pass {
            
            Cull off    // 关闭背面剔除
            
            Tags { "LightMode"="ForwardBase" }  // 设置前向渲染base

            CGPROGRAM

            #pragma multi_compile_fwdbase   // unity中处理base和add两个pass时使用的,第一个是fwdbase，第二个是fwdadd
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float     _GenShinShader;

            sampler2D _Diffuse;
            float4    _Diffuse_ST;
            float     _Fresnel;
            float     _EdgeLight;

            float     _DiffuseAlpha;
            float     _CutOff;
            float4    _glow;

            sampler2D _LightMap;
            float     _Bright;
            float     _Grey;
            float     _Dark;
            float4    _SDFRampColor;

            sampler2D _BumpMap;
            float4    _BumpMap_ST;
            float     _BumpScale;

            sampler2D _ramp;
            float     _dayAndNight;

            float     _RampIndex0;
            float     _RampIndex1;
            float     _RampIndex2;
            float     _RampIndex3;
            float     _RampIndex4;

            sampler2D _MetalMap;
            float     _Gloss;
            float     _GlossStrength;
            float4    _MetalMapColor;

            float     _Outline;
            float4    _OutlineColor0;
            float4    _OutlineColor1;
            float4    _OutlineColor2;
            float4    _OutlineColor3;
            float4    _OutlineColor4;
            float4    _Color;

            float3     _Front;
            float3     _Up;
            float3     _LeftDir;


            // 输入结构
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;      // 法线
                float4 tangent : TANGENT;    // 切线
                float4 texcoord : TEXCOORD0; // uv
            };

            // 输出结构
            struct v2f {
                float4 pos   : SV_POSITION;
                float4 uv    : TEXCOORD0;    // 顶点信息
                fixed4 TtoW0 : TEXCOORD1;    // x切线，y副切线，z法线，w顶点
                fixed4 TtoW1 : TEXCOORD2;
                fixed4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)             // 投影
            };

            // 输入结构>>顶点>>输出结构
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 裁剪空间的顶点信息
                o.uv.xy = v.texcoord.xy * _Diffuse_ST.xy + _Diffuse_ST.zw;   // 一套uv储存漫反射
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;   // 储存法线贴图

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;    // 顶点位置
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);     // 法线方向
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  // 切线方向 
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   // 叉积求得副切线方向

                // 构建矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); // 添加内置宏，计算阴影纹理坐标

                return o;
            }

            // 编写阴影函数
            float3 shadow_ramp (float4 lightMap, float Lambert, float atten){
                lightMap.g = smoothstep(0.2, 0.3, lightMap.g);   // lightMap.g
                float halfLambert = smoothstep(0.0, _Grey, Lambert + _Dark) * lightMap.g ; // 可控的半兰伯特
                float brightMask  = smoothstep(0.98, _Bright, halfLambert) ;  // 亮面的范围
                
                // 判断白天与夜晚
                float rampSampling = 0.0;
                if (_dayAndNight == 0){    // 如果为夜晚
                    rampSampling = 0.5;
                }
                
                // 计算ramp采样条数
                float ramp0 = _RampIndex0 * -0.1 + 1.05 - rampSampling; // 0.95
                float ramp1 = _RampIndex1 * -0.1 + 1.05 - rampSampling; // 0.65
                float ramp2 = _RampIndex2 * -0.1 + 1.05 - rampSampling; // 0.75
                float ramp3 = _RampIndex3 * -0.1 + 1.05 - rampSampling; // 0.55
                float ramp4 = _RampIndex4 * -0.1 + 1.05 - rampSampling; // 0.85

                // 分离lightmap.a各材质
                float lightMapA2 = step(0.25, lightMap.a);  // 0.3 
                float lightMapA3 = step(0.45, lightMap.a);  // 0.5
                float lightMapA4 = step(0.65, lightMap.a);  // 0.7
                float lightMapA5 = step(0.95, lightMap.a);  // 1.0

                // 重组lightmap.a
                // 将模型中不同位置的光照贴图混合不同的ramp
                float rampV = ramp0; // 0.0
                rampV = lerp(rampV, ramp1, lightMapA2); // 0.3
                rampV = lerp(rampV, ramp2, lightMapA3); // 0.5
                rampV = lerp(rampV, ramp3, lightMapA4); // 0.7
                rampV = lerp(rampV, ramp4, lightMapA5); // 1.0

                // 采样ramp
                float3 ramp = tex2D(_ramp, float2(halfLambert, ramp0));
                float3 shadowRamp = lerp(ramp, halfLambert, brightMask); // 遮罩亮面
                
                float3 shadow = shadowRamp;
                return shadow;
            }

            // 高光编写
            float3 Spec(float Lambert, float Phong, float4 lightMap, float3 BaseColor){
                float BPhong = pow(max(0.0, Phong), _Gloss);   // phong
                float3 Specular  = BPhong * lightMap.r * _GlossStrength;  // 高光强度
                Specular = Specular * lightMap.b;  // 混合高光细节
                //Specular = BaseColor * Specular;  // 叠加固有色
                lightMap.g = smoothstep(0.2, 0.3, lightMap.g); // lightMap.g
                float halfLambert = smoothstep(0.0, _Grey, Lambert + _Dark) * lightMap.g;  // 混合了阴影的兰伯特
                float brightMask  = step(_Bright, halfLambert);   // step兰伯特的阴影
                Specular = Specular * brightMask;

                return Specular;

            }

            // 金属
            float3 Metal(float3 nDirVS, float4 lightMap, float3 BaseColor){
                float  MetalMask = 1 - step(lightMap.r, 0.9);   // 金属遮罩
                float3 MetalMap  = tex2D(_MetalMap, nDirVS.rg * 0.5 + 0.5).r;  // 采样metalMap
                MetalMap = lerp(_MetalMapColor, BaseColor, MetalMap);   // 金属反射颜色
                MetalMap = lerp(0.0, MetalMap, MetalMask);   // 混合金属遮罩

                return MetalMap;
            }

            // 边缘光
            float3 Rim(float Fresnel){
                float FresnelS = pow(1 - Fresnel, _Fresnel);  // 菲涅尔
                FresnelS = step(0.5, FresnelS) * _EdgeLight;  // 边缘光强度

                return FresnelS;
            }

            // 自发光
            float3 Emission(float3 diffuse, float diffuseA){
                diffuseA = smoothstep(0.0, 1.0, diffuseA);  // 去除噪点
                float3 glow = lerp(0, diffuse, diffuseA * _glow);  // 自发光
                
                return glow;
            }

            // 身体
            float3 Body(float Lambert, float Phong, float Fresnel, float4 lightMap, float3 BaseColor, float3 nDirVS, float atten){
                float3 ramp = shadow_ramp(lightMap, Lambert, atten);  // 阴影
                float3 SpecularColor = Spec(Lambert, Phong, lightMap, BaseColor);  // 高光
                float3 MetalColor    = Metal(nDirVS, lightMap, BaseColor);   // 金属
                float3 diffuse       = BaseColor * ramp;   // 漫反射
                diffuse              = diffuse * step(lightMap.r, 0.9); // 将漫反射中的金属部分去掉
                float3 RimColor      = Rim(Fresnel);       // 边缘光
                //float3 glowColor     = Emission(BaseColor, diffuseA);

                float3 Body = diffuse + MetalColor + SpecularColor + RimColor;
                return Body;
                
            }

            // 脸部
            float3 Face(float3 lightDir, float3 BaseColor, float2 uv){
                // 采样贴图
                float SDF  = tex2D(_LightMap, uv).a;   // 采样SDF
                float SDF2 = tex2D(_LightMap, float2(1-uv.x, uv.y)).a;   // 翻转x轴采样SDF
                // 计算向量
                float3 RightDir = -_LeftDir;
                float2 Left     = normalize(float2(_LeftDir.x, _LeftDir.z));  // 只考虑xz，因为y轴对光线不影响
                float2 Front    = normalize(float2(_Front.x, _Front.z));
                float2 lightDirFace = normalize(lightDir.xz);

                float ctrl  = 1-(dot(Front, lightDirFace) * 0.5 + 0.5);
                
                //float3 up    = float3(0, 1, 0);  // 上方向y轴
                //float2 front = normalize(float2(_Front.x, _Front.z));  // 前朝向z轴
                //float2 left  = normalize(float2(_LeftDir.x, _LeftDir.z)); // 左朝向-x轴
                //float3 right = -_LeftDir;// 右朝向x轴
                // 点乘向量
                //float frontL = dot(normalize(front), normalize(lightDir));  // 前点乘光
                //float leftL  = dot(normalize(left), normalize(lightDir));   // 左点乘光
                //float rightL = dot(normalize(right), normalize(lightDir));  // 右点乘光
                // 计算阴影
                float lightAttenuation = dot(lightDirFace, Left) > 0 ? SDF : SDF2;

                float isShadowFace = 0;
                isShadowFace = step(lightAttenuation, ctrl);

                //bias = smoothstep(0, _)

                // 判断白天与夜晚
                float rampSampling = 0.0;
                if(_dayAndNight == 0){
                    rampSampling = 0.5;
                }
                // 计算V轴
                float rampV = _RampIndex4 * -0.1 + 1.05 - rampSampling;
                // 采样ramp
                float3 rampColor = tex2D(_ramp, float2(isShadowFace, rampV)) * _SDFRampColor;
                float3 rampColor2 = lerp(BaseColor, _SDFRampColor, isShadowFace);
                // 混合baseColor
                float3 face = lerp(BaseColor, BaseColor * rampColor2, isShadowFace);
                
                return face;
            }

            
            // 输出结构>>像素shader
            fixed4 frag(v2f i) : SV_TARGET {               
                /****准备阶段****/
                // 采样贴图
                float3 BaseColor = tex2D(_Diffuse, i.uv).rgb;  // 采样漫反射的rgb图
                float  diffuseA  = tex2D(_Diffuse, i.uv).a;    // 采样漫反射的a通道
                float4 lightMap  = tex2D(_LightMap, i.uv).rgba;// 采样光照贴图

                // 法线贴图
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));  // 采样法线贴图
                bump.xy *= _BumpScale;    // 凹凸程度
                bump.z   = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                fixed3 bumpNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                
                // 向量准备
                float3 worldPos    = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);     // 顶点
                float3 worldNormal = float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);  // 法线方向
                fixed3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);         // 光照方向
                fixed3 viewDir   = normalize(UnityWorldSpaceViewDir(worldPos)); // 观察方向
                fixed3 nDirVS    = normalize(mul((float3x3)UNITY_MATRIX_V, bumpNormal));  // 法线空间转观察空间法线        
                fixed3 LWreflect = reflect(-lightDir, bumpNormal);             // 光照反射的r

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                // 向量点积
                float Lambert = dot(bumpNormal, lightDir);
                float Phong = dot(LWreflect, viewDir);
                float Fresnel = dot(bumpNormal, viewDir);

                /****计算阶段****/
                float3 shadowColor   = shadow_ramp(lightMap, Lambert, atten);    // 阴影
                float3 SpecularColor = Spec(Lambert, Phong, lightMap, BaseColor);  // 高光
                float3 MetalColor    = Metal(nDirVS, lightMap, BaseColor);  // 金属
                float3 RimColor      = Rim(Fresnel);  // 边缘光
                float3 glowColor     = Emission(BaseColor, diffuseA);  // 自发光
                float3 Bodycolor     = Body(Lambert, Phong, Fresnel, lightMap, BaseColor, nDirVS, atten);  // 身体 = 阴影+高光+金属+边缘光
                float3 FaceColor     = Face(lightDir, BaseColor, i.uv); // 脸部

                // 主体渲染
                float3 col = float3(0.0, 0.0, 0.0);
                if(_GenShinShader == 1.0){
                    col = Bodycolor;
                }else if(_GenShinShader == 3.0){
                    col = FaceColor;
                }

                float3 GenColorLight = (col * _LightColor0.rgb ) + glowColor;
                //float3 GenColorLight = lerp(col * _LightColor0.rgb, glowColor, diffuseA);
                float3 GenColor;
                // 计算裁剪or自发光
                if(_DiffuseAlpha){
                    GenColor = col;
                    diffuseA = smoothstep(0.05, 0.7, diffuseA); // 去除噪点
                    clip(diffuseA - _CutOff);
                }else{
                    GenColor = GenColorLight;
                }
                
                //return 1;
                return float4(GenColor, 1);
                //return float(step(0.95, lightMap.a));

            }

            ENDCG
        }

        Pass {
            Tags {"LightMode" = "ForwardAdd"}
            
            Cull off    // 关闭背面剔除

            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float     _GenShinShader;

            sampler2D _Diffuse;
            float4    _Diffuse_ST;
            float     _Fresnel;
            float     _EdgeLight;

            float     _DiffuseAlpha;
            float     _CutOff;
            float4    _glow;

            sampler2D _LightMap;
            float     _Bright;
            float     _Grey;
            float     _Dark;
            float4    _SDFRampColor;

            sampler2D _BumpMap;
            float4    _BumpMap_ST;
            float     _BumpScale;

            sampler2D _ramp;
            float     _dayAndNight;

            float     _RampIndex0;
            float     _RampIndex1;
            float     _RampIndex2;
            float     _RampIndex3;
            float     _RampIndex4;

            sampler2D _MetalMap;
            float     _Gloss;
            float     _GlossStrength;
            float4    _MetalMapColor;

            float     _Outline;
            float4    _OutlineColor0;
            float4    _OutlineColor1;
            float4    _OutlineColor2;
            float4    _OutlineColor3;
            float4    _OutlineColor4;
            float4    _Color;

            float3     _Front;
            float3     _Up;
            float3     _LeftDir;


            // 输入结构
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;      // 法线
                float4 tangent : TANGENT;    // 切线
                float4 texcoord : TEXCOORD0; // uv
            };

            // 输出结构
            struct v2f {
                float4 pos   : SV_POSITION;
                float4 uv    : TEXCOORD0;    // 顶点信息
                fixed4 TtoW0 : TEXCOORD1;    // x切线，y副切线，z法线，w顶点
                fixed4 TtoW1 : TEXCOORD2;
                fixed4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)             // 投影
            };

            // 输入结构>>顶点>>输出结构
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // 裁剪空间的顶点信息
                o.uv.xy = v.texcoord.xy * _Diffuse_ST.xy + _Diffuse_ST.zw;   // 一套uv储存漫反射
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;   // 储存法线贴图

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;    // 顶点位置
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);     // 法线方向
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  // 切线方向 
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   // 叉积求得副切线方向

                // 构建矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); // 添加内置宏，计算阴影纹理坐标

                return o;
            }

            // 编写阴影函数
            float3 shadow_ramp (float4 lightMap, float Lambert, float atten){
                lightMap.g = smoothstep(0.2, 0.3, lightMap.g);   // lightMap.g
                float halfLambert = smoothstep(0.0, _Grey, Lambert + _Dark) * lightMap.g ; // 可控的半兰伯特
                float brightMask  = smoothstep(0.98, _Bright, halfLambert) ;  // 亮面的范围
                
                // 判断白天与夜晚
                float rampSampling = 0.0;
                if (_dayAndNight == 0){    // 如果为夜晚
                    rampSampling = 0.5;
                }
                
                // 计算ramp采样条数
                float ramp0 = _RampIndex0 * -0.1 + 1.05 - rampSampling; // 0.95
                float ramp1 = _RampIndex1 * -0.1 + 1.05 - rampSampling; // 0.65
                float ramp2 = _RampIndex2 * -0.1 + 1.05 - rampSampling; // 0.75
                float ramp3 = _RampIndex3 * -0.1 + 1.05 - rampSampling; // 0.55
                float ramp4 = _RampIndex4 * -0.1 + 1.05 - rampSampling; // 0.85

                // 分离lightmap.a各材质
                float lightMapA2 = step(0.25, lightMap.a);  // 0.3 
                float lightMapA3 = step(0.45, lightMap.a);  // 0.5
                float lightMapA4 = step(0.65, lightMap.a);  // 0.7
                float lightMapA5 = step(0.95, lightMap.a);  // 1.0

                // 重组lightmap.a
                // 将模型中不同位置的光照贴图混合不同的ramp
                float rampV = ramp0; // 0.0
                rampV = lerp(rampV, ramp1, lightMapA2); // 0.3
                rampV = lerp(rampV, ramp2, lightMapA3); // 0.5
                rampV = lerp(rampV, ramp3, lightMapA4); // 0.7
                rampV = lerp(rampV, ramp4, lightMapA5); // 1.0

                // 采样ramp
                float3 ramp = tex2D(_ramp, float2(halfLambert, rampV));
                float3 shadowRamp = lerp(ramp, halfLambert, brightMask); // 遮罩亮面
                
                float3 shadow = shadowRamp;
                return shadow;
            }

            // 高光编写
            float3 Spec(float Lambert, float Phong, float4 lightMap, float3 BaseColor){
                float BPhong = pow(max(0.0, Phong), _Gloss);   // phong
                float3 Specular  = BPhong * lightMap.r * _GlossStrength;  // 高光强度
                Specular = Specular * lightMap.b;  // 混合高光细节
                //Specular = BaseColor * Specular;  // 叠加固有色
                lightMap.g = smoothstep(0.2, 0.3, lightMap.g); // lightMap.g
                float halfLambert = smoothstep(0.0, _Grey, Lambert + _Dark) * lightMap.g;  // 混合了阴影的兰伯特
                float brightMask  = step(_Bright, halfLambert);   // step兰伯特的阴影
                Specular = Specular * brightMask;

                return Specular;

            }

            // 金属
            float3 Metal(float3 nDirVS, float4 lightMap, float3 BaseColor){
                float  MetalMask = 1 - step(lightMap.r, 0.9);   // 金属遮罩
                float3 MetalMap  = tex2D(_MetalMap, nDirVS.rg * 0.5 + 0.5).r;  // 采样metalMap
                MetalMap = lerp(_MetalMapColor, BaseColor, MetalMap);   // 金属反射颜色
                MetalMap = lerp(0.0, MetalMap, MetalMask);   // 混合金属遮罩

                return MetalMap;
            }

            // 边缘光
            float3 Rim(float Fresnel){
                float FresnelS = pow(1 - Fresnel, _Fresnel);  // 菲涅尔
                FresnelS = step(0.5, FresnelS) * _EdgeLight;  // 边缘光强度

                return FresnelS;
            }

            // 自发光
            float3 Emission(float3 diffuse, float diffuseA){
                diffuseA = smoothstep(0.0, 1.0, diffuseA);  // 去除噪点
                float3 glow = lerp(0, diffuse, diffuseA * _glow);  // 自发光
                
                return glow;
            }

            // 身体
            float3 Body(float Lambert, float Phong, float Fresnel, float4 lightMap, float3 BaseColor, float3 nDirVS, float atten){
                float3 ramp = shadow_ramp(lightMap, Lambert, atten);  // 阴影
                float3 SpecularColor = Spec(Lambert, Phong, lightMap, BaseColor);  // 高光
                float3 MetalColor    = Metal(nDirVS, lightMap, BaseColor);   // 金属
                float3 diffuse       = BaseColor * ramp;   // 漫反射
                diffuse              = diffuse * step(lightMap.r, 0.9); // 将漫反射中的金属部分去掉
                float3 RimColor      = Rim(Fresnel);       // 边缘光
                //float3 glowColor     = Emission(BaseColor, diffuseA);

                float3 Body = diffuse + MetalColor + SpecularColor + RimColor;
                return Body;
                
            }

            // 脸部
            float3 Face(float3 lightDir, float3 BaseColor, float2 uv){
                // 采样贴图
                float SDF  = tex2D(_LightMap, uv).a;   // 采样SDF
                float SDF2 = tex2D(_LightMap, float2(1-uv.x, uv.y)).a;   // 翻转x轴采样SDF
                // 计算向量
                float3 RightDir = -_LeftDir;
                float2 Left     = normalize(float2(_LeftDir.x, _LeftDir.z));  // 只考虑xz，因为y轴对光线不影响
                float2 Front    = normalize(float2(_Front.x, _Front.z));
                float2 lightDirFace = normalize(lightDir.xz);

                float ctrl  = 1-(dot(Front, lightDirFace) * 0.5 + 0.5);
                
                //float3 up    = float3(0, 1, 0);  // 上方向y轴
                //float2 front = normalize(float2(_Front.x, _Front.z));  // 前朝向z轴
                //float2 left  = normalize(float2(_LeftDir.x, _LeftDir.z)); // 左朝向-x轴
                //float3 right = -_LeftDir;// 右朝向x轴
                // 点乘向量
                //float frontL = dot(normalize(front), normalize(lightDir));  // 前点乘光
                //float leftL  = dot(normalize(left), normalize(lightDir));   // 左点乘光
                //float rightL = dot(normalize(right), normalize(lightDir));  // 右点乘光
                // 计算阴影
                float lightAttenuation = dot(lightDirFace, Left) > 0 ? SDF : SDF2;

                float isShadowFace = 0;
                isShadowFace = step(lightAttenuation, ctrl);

                //bias = smoothstep(0, _)

                // 判断白天与夜晚
                float rampSampling = 0.0;
                if(_dayAndNight == 0){
                    rampSampling = 0.5;
                }
                // 计算V轴
                float rampV = _RampIndex4 * -0.1 + 1.05 - rampSampling;
                // 采样ramp
                float3 rampColor = tex2D(_ramp, float2(isShadowFace, rampV)) * _SDFRampColor;
                float3 rampColor2 = lerp(BaseColor, _SDFRampColor, isShadowFace);
                // 混合baseColor
                float3 face = lerp(BaseColor, BaseColor * rampColor2, isShadowFace);
                
                return face;
            }

            
            // 输出结构>>像素shader
            fixed4 frag(v2f i) : SV_TARGET {               
                /****准备阶段****/
                // 采样贴图
                float3 BaseColor = tex2D(_Diffuse, i.uv).rgb;  // 采样漫反射的rgb图
                float  diffuseA  = tex2D(_Diffuse, i.uv).a;    // 采样漫反射的a通道
                float4 lightMap  = tex2D(_LightMap, i.uv).rgba;// 采样光照贴图

                // 法线贴图
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));  // 采样法线贴图
                bump.xy *= _BumpScale;    // 凹凸程度
                bump.z   = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                fixed3 bumpNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                
                // 向量准备
                float3 worldPos    = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);     // 顶点
                float3 worldNormal = float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);  // 法线方向
                fixed3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);         // 光照方向
                fixed3 viewDir   = normalize(UnityWorldSpaceViewDir(worldPos)); // 观察方向
                fixed3 nDirVS    = normalize(mul((float3x3)UNITY_MATRIX_V, bumpNormal));  // 法线空间转观察空间法线        
                fixed3 LWreflect = reflect(-lightDir, bumpNormal);             // 光照反射的r

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                // 向量点积
                float Lambert = dot(bumpNormal, lightDir);
                float Phong = dot(LWreflect, viewDir);
                float Fresnel = dot(bumpNormal, viewDir);

                /****计算阶段****/
                float3 shadowColor   = shadow_ramp(lightMap, Lambert, atten);    // 阴影
                float3 SpecularColor = Spec(Lambert, Phong, lightMap, BaseColor);  // 高光
                float3 MetalColor    = Metal(nDirVS, lightMap, BaseColor);  // 金属
                float3 RimColor      = Rim(Fresnel);  // 边缘光
                float3 glowColor     = Emission(BaseColor, diffuseA);  // 自发光
                float3 Bodycolor     = Body(Lambert, Phong, Fresnel, lightMap, BaseColor, nDirVS, atten);  // 身体 = 阴影+高光+金属+边缘光
                float3 FaceColor     = Face(lightDir, BaseColor, i.uv); // 脸部

                // 主体渲染
                float3 col = float3(0.0, 0.0, 0.0);
                if(_GenShinShader == 1.0){
                    col = Bodycolor;
                }else if(_GenShinShader == 3.0){
                    col = FaceColor;
                }

                float3 GenColorLight = (col * _LightColor0.rgb ) + glowColor;
                //float3 GenColorLight = lerp(col * _LightColor0.rgb, glowColor, diffuseA);
                float3 GenColor;
                // 计算裁剪or自发光
                if(_DiffuseAlpha){
                    GenColor = col;
                    diffuseA = smoothstep(0.05, 0.7, diffuseA); // 去除噪点
                    clip(diffuseA - _CutOff);
                }else{
                    GenColor = GenColorLight;
                }
                
                //return 1;
                return float4(GenColor, 1);
                //return float(step(0.95, lightMap.a));

            }

            ENDCG
        }

        
    }
    Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}