Shader "YF/ScreenUV_Bug"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _Opacity ("不透明度",range(0,1)) = 0.5
        _ScreenTex ("屏幕纹理",2D) = "black" {}
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
            uniform half _Opacity;
            uniform sampler2D _ScreenTex; uniform float4 _ScreenTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 screenuv : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);    
                o.uv0 = v.uv;
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                o.screenuv = posVS.xy;
                /*
                错误方案
                如果直接使用视角空间的XY坐标作为屏幕UV，会导致贴图有撕裂感
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                o.screenuv = posVS.xy;
                */
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex,i.uv0);
                half var_ScreenTex = tex2D(_ScreenTex,i.screenuv).r;
                half3 finalRGB = var_MainTex.rgb;
                half Opacity = var_MainTex.a * _Opacity * var_ScreenTex;
                //return half4(finalRGB * Opacity,Opacity);
                return half4(finalRGB * Opacity,Opacity);
            }
            ENDCG
        }
    }
}
