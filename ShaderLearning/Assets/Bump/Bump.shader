Shader "YF/Bump"
{
    Properties
    {
        _MainTex       ("颜色贴图", 2D) = "white" {}
        _BumpMap       ("高度贴图",2D) = "bump" {}
        _BumpScale     ("凹凸程度",range(-2,2)) = 0.0
        _SpecularColor ("高光颜色",color) = (1.0,1.0,1.0,1.0)
        _Gloss         ("高光范围",range(4,256)) = 64
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

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _BumpMap;
            uniform half _BumpScale;
            uniform half3 _SpecularColor;
            uniform half _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0; 
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv  : TEXCOORD0;
                float3 lDirTS : TEXCOORD1;
                float3 vDirTS : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //主帖图UV
                o.uv.xy = v.uv;
                //法线贴图UV
                o.uv.zw = v.uv;
    
                //解决法线方向问题可以通过使用v.tangent.w和叉积结果进行相乘
                float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                //我们把模型空间下切线方向，副切线方向，法线方向按行排列得到从模型空间到切线空间得变换矩阵
                float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);           

                o.lDirTS = normalize(mul(rotation,ObjSpaceLightDir(v.vertex)).xyz);

                o.vDirTS = normalize(mul(rotation,ObjSpaceLightDir(v.vertex)).xyz);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //解码高度图的信息
                half3 var_Normal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                var_Normal.xy *= _BumpScale;
                var_Normal.z = sqrt(1.0 - saturate(dot(var_Normal.xy,var_Normal.xy)));

                //获取颜色贴图的颜色
                half3 var_MainTex = tex2D(_MainTex,i.uv.xy).rgb;

                //环境光
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * var_MainTex;

                //漫反射光
                half3 diffuse = _LightColor0.rgb * var_MainTex * max(0.0,dot(var_Normal,i.lDirTS));

                //计算半角方向
                half3 halfDir = normalize(i.lDirTS + i.vDirTS);

                //高光反射
                half3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0.0,dot(var_Normal,halfDir)),_Gloss);

                //计算最终的颜色
                half3 finalRGB = ambient + diffuse + specular;

                return half4(finalRGB,1.0);
            }
            ENDCG
        }
    }
}
