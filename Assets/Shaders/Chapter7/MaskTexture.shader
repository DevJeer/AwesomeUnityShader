/**
	summary 
fixed3 specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
重点是如何采样MaskTexture

**/

Shader "AweSomeUnityShaders/Chapter 7/Mask Texture"{

	Properties{
		_Color ("颜色", Color) = (1, 1, 1, 1)
		_MainTex ("颜色贴图", 2D) = "white" {}
		_BumpMap ("法线贴图", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_SpecularMask ("遮罩纹理", 2D) = "white" {}
		_SpecularScale ("Specular Scale", Float) = 1.0
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}

	SubShader{
		pass{
			Tags { "LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float _BumpScale;
			sampler2D _SpecularMask;
			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;

				// 定义这个宏，unity就会为我们计算object space ---> tangent space的转换矩阵
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;

			}

			fixed4 frag(v2f i) : SV_Target {
				// compute ligth dir and view dir
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);


				// fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				// tangentNormal.xy *= _BumpScale;
				// tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				fixed4 packedNormal = tex2D(_BumpMap, i.uv);
				fixed3 tangentNormal;
				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;  // 转换法线到[-1, 1]之间  因为图像存储的法线范围为[0, 1]
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				// Important
				fixed3 specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
				fixed3 specular = _LightColor0.rgb * albedo * pow(saturate(dot(halfDir, tangentNormal)), _Gloss) * specularMask;

				return fixed4(ambient + diffuse + specular, 1.0);

			}
			

			ENDCG
		}
	}

	Fallback "Specular"

}