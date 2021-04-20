Shader "AweSomeUnityShaders/Chapter 7/SingleTexture"{

	Properties{
		_Color("纹理颜色", Color) = (1, 1, 1, 1)
		_MainTex("纹理", 2D) = "white"{}
		_Specular("高光", Color) = (1, 1, 1, 1)
		_Gloss("高光因子", Range(8, 256)) = 50

	}

	SubShader{

		pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM

			#include "Lighting.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;
			sampler2D _MainTex;
			fixed4 _Specular;
			float _Gloss;
			// Scale && Translate
			float4 _MainTex_ST;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texCoord : TEXCOORD0;
			};

			struct v2f{
				/*这块 : TEXCOORD0只是为了指明类型*/
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;

			};

			v2f vert(a2v v)
			{
				v2f o;
				// 转换到clip space
				o.pos = UnityObjectToClipPos(v.vertex);

				// get normal
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				// get world pos
				o.worldPos = UnityObjectToWorldDir(v.vertex);

				o.uv = v.texCoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				// or
				//o.uv = TRANSFORM_TEX(v.texCoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				// 混合texture 和 color
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

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