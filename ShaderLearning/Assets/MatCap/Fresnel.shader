Shader "YF/Fresnel"
{
Properties
    {
        _FresnelPow ("FresnelPow", Range(0, 10)) = 1
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }       
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform float _FresnelPow;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 posCS : SV_POSITION;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;            
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                //准备向量
                float3 nDirWS = i.nDirWS;                                         //获取世界空间下的法线贴图信息
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);//获取视角空间下的法线贴图信息
                //准备中间量
                float vdotn = dot(vDirWS,nDirWS);
                //计算结果
                float3 fresnel = pow(max(0.0,1.0-vdotn),_FresnelPow);
                //返回结果
                return float4(fresnel,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
