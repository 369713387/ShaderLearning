Shader "Unlit/OldSchoolPro"
{
    Properties {
        _MainTex ("颜色贴图", 2D) = "white" {}
        _NormalMap("法线贴图",2d) = "bump" {}
        _CubeMap("立方体贴图",CUBE) = "gray" {}
        _CubeMapLOD("立方体贴图LOD",range(0,7)) = 1
        _FresnelPow("菲涅尔反射强度",range(0,10)) = 1
        _EnvUpCol("顶部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvSideCol("侧边环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvDownCol("底部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _Occlusion("AO贴图",2D) = "white" {}
        _EnvLightPow("环境光强度",range(0,50)) = 25
        _SpecularPow("高光强度",range(0,400)) = 150
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

            uniform sampler2D _MainTex;
            uniform sampler2D _NormalMap;
            uniform samplerCUBE _CubeMap;
            uniform float _CubeMapLOD;
            uniform float _FresnelPow;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;
            uniform sampler2D _Occlusion;
            uniform float _EnvLightPow;
            uniform float _SpecularPow;

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0; // 新建一个输出结构
                o.pos = UnityObjectToClipPos(v.vertex); // 变换顶点信息 OS->CS
                o.posWS = mul(unity_ObjectToWorld,v.vertex);//变化顶点信息 OS->WS
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);//获取世界空间的切线信息
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);//获取世界空间的副切线信息  
                o.uv = v.uv0;
                TRANSFER_VERTEX_TO_FRAGMENT(o) // Unity封装 不用管细节
                return o; // 将输出结构 输出
            }
            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR 
            {
                //计算添加法线贴图后的法线信息
                float3 var_NormalMap = UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 nDir = normalize(mul(var_NormalMap,TBN));

                //计算CubeMap的贴图信息
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 vrDir = reflect(-vDir,nDir);
                float3 var_CubeMap = texCUBElod(_CubeMap,float4(vrDir,_CubeMapLOD));

                //计算菲涅尔反射信息
                float vdotn = dot(vDir,nDir);
                float fresnel = pow(max(0.0,1.0 - vdotn),_FresnelPow);

                //计算直接光照
                //兰伯特光照
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 ndotl = dot(nDir,lDir);              
                float3 Lambert = max(0.0,ndotl);

                //blinn-phong
                float3 hDir = normalize(lDir + vDir);
                float3 ndoth = dot(nDir,hDir);
                float3 BlinnPhong = pow(max(0.0,ndoth),_SpecularPow);

                //阴影
                float Shadow = LIGHT_ATTENUATION(i); // 同样Unity封装好的函数 可取出投影

                //直接光照最终颜色
                float3 DirLightCol = (Lambert + BlinnPhong) * Shadow;

                //计算环境光照               
                float UpMask = max(0.0,i.nDirWS.g);
                float SideMask = 1 - (max(0.0,i.nDirWS.g) + max(0.0,-i.nDirWS.g));
                float DownMask = max(0.0,-i.nDirWS.g);
                
                float3 EnvCol = _EnvUpCol * UpMask + _EnvSideCol * SideMask + _EnvDownCol * DownMask;
                float Occlusion = tex2D(_Occlusion,i.uv);  

                //环境光照最终颜色
                float3 EnvLightCol = EnvCol * Occlusion * fresnel * _EnvLightPow;
                
                //贴图颜色
                float4 MainTex = tex2D(_MainTex,i.uv);
                float3 MainTexCol = MainTex.rgb;
                
                //计算最终颜色
                float3 finalRGB = var_CubeMap * MainTexCol * EnvLightCol * DirLightCol;
                //返回结果                
                return float4(finalRGB, 1.0);
            }
        ENDCG
        }
    }
    FallBack "Diffuse"
}