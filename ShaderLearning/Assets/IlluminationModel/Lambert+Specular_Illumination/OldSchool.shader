Shader "Unlit/OldSchool"
{
    Properties
    {
        //定义属性
        //_名称("面板标签",类型(参数),可无)) = 默认值
        _MainTex("贴图",2d) = "white" {}
        _MainCol("颜色",color) = (1.0,1.0,1.0,1.0)
        _SpecularPow("高光强度",range(0,90)) = 30
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            //输入结构
            struct appdata
            {
                float4 vertex : POSITION; //顶点信息
                float4 normal : NORMAL;   //法线信息
                float2 uv0 : TEXCOORD0;   //uv信息
            };

            //输出结构
            struct v2f
            {
                float4 posCS : SV_POSITION;//裁剪空间的顶点信息
                float4 posWS : TEXCOORD0;  //世界空间的顶点信息
                float3 nDirWS : TEXCOORD1; //世界空间的法线信息
                float2 uv : TEXCOORD2;     //uv信息
            };

            //声明属性
            uniform sampler2D _MainTex;
            uniform float3 _MainCol;
            uniform float _SpecularPow;

            v2f vert (appdata v)
            {
                v2f o;                                          //新建一个输出结构
                o.posCS = UnityObjectToClipPos(v.vertex);       //位置信息转换OS->CS
                o.posWS = mul(unity_ObjectToWorld,v.vertex);    //位置信息转换OS->WS
                o.nDirWS = UnityObjectToWorldNormal(v.normal);     //位置信息转换OSN->WSN
                o.uv = v.uv0;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备向量
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 nDir = i.nDirWS;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 hDir = normalize(lDir + vDir);
                //准备中间结果
                float3 ndotl = dot(nDir,lDir);
                float3 ndoth = dot(nDir,hDir);
                float4 MainTex = tex2D(_MainTex,i.uv);
                //光照模型
                float3 lambert = max(0.0,ndotl);
                float3 specular = pow(max(0.0,ndoth),_SpecularPow);
                float3 finalRGB = MainTex * _MainCol * lambert + specular;
                //返回结果
                return float4(finalRGB,1.0);
            }
            ENDCG
        }
    }
}
