// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
		summary
blin-phong 光照模型避免了计算reflect dir，采用了 v + l 的方式来得到half vector，
并将dot(halfvector, normal)来模拟 dot(reflectdir, viewdir)
这样得到的效果是和phong模式差不多的，所以大多是采用blin-phong模式
*/

Shader "AweSomeUnityShader/Chapter 6/Blin-Phong"{

	Properties{
		_Diffuse ("漫反射", Color) = (1, 1, 1, 1)
		_Specular ("高光", Color) = (1, 1, 1, 1)
		_Gloss ("高光系数", Range(8.0, 256)) = 20

	}

	SubShader{

		pass{

			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
			#include "Lighting.cginc"
			
			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(a2v v) {
				v2f o;
				// Transform the vertex from object space to projection space
				o.pos = UnityObjectToClipPos(v.vertex);
				
				// Transform the normal from object space to world space
				// 计算worldNormal可以用UnityObjectToWorldNormal(v.normal)
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				
				// Transform the vertex from object spacet to world space
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 worldNormal = normalize(i.worldNormal);
				// 计算Lightdir可以用UnityWorldSpaceLightDir(i.worldPos)替换
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

				// compute h
				// 计算view dir可以用UnityWorldSpaceViewDir(i.worldPos)替换
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);

			}

			ENDCG
		}
	}

	Fallback "Specular"

}