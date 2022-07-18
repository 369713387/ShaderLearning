Shader "Unlit/BlinnPhong"
{
    Properties
    {
        _SpecularPow("高光强度",range(0,90)) = 30
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

            //输入结构
            struct appdata
            {
                float4 vertex : POSITION; //顶点信息
                float4 normal : NORMAL;   //法线信息
            };

            //输出结构
            struct v2f
            {
                float4 posCS : SV_POSITION;//裁剪空间的顶点信息
                float4 posWS : TEXCOORD0;  //世界空间的顶点信息
                float3 nDirWS : TEXCOORD1; //世界空间的法线信息
            };

            //声明属性
            float _SpecularPow;

            v2f vert (appdata v)
            {
                v2f o;                                          //新建一个输出结构
                o.posCS = UnityObjectToClipPos(v.vertex);       //位置信息转换OS->CS
                o.posWS = mul(unity_ObjectToWorld,v.vertex);    //位置信息转换OS->WS
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  //位置信息转换OSN->WSN
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 nDir = i.nDirWS;
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                float3 hDir = normalize(lDir + vDir);
                //准备中间结果
                float3 ndoth = dot(nDir,hDir);
                //光照模型
                float3 BlinnPhong = pow(max(0.0,ndoth),_SpecularPow);
                //返回结果
                return float4(BlinnPhong,1.0);
            }
            ENDCG
        }
    }
}
