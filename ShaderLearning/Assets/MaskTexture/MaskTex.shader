Shader "YF/MaskTex"
{
    Properties
    {
        _Color("颜色",color) = (1.0,1.0,1.0,1.0)
        _MainTex("颜色贴图",2D) = "white" {}
        _NormalMap("法线贴图",2D) = "bump" {}
        _BumpScale("凹凸程度",range(-1,1)) = 0.5
        _SpecularMask ("遮罩贴图", 2D) = "white" {}
        _SpecularScale ("遮罩系数",range(-50,50)) = 1.0
        _SpecularColor("高光颜色",color) = (1.0,1.0,1.0,1.0)
        _Gloss("高光次幂",range(8,256)) = 20
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
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;        
                float3 lDir : TEXCOORD1;
                float3 vDir : TEXCOORD2;        
            };

            uniform half3 _Color;
            uniform sampler2D _MainTex;
            uniform sampler2D _NormalMap;
            uniform half _BumpScale;
            uniform sampler2D _SpecularMask;
            uniform half _SpecularScale;
            uniform half3 _SpecularColor;
            uniform half _Gloss;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy;

                TANGENT_SPACE_ROTATION;//从模型空间转换到切线空间

                o.lDir = normalize(mul(rotation,ObjSpaceLightDir(v.texcoord)).xyz);

                o.vDir = normalize(mul(rotation,ObjSpaceViewDir(v.texcoord)).xyz);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 var_Normal = UnpackNormal(tex2D(_NormalMap,i.uv));
                var_Normal.xy *= _BumpScale;
                var_Normal.z = sqrt(1.0 - saturate(dot(var_Normal.xy,var_Normal.xy)));

                half3 albedo = tex2D(_MainTex,i.uv).rgb *_Color.rgb;

                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                half3 diffuse = _LightColor0.rgb * albedo * max(0.0,dot(var_Normal,i.lDir));

                half3 hDir = normalize(i.lDir + i.vDir);

                half var_SpecularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;//采样高光遮罩贴图，通过_SpecularScale来控制高光反射的强度

                half3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0.0,dot(var_Normal,hDir)),_Gloss) * var_SpecularMask;//计算高光反射

                half3 finalRGB = ambient + diffuse + specular;

                return half4(finalRGB,1.0);
            }
            ENDCG
        }
    }
}
