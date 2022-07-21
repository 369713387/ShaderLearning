Shader "YF/CubeMap"
{
    Properties
    {
        _CubeMap("立方体贴图",CUBE) = "gray" { }
        _CubeMapMip("立方体贴图LOD",range(0,7)) = 1
        _NormalMap("法线贴图",2d) = "bump" { }
        _FresnelPow("菲涅尔反射强度",range(0,10)) = 1
        _EnvLightPow("环境光强度",range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            //输入参数
            uniform samplerCUBE _CubeMap;
            uniform float _CubeMapMip;
            uniform sampler2D _NormalMap;
            uniform float _FresnelPow;
            uniform float _EnvLightPow;

            //输入结构
            struct appdata
            {
                float4 vertex : POSITION; //顶点信息
                float4 normal : NORMAL;   //法线信息
                float4 tangent : TANGENT; //切线信息
                float2 uv0 : TEXCOORD0;   //uv信息
            };

            //输出结构
            struct v2f
            {
                float4 posCS : SV_POSITION;  //裁剪空间的顶点信息
                float2 uv : TEXCOORD0;       //uv信息
                float3 posWS : TEXCOORD1;    //世界坐标的顶点信息
                float3 tDirWS : TEXCOORD2;   //切线信息
                float3 bDirWS : TEXCOORD3;   //副切线信息
                float3 nDirWS : TEXCOORD4;   //法线信息
            };

            v2f vert (appdata v)
            {
                v2f o;                                          //新建一个输出结构
                o.posCS = UnityObjectToClipPos(v.vertex);       //位置信息转换OS->CS
                o.uv = v.uv0;                                   //传递uv信息
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  //获取世界空间的法线信息
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);//获取世界空间的切线信息
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);//获取世界空间的副切线信息  
                o.posWS = mul(unity_ObjectToWorld,v.vertex);                                                            
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 var_NormalMap = UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 nDirWS = normalize(mul(var_NormalMap,TBN));
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 vrDirWS = reflect(-vDirWS,nDirWS);
                //准备中间结果
                float vdotn = dot(vDirWS,nDirWS);
                //光照模型
                float3 var_CubeMap = texCUBElod(_CubeMap,float4(vrDirWS,_CubeMapMip)).rgb;
                float fresnel = pow(max(0.0,1.0-vdotn),_FresnelPow);                
                float3 LightingCol = var_CubeMap * fresnel * _EnvLightPow;

                //返回结果
                return float4(LightingCol,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
