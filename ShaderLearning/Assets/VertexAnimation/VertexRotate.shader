Shader "YF/VertexRotate"
{
    Properties
    {
        _MainTex ("贴图", 2D) = "white" {}
        _RotateRange("旋转范围",range(0,90)) = 10
        _RotateSpeed ("旋转速度",range(0,50)) = 5
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
            uniform half _RotateRange;
            uniform half _RotateSpeed;

            // 声明常量
            #define TWO_PI 6.283185

            //顶点旋转动画
            void Rotate(inout float3 vertex)
            {
                float angleY = _RotateRange * sin(frac(_Time.x * _RotateSpeed) * TWO_PI);//计算要旋转的角度
                float radY = radians(angleY);                                            //角度转弧度单位
                float sinY, cosY = 0;
                sincos(radY,sinY,cosY);
                float2x2 Rotate_Matrix_Y = float2x2(cosY,sinY,-sinY,cosY);
                vertex.xz = mul(Rotate_Matrix_Y,float2(vertex.x,vertex.z));
                // vertex.xz = float2(
                //     vertex.x * cosY - vertex.z * sinY,
                //     vertex.x * sinY + vertex.z * cosY
                // );
            }

            v2f vert (appdata v)
            {
                v2f o;
                Rotate(v.vertex.xyz);
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
