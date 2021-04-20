/*
	summary
		fixed halfLambert = 0.5 * dot(worldLightDir, worldNormal) + 0.5;
		fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
	主要点在于如何采样ramp tex
	需要使用half lambert来作为uv坐标来进行采样
*/
Shader "AweSomeUnityShaders/Chapter 7/Ramp Texture"{

	Properties{
		_Color ("颜色", Color) = (1, 1, 1, 1)
		_RampTex ("渐变贴图", 2D) = "white" {}
		_Specular ("镜面高光", Color) = (1, 1, 1, 1)
		_Gloss ("高光因子", Range(8.0, 256)) = 20
	}

	SubShader{
		pass{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _RampTex;
			float4 _RampTex_ST;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = UnityObjectToWorldDir(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				// get world normal and world light dir
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// blin-phong
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed halfLambert  = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

				fixed3 diffuse = _LightColor0.rgb * diffuseColor;
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);


				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}

	Fallback "Specular"
}