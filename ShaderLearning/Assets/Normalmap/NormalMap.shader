Shader "Unlit/NormalMap"
{
    Properties
    {
        _NormalMap("法线贴图",2d) = "bump" { }
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
            uniform sampler2D _NormalMap;

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
                float3 tDirWS : TEXCOORD1;   //切线信息
                float3 bDirWS : TEXCOORD2;   //副切线信息
                float3 nDirWS : TEXCOORD3;   //法线信息
            };

            v2f vert (appdata v)
            {
                v2f o;                                          //新建一个输出结构
                o.posCS = UnityObjectToClipPos(v.vertex);       //位置信息转换OS->CS
                o.uv = v.uv0;                                   //传递uv信息
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  //获取世界空间的法线信息
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);//获取世界空间的切线信息
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);//获取世界空间的副切线信息                                                                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 var_NormalMap = UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 nDir = normalize(mul(var_NormalMap,TBN));
                //准备中间结果
                float3 ndotl = dot(nDir,lDir);
                //光照模型
                float3 lambert = max(0.0,ndotl);
                
                //返回结果
                return float4(lambert,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
