﻿// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
		summary
half lambert与phong模式不同的地方为
		计算diffuse factor的时候 为 dot(normal, lightdir) * 0.5 + 0.5
		而 phong 为 saturate(dot(normal, lightdir)) 这导致了phong 模式的背面会完全是黑的，而half lambert则和向光面是一样的
*/

Shader "AweSomeUnityShaders/Chapter 6/Half Lambert"{

	Properties{
		_Diffuse("Diffuse color", Color) = (1, 1, 1, 1)

	}

	SubShader{

		pass{
			Tags { "LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Diffuse;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};

			v2f vert(a2v v) {
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// Transform the normal from object space to world space
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				// compute
				fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

				fixed3 color = diffuse + ambient;

				return fixed4(color, 1.0);
			}

			ENDCG

		}
		
	}

	Fallback "Diffuse"

}