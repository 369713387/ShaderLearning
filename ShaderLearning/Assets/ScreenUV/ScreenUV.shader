Shader "YF/ScreenUV"
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
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;//顶点信息OS->VS
                //【模型原点到相机的z方向距离(观察空间为负值)】
                float originDistance = UnityObjectToViewPos(float3(0.0,0.0,0.0)).z;//原点位置OS->VS,z轴坐标可以代表相机深度
                //【去除因深度原因产生的拉伸】
                o.screenuv = posVS.xy / posVS.z;
                //【纹理大小跟随物体原点到相机的距离而变化】
                o.screenuv *= originDistance;
                //【启用Tiling，Offset，用Offset来控制uv流速】
                o.screenuv = o.screenuv * _ScreenTex_ST.xy - frac(_Time.x * _ScreenTex_ST.zw);
                /*
                错误方案
                如果直接使用视角空间的XY坐标作为屏幕UV，会导致贴图有撕裂感
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                o.screenuv = posVS.xy;
                */
                /*
                正确方案
                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;//顶点信息OS->VS
                //【模型原点到相机的z方向距离(观察空间为负值)】
                float originDistance = UnityObjectToViewPos(float3(0.0,0.0,0.0)).z;//原点位置OS->VS,z轴坐标可以代表相机深度
                //【去除因深度原因产生的拉伸】
                o.screenuv = posVS.xy / posVS.z;
                //【纹理大小跟随物体原点到相机的距离而变化】
                o.screenuv *= originDistance;
                //【启用Tiling，Offset，用Offset来控制uv流速】
                o.screenuv = o.screenuv * _ScreenTex_ST.xy - frac(_Time.x * _ScreenTex_ST.zw);
                */
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex,i.uv0);
                half var_ScreenTex = tex2D(_ScreenTex,i.screenuv).r;
                half3 finalRGB = var_MainTex.rgb;
                half Opacity = var_MainTex.a * _Opacity * var_ScreenTex;
                return half4(finalRGB * Opacity, Opacity);
            }
            ENDCG
        }
    }
}
