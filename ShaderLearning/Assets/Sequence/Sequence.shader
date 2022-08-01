Shader "YF/Sequence"
{
    Properties
    {
        _MainTex ("RGB:颜色 A：透贴", 2D) = "white" {}
        _OpacityMain   ("不透明度(主贴图)", range(0, 1)) = 0.5
        _OpacitySeq    ("不透明度(序列帧)", range(0, 1)) = 0.5
        _SequenceTex   ("序列帧", 2d) = "gray"{}
        _RowCount   ("行数", int) = 1
        _ColCount   ("列数", int) = 1
        _Speed      ("速度", range(0.0, 15.0)) = 1
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

        //使用AB透明混合渲染方式 渲染底层模型
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
            uniform half _OpacityMain;

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
                o.pos = UnityObjectToClipPos( v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_MainTex = tex2D(_MainTex, i.uv);      
                half3 finalRGB = var_MainTex.rgb;
                half opacity = var_MainTex.a * _OpacityMain;
                return half4(finalRGB * opacity,opacity);                           
            }
            ENDCG
        }

        //使用AD透明叠加渲染方式 渲染模型外层的序列图
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

            uniform sampler2D _SequenceTex; uniform float4 _SequenceTex_ST;
            uniform half _OpacitySeq;
            uniform half _RowCount;
            uniform half _ColCount;
            uniform half _Speed;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                //注意事项：UV的原点为图片的左下角，而序列帧的第一帧一版为左上角，需要进行一个转换
                //当ID = x 时 idv = x / col（向下取整） idu = x - idv * col（向下取整）
                v2f o;
                v.vertex.xyz += v.normal * 0.03;            // 顶点位置法线向外挤出，制作出一个模型的轮廓
                o.pos = UnityObjectToClipPos( v.vertex);    // 顶点位置 OS>CS
                o.uv = TRANSFORM_TEX(v.uv,_SequenceTex);    // 前置UV ST操作
                float id = floor(_Time.z * _Speed);         //计算序列ID，当前序列帧走到第几帧
                float idv = floor(id / _ColCount);          //计算V轴ID
                float idu = id - idv * _ColCount;           //计算U轴ID
                float stepu = 1.0 / _ColCount;              //计算V轴步幅
                float stepv = 1.0 / _RowCount;              //计算U轴步幅
                float2 initUV = o.uv * float2(stepu,stepv) + float2(0.0,stepv * (_ColCount - 1.0)); //计算ID为0时的初始UV
                o.uv = initUV + float2(idu * stepu,idv * stepv);//计算后续序列帧UV
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 var_Sequence = tex2D(_SequenceTex,i.uv);
                half3 finalRGB = var_Sequence.rgb;
                half opacity = var_Sequence.a * _OpacitySeq;
                return half4(finalRGB * opacity,opacity);                             
            }
            ENDCG
        }
    }
}
