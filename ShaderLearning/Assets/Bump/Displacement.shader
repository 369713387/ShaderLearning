Shader "YF/Displacement"
{
    Properties
    {
        _MainTex ("贴图 (RGB)", 2D) = "white" {}
        _DisplacementTex ("位移贴图", 2D) = "gray" {}
        _Displacement ("位移", Range(0,1)) = 0.0
        _Specular("平滑度",Range(0,1)) = 0.0
        _Gloss("光泽度",Range(0,1)) = 0.0
        _Tess("镶嵌花纹", Range(1, 32)) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:vert tessellate:tessFixed

        uniform sampler2D _MainTex;
        uniform sampler2D _DisplacementTex;
        uniform half _Displacement;
        uniform half _Specular;
        uniform half _Gloss;
        uniform half _Tess;

        struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

        struct Input
        {
            float2 uv_MainTex;
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float4 tessFixed()
		{
			return _Tess;
		}

		void vert(inout appdata v)
		{
			float d = tex2Dlod(_DisplacementTex, float4(v.texcoord.xy, 0, 0)).r * _Displacement;
			v.vertex.xyz -= v.normal * d;
		}

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Specular = _Specular;
            o.Gloss = _Gloss;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
