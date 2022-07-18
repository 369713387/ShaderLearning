Shader "Unlit/OldSchoolAndAmbientWithShadow"
{
    Properties {
        _MainTex ("颜色贴图", 2D) = "white" {}
        _EnvUpCol("顶部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvSideCol("侧边环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvDownCol("底部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _Occlusion("AO贴图",2D) = "white" {}
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
                float2 uv0 : TEXCOORD0;   //模型的UV0信息
            };
            // 输出结构
            struct VertexOutput 
            {
                float4 pos : SV_POSITION;    //裁剪空间下的顶点信息
                float3 nDirWS : TEXCOORD0;   //世界空间下的法线信息
                float2 uv : TEXCOORD1;       //模型的UV信息
                LIGHTING_COORDS(2,3)         // 投影用坐标信息 Unity已封装 不用管细节
                float4 posWS : TEXCOORD4;    //世界空间下的顶点信息
            };

            sampler2D _MainTex;
            float3 _EnvUpCol;
            float3 _EnvSideCol;
            float3 _EnvDownCol;
            sampler2D _Occlusion;
            float _SpecularPow;

            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0; // 新建一个输出结构
                o.pos = UnityObjectToClipPos(v.vertex); // 变换顶点信息 并将其塞给输出结构
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv0;
                TRANSFER_VERTEX_TO_FRAGMENT(o) // Unity封装 不用管细节
                return o; // 将输出结构 输出
            }
            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR 
            {
                //计算直接光照
                //兰伯特光照
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 nDir = i.nDirWS;
                float3 ndotl = dot(nDir,lDir);              
                float3 Lambert = max(0.0,ndotl);

                //blinn-phong
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
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
                float3 EnvLightCol = EnvCol * Occlusion;
                
                //贴图颜色
                float4 MainTex = tex2D(_MainTex,i.uv);
                float3 MainTexCol = MainTex.rgb;
                
                //计算最终颜色
                float3 finalRGB = MainTexCol * EnvLightCol * DirLightCol;
                //返回结果                
                return float4(finalRGB, 1.0);
            }
        ENDCG
        }
    }
    FallBack "Diffuse"
}