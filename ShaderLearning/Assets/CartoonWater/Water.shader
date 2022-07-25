Shader "YF/Water"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _WrapTex ("扭曲图", 2d) = "gray"{}
        _FlowSpeedX("X轴流速",range(0,10)) = 5
        _FlowSpeedY("Y轴流速",range(0,10)) = 5
        _Wrap1Size("扰动图1大小",range(0,4)) = 1.0
        _Wrap1SpeedX("扰动图1流速X",range(0,1)) = 1.0
        _Wrap1SpeedY("扰动图1流速Y",range(0,1)) = 0.5
        _Wrap1Pow("扰动图1强度",range(0,2)) = 1.0
        _Wrap2Size("扰动图2大小",range(0,4)) = 2.0
        _Wrap2SpeedX("扰动图2流速X",range(0,1)) = 0.5
        _Wrap2SpeedY("扰动图2流速Y",range(0,1)) = 0.5
        _Wrap2Pow("扰动图2强度",range(0,2)) = 1.0
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

            Tags{
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _WrapTex; 
            uniform half _FlowSpeedX;
            uniform half _FlowSpeedY;
            uniform half _Wrap1Size;
            uniform half _Wrap1SpeedX;
            uniform half _Wrap1SpeedY;
            uniform half _Wrap1Pow;
            uniform half _Wrap2Size;
            uniform half _Wrap2SpeedX;
            uniform half _Wrap2SpeedY;
            uniform half _Wrap2Pow;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);
                o.uv0 =  v.uv - frac(_Time.x * float2(_FlowSpeedX,_FlowSpeedY));
                o.uv1 =  v.uv * _Wrap1Size - frac(_Time.x * float2(_Wrap1SpeedX,_Wrap1SpeedY));
                o.uv2 =  v.uv * _Wrap2Size - frac(_Time.x * float2(_Wrap2SpeedX,_Wrap2SpeedY));
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 var_Wrap1 = tex2D(_WrapTex,i.uv1).rgb;
                half3 var_Wrap2 = tex2D(_WrapTex,i.uv2).rgb;

                //扰动混合
                half2 var_wrap1 = (var_Wrap1.xy - 0.5) * _Wrap1Pow;

                half2 var_wrap2 = (var_Wrap2.xy - 0.5) * _Wrap2Pow;

                //扰动UV
                float2 wrap_uv = i.uv0 + var_wrap1 + var_wrap2;

                //采样贴图
                half3 var_MainTex = tex2D(_MainTex,wrap_uv);

                return half4(var_MainTex,1.0);                             
            }
            ENDCG
        }
    }
}
