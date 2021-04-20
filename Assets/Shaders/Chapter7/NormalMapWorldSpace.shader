/*
	Summary
	fixed3 worldBinormal = cross(normalize(worldNormal), normalize(worldTangent)) * v.tangent.w;
	计算切线的时候为什么要* w
	因为与法线和切线方向垂直的方向有两个，w决定了我们使用哪一个方向

	在world space中计算
	tangent space ---> world space
	tangent在world space中的正交基很好求，得到正交基后按列展开就可以了
*/
Shader "AweSomeUnityShaders/Chapter 7/NormalMap World Space"{

	Properties{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1.0
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader{
		pass{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldPos = UnityObjectToWorldDir(v.vertex);
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(normalize(worldNormal), normalize(worldTangent)) * v.tangent.w;
				// 将world pos 保存在w分量中，这样更节省空间
				o.TtoW0 = float4(worldNormal.x, worldBinormal.x, worldTangent.x, worldPos.x);
				o.TtoW1 = float4(worldNormal.y, worldBinormal.y, worldTangent.y, worldPos.y);
				o.TtoW2 = float4(worldNormal.z, worldBinormal.z, worldTangent.z, worldPos.z);

				return o;

			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// get normal
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				// compute normal
				fixed3 tangentNormal;
				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				fixed3 bump = normalize(half3(dot(tangentNormal, i.TtoW0.xyz), dot(tangentNormal, i.TtoW1.xyz), dot(tangentNormal, i.TtoW2.xyz)));

				// compute blin-phong
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));
				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Specular"

}