Shader "Unlit/3ColorAmbient"
{
    Properties
    {
        _MainTex ("颜色贴图", 2D) = "white" {}
        _EnvUpCol("顶部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvSideCol("侧边环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _EnvDownCol("底部环境光颜色",color) = (1.0,1.0,1.0,1.0)
        _Occlusion("AO贴图",2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION; //模型空间下的顶点信息
                float4 normal : NORMAL;   //模型空间下的法线信息
                float2 uv0 : TEXCOORD0;   //模型的UV0信息
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;  //裁剪空间下的顶点信息
                float3 nDirWS : TEXCOORD0;   //世界空间下的法线信息
                float2 uv : TEXCOORD1;       //模型的UV信息
                
            };

            sampler2D _MainTex;
            float3 _EnvUpCol;
            float3 _EnvSideCol;
            float3 _EnvDownCol;
            sampler2D _Occlusion;

            v2f vert (appdata v)
            {
                v2f o;
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv0;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float4 MainTex = tex2D(_MainTex,i.uv);
                float Occlusion = tex2D(_Occlusion,i.uv);
                float UpMask = max(0.0,i.nDirWS.g);
                float SideMask = 1 - (max(0.0,i.nDirWS.g) + max(0.0,-i.nDirWS.g));
                float DownMask = max(0.0,-i.nDirWS.g);
                //准备中间件
                float3 MainTexCol = MainTex.rgb;
                float3 EnvCol = _EnvUpCol * UpMask + _EnvSideCol * SideMask + _EnvDownCol * DownMask;
                //计算最终颜色
                float3 finalRGB = MainTexCol * EnvCol * Occlusion;
                //返回结果
                return float4(finalRGB,1.0);
            }
            ENDCG
        }
    }
}
