Shader "YF/RempTex"
{
    Properties
    {
        _Color("颜色",color) = (1.0,1.0,1.0,1.0)
        _RempTex ("渐变纹理", 2D) = "white" {}
        _SpecularColor("高光颜色",color) = (1.0,1.0,1.0,1.0)
        _Gloss("高光次幂",range(8,256)) = 50
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;        
                float3 nDirWS : TEXCOORD1;
                float3 posWS : TEXCOORD2;        
            };

            uniform half3 _Color;
            uniform sampler2D _RempTex;
            uniform half3 _SpecularColor;
            uniform half _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 nDirWS = normalize(i.nDirWS);

                half3 lDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));

                //计算环境光
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //计算半兰伯特光照
                half halfLambert = dot(nDirWS,lDirWS) * 0.5 + 0.5;

                //获取渐变纹理
                half3 var_RempTex = tex2D(_RempTex,halfLambert).rgb;

                //计算漫反射光照
                half3 diffuse = var_RempTex * _Color.rgb * _LightColor0.rgb;

                //计算视角方向
                half3 vDir = normalize(UnityWorldSpaceViewDir(i.posWS));

                //计算半角方向
                half3 hDir = normalize(lDirWS + vDir);

                //计算高光反射光照
                half3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0.0,dot(nDirWS,hDir)),_Gloss);

                //计算最终颜色
                half3 finalRGB = ambient + diffuse + specular;

                return half4(finalRGB,1.0);
            }
            ENDCG
        }
    }
}
