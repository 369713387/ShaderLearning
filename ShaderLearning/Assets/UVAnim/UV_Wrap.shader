Shader "YF/UV_Wrap"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _Opacity ("不透明度", range(0, 1)) = 0.5
        _WrapTex ("扭曲图", 2d) = "gray"{}
        _WrapPow("扭曲强度",range(0,1)) = 0.5
        _NoisePow ("噪声强度", range(0, 2)) = 0.5
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
            uniform sampler2D _WrapTex; uniform float4 _WrapTex_ST;
            uniform half _Opacity;
            uniform half _WrapPow;
            uniform half _NoisePow;
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
                o.uv1 = TRANSFORM_TEX(v.uv, _WrapTex);    
                o.uv1.y = o.uv1.y - frac(_Time.x * _FlowSpeed);  
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 var_WarpTex = tex2D(_WrapTex,i.uv1).rgb;   // 噪声图(RGB的各个值的范围为0-1)
                float2 uvOffset = (var_WarpTex.rg - 0.5) * _WrapPow; // 计算UV偏移值(RGB的各个值的范围映射到-0.5-0.5)
                float2 uv0 = i.uv0 + uvOffset;// 应用UV偏移量
                half4 var_MainTex = tex2D(_MainTex,uv0);// 偏移后UV采样MainTex
                half3 finalRGB = var_MainTex.rgb;
                float noise = lerp(1.0,var_WarpTex.b * 2.0,_NoisePow);
                noise = max(0.0,noise);
                half opacity = var_MainTex.a * _Opacity * noise;
                return half4(finalRGB,opacity);                             
            }
            ENDCG
        }
    }
}
