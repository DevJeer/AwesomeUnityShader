/*
		summary
	主要使用菲涅尔等式计算lerp(diffuse, reflection, staurate(Fresnel));
	reflection 为采样的环境映射贴图 
	Fresnel为计算的菲涅尔等式的值  float
	fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

	FresnelScale为反射系数

*/

Shader "AweSomeUnityShaders/Chapter 10/Fresnel"{
	Properties{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.5
		_Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}
	}

	SubShader{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
		pass {
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed _FresnelScale;
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
  				fixed3 worldRefl : TEXCOORD3;
 	 			SHADOW_COORDS(4)
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				// WorldPos
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefl = reflect(-normalize(o.worldViewDir), normalize(o.worldNormal));

				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i): SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;
				// 计算菲涅尔等式
				// Important
				fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

				fixed3 diffuse = _Color.rgb * _LightColor0.rgb * saturate(dot(worldLightDir, worldNormal));

				fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;
				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}

	Fallback "Reflective/VertexLit"
}