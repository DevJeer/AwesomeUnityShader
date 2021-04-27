// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

/***

			summary
o.worldRefr = refract(-normalize(o.worldViewDir), o.worldNormal, _RefractRatio);
fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

		1. 计算折射的方向，是通过内置的refract函数进行计算的，第三个par为折射率  使用worldViewDir是因为光路的可逆性，在计算采样cubemap的光线的时候，viewDir == lightDir
		2. 通过折射的方向来采样Cubemap并与_RefractColor进行乘积

lerp的用法
		lerp(a, b, w) = a + w * (b - a)

		_RefractAmount 为反射颜色所占的比例
		_RefractRatio 可以模拟不同介质
***/
Shader "AweSomeUnityShaders/Chapter 10/Refraction"{

	Properties{
		_Color("Colro Tint", Color) = (1, 1, 1, 1)
		_RefractColor("Refraction Color", Color) = (1, 1, 1, 1)
		_RefractAmount("Refraction Amount", Range(0, 1)) = 1
		_RefractRatio("Refraction Ratio", Range(0.1, 1)) = 0.5
		_Cubemap("Refraction Cubemap", Cube) = "_Skybox"{}
	}

	SubShader{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }

		pass{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed4 _RefractColor;
			float  _RefractAmount;
			fixed  _RefractRatio;
			samplerCUBE _Cubemap;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefr : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				// Important
				o.worldRefr = refract(-normalize(o.worldViewDir), o.worldNormal, _RefractRatio);

				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldLightDir, worldNormal));
				// Important
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				// lerp(a, b, w) == a + w * (b - a)  w为1 全为折射的颜色  w为0 全为diffuse的颜色
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;

				return fixed4(color, 0.0);
			}


			ENDCG
		}

	}

	Fallback "Reflective/VertexLit"

}