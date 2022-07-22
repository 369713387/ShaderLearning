Shader "Unlit/OldSchoolPro"
{
    Properties {
        [Header(Texture)]
        _MainTex ("RGB:基础颜色 A:环境遮罩", 2D) = "white" {}
        _NormalMap("RGB:法线贴图",2d) = "bump" {}
        _SpecTex("RGB:高光颜色 A:高光次幂",2d) = "gray" {}
        _EmitTex("RGB:自发光贴图",2D) = "black" {}
        _CubeMap("RGB:环境反射贴图",CUBE) = "_Skybox" {}

        [Header(Diffuse)]
        _BaseCol("基础颜色",color) = (0.5, 0.5, 0.5, 1.0)
        _EnvTopCol("天空环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvBottomCol("地表环境光颜色",color) = (0.0, 0.0, 0.0, 0.0)
        _EnvSideCol("其他环境光颜色",color) = (0.5, 0.5, 0.5, 1.0)
        _EnvDiffPow("环境漫反射强度",range(0,1)) = 0.2

        [Header(Specular)]
        _SpecularPow("高光次幂",range(1,90)) = 10
        _EnvSpcPow("镜面反射强度",range(0,5)) = 5
        _FresnelPow("菲涅尔次幂",range(0,5)) = 1
        _CubeMapLOD("环境反射贴图LOD(mipmap有8个等级)",range(0,7)) = 0

        [Header(Emission)]
        _EmitPow("自发光强度",range(1,10)) = 1
        
    }
    SubShader 
    {
        Tags 
        {
            "RenderType"="Opaque"
        }
        Pass 
        {
            Name "FORWARD"
            Tags 
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc" // 使用Unity投影必须包含这两个库文件
            #include "Lighting.cginc" // 同上
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            //参数声明
            //Texture
            uniform sampler2D _MainTex;
            uniform sampler2D _NormalMap;
            uniform sampler2D _SpecTex;
            uniform sampler2D _EmitTex;
            uniform samplerCUBE _CubeMap;
            //Diffuse
            uniform float3 _BaseCol;
            uniform float3 _EnvTopCol;
            uniform float3 _EnvBottomCol;
            uniform float3 _EnvSideCol;
            uniform float _EnvDiffPow;
            //Specular
            uniform float _SpecularPow;
            uniform float _EnvSpcPow;
            uniform float _FresnelPow;
            uniform float _CubeMapLOD;
            //Emission
            uniform float _EmitPow;

            // 输入结构
            struct VertexInput 
            {
                float4 vertex : POSITION; //模型空间下的顶点信息
                float4 normal : NORMAL;   //模型空间下的法线信息
                float4 tangent : TANGENT; //模型空间下的切线信息
                float2 uv0 : TEXCOORD0;   //模型的UV0信息
            };
            // 输出结构
            struct VertexOutput 
            {
                float4 pos : SV_POSITION;    //裁剪空间下的顶点信息
                float4 posWS:TEXCOORD0;      //世界空间下的顶点信息
                float3 nDirWS : TEXCOORD1;   //世界空间下的法线信息
                float3 tDirWS : TEXCOORD2;   //世界空间下的切线信息
                float3 bDirWS : TEXCOORD3;   //世界空间下的副切线信息
                float2 uv : TEXCOORD4;       //模型的UV信息
                LIGHTING_COORDS(5,6)         // 投影用坐标信息 Unity已封装 不用管细节
            };

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0; // 新建一个输出结构
                o.uv = v.uv0;//获取UV信息
                o.pos = UnityObjectToClipPos(v.vertex); // 变换顶点信息 OS->CS
                o.posWS = mul(unity_ObjectToWorld,v.vertex);//变化顶点信息 OS->WS
                o.nDirWS = UnityObjectToWorldNormal(v.normal);//变化顶点信息 ON-WN
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);//获取世界空间的切线信息
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);//获取世界空间的副切线信息                 
                TRANSFER_VERTEX_TO_FRAGMENT(o) // Unity封装 不用管细节
                return o; // 将输出结构 输出
            }
            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR 
            {
                // 准备向量
                float3 nDirTS = UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS,TBN));
                float3 lDirWS = _WorldSpaceLightPos0.xyz;
                float3 lrDirWS = reflect(-lDirWS,nDirWS);
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 vrDirWS = reflect(-vDirWS,nDirWS);               
                // 准备点积结果
                float ndotl = dot(nDirWS,lDirWS);
                float vdotr = dot(vDirWS,lrDirWS);
                float vdotn = dot(vDirWS,nDirWS);
                // 采样纹理
                float4 var_MainTex = tex2D(_MainTex,i.uv);
                float4 var_SpecTex = tex2D(_SpecTex,i.uv);
                float3 var_EmitTex = tex2D(_EmitTex,i.uv).rgb;
                float CubeMapMip = lerp(_CubeMapLOD,0.0,var_SpecTex.a);
                float3 var_CubeMap = texCUBElod(_CubeMap,float4(vrDirWS,CubeMapMip)).rgb;

                // 光照模型(直接光照部分)
                    //漫反射(兰伯特)
                    float3 MainCol = var_MainTex.rgb * _BaseCol;
                    float lambert = max(0.0,ndotl);
                    //镜面反射(Phong)
                    float specCol = var_SpecTex.rgb;
                    float SpecPow = lerp(1,_SpecularPow,var_SpecTex.a);
                    float Phong = pow(max(0.0,vdotr),SpecPow);
                    //遮挡效果(shadow)
                    float shadow = LIGHT_ATTENUATION(i);
                    //直接光照混合
                    float3 dirLighting = (MainCol * lambert + specCol * Phong) * _LightColor0 * shadow;
                // 光照模型(环境光照部分)
                    //漫反射(三色环境光)
                    float EnvTopMask = max(0.0,nDirWS.g);
                    float EnvBottomMask = max(0.0,-nDirWS.g);
                    float EnvSideMask = 1 - EnvTopMask - EnvBottomMask;
                    float3 EnvCol = _EnvTopCol * EnvTopMask + _EnvBottomCol * EnvBottomMask + _EnvSideCol * EnvSideMask;                
                    //镜面反射(环境球贴图)
                    float fresnel = pow(max(0.0,1.0 - vdotn),_FresnelPow);
                    //遮挡效果(AO图)
                    float occlusion = var_MainTex.a;
                    //环境光照混合
                    float3 envLighting = (MainCol * EnvCol * _EnvDiffPow + var_CubeMap * fresnel * _EnvSpcPow * var_SpecTex.a) * occlusion;
                // 光照模型(自发光部分)
                float emitpow = _EmitPow * (sin(frac(_Time.z)) * 0.5 + 0.5);
                float3 emission = var_EmitTex * emitpow;
                //返回结果
                float3 finalRBG = dirLighting + envLighting + emission;
                return float4(finalRBG, 1.0);
            }
        ENDCG
        }
    }
    FallBack "Diffuse"
}