Shader "YF/MatCap"
{
    Properties
    {
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _Matcap ("Matcap", 2D) = "gray" {}
        _FresnelPow ("FresnelPow", Range(0, 10)) = 1
        _EnvSpecInt ("EnvSpecInt", Range(0, 5)) = 1
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

            uniform sampler2D _NormalMap;
            uniform sampler2D _Matcap;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 posCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;            
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv0;
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                //准备向量
                float3 NormalmapTS = UnpackNormal(tex2D(_NormalMap,i.uv)).rgb;//解码法线贴图的信息
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);          //构建TBN矩阵
                float3 nDirWS = normalize(mul(NormalmapTS,TBN));          //获取世界空间下的法线贴图信息
                float3 nDirVS = mul(UNITY_MATRIX_V,nDirWS);               //获取视角空间下的法线贴图信息
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);//获取视角空间下的法线贴图信息
                //准备中间量
                float vdotn = dot(vDirWS,nDirWS);
                float2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                //计算结果
                float3 matcap = tex2D(_Matcap,matcapUV);
                float fresnel = pow(max(0.0,1.0-vdotn),_FresnelPow);
                float3 envSpecLighting = matcap * fresnel * _EnvSpecInt;
                //返回结果
                return float4(envSpecLighting,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
