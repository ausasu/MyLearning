Shader "ToonShader/ToonShaderPlus02" {
    Properties {
        [Header(Texture)]
        _AmbientScale     ("环境光强度", Range(0, 3)) = 0.5
        _Diffuse          ("漫反射颜色", Color) = (0.7, 0.7, 0.7, 0.7)
        _MainTex          ("纹理贴图", 2D) = "white" {}
        [Normal] _BumpMap ("凹凸贴图", 2D) = "bump" {}
        _BumpScale        ("凹凸程度", Float) = 1.0

        [Header(Shadow)]
        [Toggle] _ToggleRamp ("启用Ramp图", Float) = 0.0
        _RampTex             ("Ramp贴图", 2D) = "white" {}
        _RampTexScale        ("Ramp强度", Float) = 0.8
        _Ramp                ("ramp图位置变换", Range(0.05, 0.95)) = 0.5
        _RampGrey            ("Ramp的过度部分", Range(0.0, 1.5)) = 0.6
        _LightThreshold      ("一阶阴影", Range(-1.0, 1.0)) = 0.8
        _ShadowColor         ("一阶阴影颜色", color) = (0.5, 0.5, 0.5, 0.5)
        _Smooth              ("一阶阴影过度", Range(0, 1)) = 0.0
        _LightThreshold2     ("二阶阴影", Range(-1.0, 1.0)) = 0.6
        _ShadowColor2        ("二阶阴影颜色", color) = (0.0, 0.0, 0.0, 1.0)
        _Smooth2             ("二阶阴影过度", Range(0, 1)) = 0.0
        
        [Header(Gloss)]
        [Toggle] _ToggleSpecularIf  ("是否启动高光", Float) = 1.0
        [Toggle] _ToggleSpecular    ("启用phong高光", Float) = 0.0
        [Toggle] _ToggleSpecular2   ("高光混合阴影", Float) = 1.0
        _SpecularMask               ("高光遮罩", 2D) = "white" {}
        _SpecularScale              ("遮罩系数", Float) = 1.0
        _SpecularColor              ("高光颜色", Color) = (1.0, 1.0, 1.0, 1.0) 
        _Gloss                      ("phong高光大小", Range(0.01, 256)) = 10
        _Smooth4                    ("高光过度", Range(0, 1)) = 0.001
        _SpecularThreshold          ("高光大小", Range(0, 1)) = 0.1
        _SpecularShadowMix          ("高光混合阴影大小", Range(0.0, 1.0)) = 0.2
        
        [Header(Fresnel)]
        [Toggle] _ToggleFresnel ("菲涅尔混合cubemap", Float) = 1.0 
        _FresnelScale           ("菲涅尔范围", Range(10, 0.0)) = 10.0
        _FresnelInt             ("菲涅尔强度", Range(0, 10.0)) = 0.0
        _FresnelColor           ("菲涅尔颜色", color) = (1.0, 1.0, 1.0, 1.0)

        [Header(Rim)]
        [Toggle] _ToggleRim    ("启用非剪切轮廓光", Float) = 0.0
        [HDR] _RimColor        ("轮廓光颜色", color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower              ("轮廓光范围", float) = 0.1 
        _RimInt                ("轮廓光强度", Range(0, 3)) = 0.1
        _LightThreshold3       ("轮廓光渐变", Range(-1.0, 1.0)) = 0.5
        _Smooth3               ("轮廓光渐变阈值", Range(0, 1)) = 0.5
        
        [Header(Cubemap)]
        _cubemap              ("立方体纹理", Cube) = "_Skybox" {}
        _ReflectColor         ("反射颜色(菲尼尔颜色)", Color) = (1.0, 1.0, 1.0, 1.0)
        _ReflectAmount        ("反射强度", Range(0, 1)) = 0.0

        [Header(Outline)]
        [Toggle] _ToggleOutline   ("启用BackFacing描边", Float) = 1.0
        _Outline                  ("描边", float) = 0.1
        _OutlineColor             ("描边颜色", Color) = (0.0, 0.0, 0.0, 0.0)
    }

    SubShader {
        Tags { "RenderType" = "Opaque" "Queue"="Geometry"}
        
        Cull Off
        
        // 这个pass只处理平行光，不处理其他光源
        Pass {
            Tags { "LightMode"="ForwardBase" }  // 设置前向渲染base

            CGPROGRAM

            #pragma multi_compile_fwdbase   // unity中处理base和add两个pass时使用的,第一个是fwdbase，第二个是fwdadd
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float     _AmbientScale;
            fixed4    _Diffuse;
            sampler2D _MainTex;
            float4    _MainTex_ST;
            sampler2D _BumpMap;
            float4    _BumpMap_ST;
            float     _BumpScale;

            float     _ToggleRamp;
            sampler2D _RampTex;
            float     _RampTexScale; 
            float     _Ramp;    
            float     _RampGrey;
            float     _LightThreshold;
            float4    _ShadowColor;
            float     _Smooth;
            float     _LightThreshold2;
            float4    _ShadowColor2;
            float     _Smooth2;
            
            float     _ToggleSpecularIf;
            float     _ToggleSpecular;
            float     _ToggleSpecular2;
            sampler2D _SpecularMask;
            float     _SpecularScale;
            fixed4    _SpecularColor;
            float     _Gloss;
            float     _Smooth4;
            float     _SpecularThreshold;
            float     _SpecularShadowMix;

            float     _ToggleFresnel;
            float     _FresnelScale;
            float     _FresnelInt;
            float4    _FresnelColor;

            float     _ToggleRim;
            float4    _RimColor;
            float     _RimPower;
            float     _RimInt;
            float     _LightThreshold3;
            float     _Smooth3;
            samplerCUBE _cubemap;
            fixed4    _ReflectColor;
            fixed     _ReflectAmount;


            // 输入结构
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            // 输出结构
            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;    // 顶点信息
                fixed4 TtoW0 : TEXCOORD1;
                fixed4 TtoW1 : TEXCOORD2;
                fixed4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
            };

            // 输入结构>>顶点>>输出结构
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);              // 裁剪空间的顶点信息
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);     // 法线方向
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  // 切线方向 
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   // 叉积求得副切线方向

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); // 添加内置宏，计算阴影纹理坐标

                return o;
            }

            // 输出结构>>像素shader
            fixed4 frag(v2f i) : SV_TARGET {               
                /***向量准备***/
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 worldNormal = float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir  = normalize(UnityWorldSpaceViewDir(worldPos));           
                // 切线向量用于凹凸贴图
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));  // 采样法线贴图
                bump.xy *= _BumpScale;    // 凹凸程度
                bump.z   = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                fixed3 bumpNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                // 不同反射向量r
                fixed3 LWreflect = reflect(-lightDir, bumpNormal);    // 光反射的r
                fixed3 worldRefl = reflect(-viewDir, bumpNormal);     // 立方体的r

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
                
                /***漫反射模型***/
                // 内置环境光
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed3 albedo = texColor.rgb * _Diffuse.rgb;    // 采样纹理
                fixed halfLambert = (0.5 + dot(bumpNormal, lightDir) * 0.5 );
                //fixed ahalfLambert = (0.5 + (dot(bumpNormal, lightDir) * atten) * 0.5 );              
                // 二分边缘
                float Threshold = smoothstep(0, _Smooth, halfLambert - _LightThreshold);  // 控制一阶阴影
                // float Threshold2 = smoothstep(0, _Smooth, atten - _LightThreshold); // 控制atten
                float Threshold3 = Threshold * atten;    // 控制一阶阴影加atten
                float Threshold4 = smoothstep(0, _Smooth2, halfLambert - _LightThreshold2);  // 控制二阶阴影
                //float Threshold4_1 = Threshold4 * Threshold2;
                float Threshold5 = smoothstep(0, _Smooth3, halfLambert - _LightThreshold3);  // 控制轮廓光渐变
               
                /****环境光****/
                fixed3 ambient = unity_IndirectSpecColor * albedo * _AmbientScale;  // 内置环境光
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
                
                // 二分阴影漫反射
                fixed3 diffuse2 = lerp(_ShadowColor.rgb * diffuse, diffuse, Threshold3);
                fixed3 diffuse2_1 = lerp(_ShadowColor2.rgb * diffuse, diffuse2 , Threshold4);
                //fixed3 diffuseColor = diffuse2 + diffuse2_1;
                
                // ramp图阴影
                //fixed3 rampcolor = tex2D(_RampTex, fixed2(halfLambert , 0.2)).rgb; // 采样纹理
                float RamphalfLambert = smoothstep(0.0, _RampGrey, halfLambert) ;  // 先用兰伯特乘以atten
                float brightMask  = smoothstep(0.9, 0.93, RamphalfLambert) ;  // 边缘过渡
                
                fixed3 rampcolor = tex2D(_RampTex, fixed2(RamphalfLambert , _Ramp)).rgb;  // 采样ramp图
                fixed3 ramppow  = pow(rampcolor, _RampTexScale);
                float3 shadowRamp = lerp(ramppow, RamphalfLambert, brightMask);
                fixed3 diffuse3 = _LightColor0.rgb * albedo * shadowRamp;
                fixed3 diffusecol;
                if(_ToggleRamp){
                    diffusecol = diffuse3;
                }else{
                    diffusecol = diffuse2_1;
                }
                
                /***高光模型***/
                fixed3 specularMask = tex2D(_SpecularMask, i.uv).a * _SpecularScale;
                // phong
                fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(LWreflect, viewDir)), _Gloss);
                // 裁剪高光
                fixed3 stepSpecular = step(1 - _Gloss * 0.01, max(0, dot(LWreflect, viewDir))) * _SpecularColor;
                // 裁剪高光抗锯齿
                fixed w = fwidth(specular);
                fixed3 smoothSpecular = _SpecularColor * lerp(0, 1, smoothstep(-w, w, max(0, dot(LWreflect, viewDir)) + _Gloss - 1)) * step(0.0001, _Gloss) ;
                // 边缘模糊高光
                float Threshold6 =  smoothstep(0, _Smooth4, pow(dot(LWreflect, viewDir), _Gloss) -  _SpecularThreshold);
                fixed3 smoothSpecular2 = _LightColor0.rgb * _SpecularColor.rgb * Threshold6;
                fixed3 specularCol;
                if(_ToggleSpecularIf){
                    if(_ToggleSpecular){
                        if(_ToggleSpecular2){
                            specularCol = lerp(specular * _SpecularShadowMix, specular, Threshold3);
                        }else{
                            specularCol = specular;
                        }
                    }else{
                        if(_ToggleSpecular2){
                            //specularCol = smoothSpecular2 * diffusecol;
                            specularCol = lerp(smoothSpecular2 * _SpecularShadowMix, smoothSpecular2, Threshold3);
                        }else{
                            specularCol = smoothSpecular2 ;
                        }  
                    }
                }else{
                    specularCol = 0;
                }
                


                // cubemap采样
                fixed3 ReDiffuse = diffusecol;  // 将修改的漫反射放在这
                fixed3 reflection = texCUBE(_cubemap, worldRefl).rgb * _ReflectColor.rgb;
                fixed3 reflectionCube = lerp(ReDiffuse, reflection, _ReflectAmount) ;  // 金属反射              
                
                /***菲涅尔***/
                fixed fresnel = pow(1.0 - dot(viewDir, bumpNormal), _FresnelScale) * _FresnelInt;
                // 漫反射混合菲尼尔加金属反射
                fixed3 fresnelcube = lerp(reflectionCube, reflection, fresnel);
                // 纯菲尼尔加金属反射
                fixed3 fresnel2 = fresnel * _FresnelColor.rgb+  reflectionCube;
                fixed3 fresnelCol;
                if(_ToggleFresnel){
                    fresnelCol = fresnelcube;
                }else{
                    fresnelCol = fresnel2;
                }

                /***轮廓光***/
                // 轮廓光
                fixed3 rimLight = pow(1.0 - dot(viewDir, bumpNormal), _RimPower) * _RimInt * _RimColor.rgb * Threshold5;
                // 裁剪轮廓光
                fixed3 rimLight2 = step(1 - _RimPower, 1-dot(viewDir, bumpNormal)) * _RimInt * _RimColor.rgb * Threshold5;
                fixed3 rimLightCol;
                if(_ToggleRim){
                    rimLightCol = rimLight;
                }else{
                    rimLightCol = rimLight2;
                }

                // 输出颜色
                fixed3 color = ambient +  fresnelCol  + specularCol * specularMask + rimLightCol;
                return fixed4( color, 1.0);
                //return  fixed4(  ambient + fresnelCol,0);
                //return brightMask ;
            }

            ENDCG
        }

        Pass{
            Tags {"LightMode" = "ForwardAdd"}

            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float     _AmbientScale;
            fixed4    _Diffuse;
            sampler2D _MainTex;
            float4    _MainTex_ST;
            sampler2D _BumpMap;
            float4    _BumpMap_ST;
            float     _BumpScale;

            float     _ToggleRamp;
            sampler2D _RampTex;
            float     _RampTexScale; 
            float     _Ramp;    
            float     _RampGrey;
            float     _LightThreshold;
            float4    _ShadowColor;
            float     _Smooth;
            float     _LightThreshold2;
            float4    _ShadowColor2;
            float     _Smooth2;
            
            float     _ToggleSpecularIf;
            float     _ToggleSpecular;
            float     _ToggleSpecular2;
            sampler2D _SpecularMask;
            float     _SpecularScale;
            fixed4    _SpecularColor;
            float     _Gloss;
            float     _Smooth4;
            float     _SpecularThreshold;
            float     _SpecularShadowMix;

            float     _ToggleFresnel;
            float     _FresnelScale;
            float     _FresnelInt;
            float4    _FresnelColor;

            float     _ToggleRim;
            float4    _RimColor;
            float     _RimPower;
            float     _RimInt;
            float     _LightThreshold3;
            float     _Smooth3;
            samplerCUBE _cubemap;
            fixed4    _ReflectColor;
            fixed     _ReflectAmount;


            // 输入结构
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            // 输出结构
            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;    // 顶点信息
                fixed4 TtoW0 : TEXCOORD1;
                fixed4 TtoW1 : TEXCOORD2;
                fixed4 TtoW2 : TEXCOORD3;
				SHADOW_COORDS(4)
            };

            // 输入结构>>顶点>>输出结构
            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);              // 裁剪空间的顶点信息
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);     // 法线方向
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  // 切线方向 
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;   // 叉积求得副切线方向

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); // 添加内置宏，计算阴影纹理坐标

                return o;
            }

            // 输出结构>>像素shader
            fixed4 frag(v2f i) : SV_TARGET {               
                /***向量准备***/
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                float3 worldNormal = float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);
                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir  = normalize(UnityWorldSpaceViewDir(worldPos));           
                // 切线向量用于凹凸贴图
                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));  // 采样法线贴图
                bump.xy *= _BumpScale;    // 凹凸程度
                bump.z   = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                fixed3 bumpNormal = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                // 不同反射向量r
                fixed3 LWreflect = reflect(-lightDir, bumpNormal);    // 光反射的r
                fixed3 worldRefl = reflect(-viewDir, bumpNormal);     // 立方体的r

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
                
                /***漫反射模型***/
                // 内置环境光
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed3 albedo = texColor.rgb * _Diffuse.rgb;    // 采样纹理
                fixed halfLambert = (0.5 + dot(bumpNormal, lightDir) * 0.5 );
                //fixed ahalfLambert = (0.5 + (dot(bumpNormal, lightDir) * atten) * 0.5 );              
                // 二分边缘
                float Threshold = smoothstep(0, _Smooth, halfLambert - _LightThreshold);  // 控制一阶阴影
                // float Threshold2 = smoothstep(0, _Smooth, atten - _LightThreshold); // 控制atten
                float Threshold3 = Threshold * atten;    // 控制一阶阴影加atten
                float Threshold4 = smoothstep(0, _Smooth2, halfLambert - _LightThreshold2);  // 控制二阶阴影
                //float Threshold4_1 = Threshold4 * Threshold2;
                float Threshold5 = smoothstep(0, _Smooth3, halfLambert - _LightThreshold3);  // 控制轮廓光渐变
               
                /****环境光****/
                fixed3 ambient = unity_IndirectSpecColor * albedo * _AmbientScale;  // 内置环境光
                // 漫反射
                fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
                
                // 二分阴影漫反射
                fixed3 diffuse2 = lerp(_ShadowColor.rgb * diffuse, diffuse, Threshold3);
                fixed3 diffuse2_1 = lerp(_ShadowColor2.rgb * diffuse, diffuse2 , Threshold4);
                //fixed3 diffuseColor = diffuse2 + diffuse2_1;
                
                // ramp图阴影
                //fixed3 rampcolor = tex2D(_RampTex, fixed2(halfLambert , 0.2)).rgb; // 采样纹理
                float RamphalfLambert = smoothstep(0.0, _RampGrey, halfLambert) * atten;  // 先用兰伯特乘以atten
                float brightMask  = smoothstep(0.9, 0.93, RamphalfLambert) ;  // 边缘过渡
                
                fixed3 rampcolor = tex2D(_RampTex, fixed2(RamphalfLambert , _Ramp)).rgb;  // 采样ramp图
                fixed3 ramppow  = pow(rampcolor, _RampTexScale);
                float3 shadowRamp = lerp(ramppow, RamphalfLambert, brightMask);
                fixed3 diffuse3 = _LightColor0.rgb * albedo * shadowRamp;
                fixed3 diffusecol;
                if(_ToggleRamp){
                    diffusecol = diffuse3;
                }else{
                    diffusecol = diffuse2_1;
                }
                
                /***高光模型***/
                fixed3 specularMask = tex2D(_SpecularMask, i.uv).a * _SpecularScale;
                // phong
                fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(LWreflect, viewDir)), _Gloss);
                // 裁剪高光
                fixed3 stepSpecular = step(1 - _Gloss * 0.01, max(0, dot(LWreflect, viewDir))) * _SpecularColor;
                // 裁剪高光抗锯齿
                fixed w = fwidth(specular);
                fixed3 smoothSpecular = _SpecularColor * lerp(0, 1, smoothstep(-w, w, max(0, dot(LWreflect, viewDir)) + _Gloss - 1)) * step(0.0001, _Gloss) ;
                // 边缘模糊高光
                float Threshold6 =  smoothstep(0, _Smooth4, pow(dot(LWreflect, viewDir), _Gloss) -  _SpecularThreshold);
                fixed3 smoothSpecular2 = _LightColor0.rgb * _SpecularColor.rgb * Threshold6;
                fixed3 specularCol;
                if(_ToggleSpecularIf){
                    if(_ToggleSpecular){
                        if(_ToggleSpecular2){
                            specularCol = lerp(specular * _SpecularShadowMix, specular, Threshold3);
                        }else{
                            specularCol = specular;
                        }
                    }else{
                        if(_ToggleSpecular2){
                            //specularCol = smoothSpecular2 * diffusecol;
                            specularCol = lerp(smoothSpecular2 * _SpecularShadowMix, smoothSpecular2, Threshold3);
                        }else{
                            specularCol = smoothSpecular2 ;
                        }  
                    }
                }else{
                    specularCol = 0;
                }
                


                // cubemap采样
                fixed3 ReDiffuse = diffusecol;  // 将修改的漫反射放在这
                fixed3 reflection = texCUBE(_cubemap, worldRefl).rgb * _ReflectColor.rgb;
                fixed3 reflectionCube = lerp(ReDiffuse, reflection, _ReflectAmount) ;  // 金属反射              
                
                /***菲涅尔***/
                fixed fresnel = pow(1.0 - dot(viewDir, bumpNormal), _FresnelScale) * _FresnelInt;
                // 漫反射混合菲尼尔加金属反射
                fixed3 fresnelcube = lerp(reflectionCube, reflection, fresnel);
                // 纯菲尼尔加金属反射
                fixed3 fresnel2 = fresnel * _FresnelColor.rgb+  reflectionCube;
                fixed3 fresnelCol;
                if(_ToggleFresnel){
                    fresnelCol = fresnelcube;
                }else{
                    fresnelCol = fresnel2;
                }

                /***轮廓光***/
                // 轮廓光
                fixed3 rimLight = pow(1.0 - dot(viewDir, bumpNormal), _RimPower) * _RimInt * _RimColor.rgb * Threshold5;
                // 裁剪轮廓光
                fixed3 rimLight2 = step(1 - _RimPower, 1-dot(viewDir, bumpNormal)) * _RimInt * _RimColor.rgb * Threshold5;
                fixed3 rimLightCol;
                if(_ToggleRim){
                    rimLightCol = rimLight;
                }else{
                    rimLightCol = rimLight2;
                }

                // 输出颜色
                fixed3 color = ambient +  fresnelCol  + specularCol * specularMask + rimLightCol;
                return fixed4( color, 1.0);
                //return  fixed4(  ambient + fresnelCol,0);
                //return brightMask ;
            }

            ENDCG
        }
    }
    Fallback "Transparent/Cutout/VertexLit"
}