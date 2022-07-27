Shader "YF/ScreenWarp"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _WarpTex ("扰动图 R:左右方向扰动 G:上下方向扰动",2D) = "black" {} 
        _Opacity ("不透明度",range(0,1)) = 0.5
        _WarpMidVal ("扰动中间值",range(0,1)) = 0.5
        _WarpPow ("扰动强度",range(0,5)) = 1
        _FlowSpeed ("扰动速度",range(0,10)) = 5
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

        //获取背景纹理
        GrabPass{
            "_BGTex"
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
            uniform sampler2D _WarpTex; uniform float4 _WarpTex_ST;
            uniform half _Opacity;
            uniform half _WarpMidVal;
            uniform half _WarpPow;
            uniform half _FlowSpeed;
            uniform sampler2D _BGTex;

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
                float4 grapPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv0 = v.uv;
                o.uv1 = TRANSFORM_TEX(v.uv,_WarpTex) - float2(0.0,_Time.x * _FlowSpeed);
                o.grapPos = ComputeGrabScreenPos(o.pos);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv0);

                half3 var_WarpTex = tex2D(_WarpTex, i.uv1).rgb;

                //【扰动采样背景纹理的坐标】
                i.grapPos.xy += (var_WarpTex.xy - _WarpMidVal) * _WarpPow;  // i.grabPos.xy 作为UV坐标

                half3 var_BGTex = tex2Dproj(_BGTex,i.grapPos).rgb;

                //【用不透明度控制前面和背景混合量——混合模式：正常混合】
                half3 finalRGB =  lerp(1.0, var_MainTex.rgb , _Opacity) * var_BGTex;

                //【不透明度】
                half opacity = var_MainTex.a * _Opacity;

                return half4(finalRGB * opacity, opacity);
            }
            ENDCG
        }
    }
}
