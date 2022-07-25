Shader "YF/Fire"
{
    Properties
    {
        _MaskTex ("R:外焰 G:内焰 B:透贴", 2D) = "blue" {}
        _NoiseTex("R:噪声贴图1 G:噪声贴图2",2D) = "gray" {}
        _Noise1Size("噪声贴图1的噪声大小",range(0,5)) = 1
        _Noise1Flowspeed("噪声贴图1的流速",range(0,10)) = 0.2
        _Noise1Pow("噪声贴图1的噪声强度",range(0,1)) = 0.2
        _Noise2Size("噪声贴图2的噪声大小",range(0,5)) = 1
        _Noise2Flowspeed("噪声贴图2的流速",range(0,10)) = 0.2
        _Noise2Pow("噪声贴图2的噪声强度",range(0,1)) = 0.2
        [HDR]_ColorInner("内焰颜色",color) = (1.0,0.0,0.0,1.0)
        [HDR]_ColorOuter("外焰颜色",color) = (0.0,0.0,1.0,1.0)
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

            uniform sampler2D _MaskTex; uniform float4 _MaskTex_ST;
            uniform sampler2D _NoiseTex; 
            uniform half _Noise1Size;
            uniform half _Noise1Flowspeed;
            uniform half _Noise1Pow;
            uniform half _Noise2Size;
            uniform half _Noise2Flowspeed;
            uniform half _Noise2Pow;
            uniform half3 _ColorInner;
            uniform half3 _ColorOuter;

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
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv0 = TRANSFORM_TEX(v.uv,_MaskTex);       //获取遮罩的UV信息，支持ST
                o.uv1 = o.uv0 * _Noise1Size - float2(0.0,frac(_Time.x * _Noise1Flowspeed));//获取噪声图1的UV信息，UV流动仅需要V轴方向的变化
                o.uv2 = o.uv0 * _Noise2Size - float2(0.0,frac(_Time.x * _Noise2Flowspeed));//获取噪声图2的UV信息，UV流动仅需要V轴方向的变化
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half var_wrapMask = tex2D(_MaskTex,i.uv0).b;       // 采样扰动遮罩
                half var_Noise1Tex = tex2D(_NoiseTex, i.uv1).r;    // 采样噪声图1
                half var_Noise2Tex = tex2D(_NoiseTex, i.uv2).g;    // 采样噪声图2
                
                half noise = var_Noise1Tex * _Noise1Pow + var_Noise2Tex * _Noise2Pow;//噪声混合

                float2 wrapUV = i.uv0 - float2(0.0,noise) * var_wrapMask; //计算扰动后的UV

                half2 mask = tex2D(_MaskTex,wrapUV).rg;// 采样遮罩贴图

                half3 finalRGB = mask.r * _ColorInner + mask.g * _ColorOuter; //计算最终颜色

                half opacity = mask.r + mask.g;//计算不透明度

                return half4(finalRGB,opacity);
            }
            ENDCG
        }
    }
}
