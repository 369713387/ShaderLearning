Shader "YF/AlphaAdditive"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
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

            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);       // UV信息 支持TilingOffset
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);      // 采样贴图 RGB颜色 A透贴
                return var_MainTex;                             // 返回值
                //return var_MainTex * var_MainTex.a;           // 返回值
            }
            ENDCG
        }
    }
}
