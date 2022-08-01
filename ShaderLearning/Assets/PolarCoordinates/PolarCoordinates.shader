Shader "YF/PolarCoordinates"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}      
        [HDR]_Color ("混合颜色",color) = (1.0,1.0,1.0,1.0)
        _Opacity ("透明度",range(0,1)) = 0.5
        _Speed ("流动速度",float) = 0.5
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"             //修改渲染队列为透明队列
            "RenderType"="TransparentCutout"    // 对应改为Cutout
            "ForceNoShadowCasting"="True"       // 关闭阴影投射
            "IgnoreProjector"="True"            // 不响应投射器
        }

        Pass
        {
            Name "FORWARD"

            Tags{
                "LightMode" = "ForwardBase"
            }

            Blend One OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform sampler2D _MainTex;
            uniform half3 _Color;
            uniform half _Opacity;
            uniform half _Speed;

            #define PI 3.1415926

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv = v.uv;
                o.color = v.color;      
                return o;
            }

            //直角坐标转极坐标方法
            float2 RectToPolar(float2 uv,float2 centerUV){
                uv = uv - centerUV;
                float theta = atan2(uv.y,uv.x);// atan()值域[-π/2, π/2]一般不用; atan2()值域[-π, π]
                float r = length(uv);
                return float2(theta,r);
            }

            half4 frag (v2f i) : SV_Target
            {
                //直角坐标转换为极坐标
                float2 thetaR = RectToPolar(i.uv,float2(0.5,0.5));
                float2 polarUV = float2(
                    thetaR.x / PI * 0.5 + 0.5,
                    thetaR.y + frac(_Time.x * _Speed));

                half4 var_MainTex = tex2D(_MainTex,polarUV);
                half3 finalRGB = (1 - var_MainTex.rgb) * _Color;
                half opacity = (1-  var_MainTex.r) * _Opacity * i.color.b;
                return half4(finalRGB * opacity ,opacity);
            }
            ENDCG
        }
    }
}
