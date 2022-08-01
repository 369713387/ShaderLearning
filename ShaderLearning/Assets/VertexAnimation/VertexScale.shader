Shader "YF/VertexScale"
{
    Properties
    {
        _MainTex ("贴图", 2D) = "white" {}
        _ScaleRange("缩放范围",range(0,0.5)) = 0.1
        _ScaleSpeed ("缩放速度",range(0,10)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform half _ScaleRange;
            uniform half _ScaleSpeed;

            // 声明常量
            #define TWO_PI 6.283185

            //顶点缩放动画
            void Scale(inout float3 vertex)
            {
                vertex.xyz *= 1.0 + _ScaleRange * sin(frac(_Time.x * _ScaleSpeed) * TWO_PI);
            }

            v2f vert (appdata v)
            {
                v2f o;
                Scale(v.vertex.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col = tex2D(_MainTex, i.uv).rgb;
                return fixed4(col,1.0);
            }
            ENDCG
        }
    }
}
