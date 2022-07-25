Shader "YF/UV_Flow"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _Opacity ("不透明度", range(0, 1)) = 0.5
        _NoiseTex ("噪声图", 2d) = "gray"{}
        _NoiseInt ("噪声强度", range(0, 5)) = 0.5
        _FlowSpeed ("流动速度", range(0, 10)) = 5
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

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform sampler2D _MainTex;
            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform half _Opacity;
            uniform half _NoiseInt;
            uniform half _FlowSpeed;

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
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);
                o.uv0 = v.uv;
                o.uv1 = TRANSFORM_TEX(v.uv, _NoiseTex);    
                o.uv1.y = o.uv1.y - frac(_Time.x * _FlowSpeed);  
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv0);      
                half3 var_NoiseTex = tex2D(_NoiseTex,i.uv1).r;

                half3 finalRGB = var_MainTex.rgb;
                half noise = lerp(1.0,var_NoiseTex * 2.0,_NoiseInt);
                noise = max(0.0,noise);
                half Opacity = var_MainTex.a * _Opacity * noise;
                return half4(finalRGB,Opacity);                             
            }
            ENDCG
        }
    }
}
