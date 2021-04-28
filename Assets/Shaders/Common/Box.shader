
/*
		summary
	一般情况下 我们计算转换矩阵
	object space ---> tangent space
	需要知道模型在tangent space下的正交基，而这个不好求
	所以，我们求出 tangent space ---> object space， 我们需要知道tangent 在模型空间下的正交基，这个好求， （直接用正交基按列展开填充即可）
	我们就可以利用它的逆矩阵得到我们想要的矩阵

	tangent space ---> world space
	就需要知道tangent在world space下的正交基

	切线x 副切线y 法线z

	tips : 我们使用过的法线贴图是在切线空间下存储的
	在切线空间下计算的关键是 将 view dir 和 light dir转换到tangent space
	
*/

Shader "AweSomeUnityShaders/Chapter 7/NormalMap TangentSpace"{
	Properties{
		_Color("颜色", Color) = (1, 1, 1, 1)
		_MainTex("颜色贴图", 2D) = "white"{}
		_BumpMap("凹凸贴图", 2D) = "bump"{}
		// 这里float 和 Float有什么区别  待测试
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("镜面反射", Color) = (1, 1, 1, 1)
		_Gloss("高光因子", Range(8, 256)) = 20
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
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;

			};

			v2f vert(a2v v)
			{
				v2f o;
				// clip space
				o.pos = UnityObjectToClipPos(v.vertex);
				// _MainTex uv
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				// _BumpMap uv
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				// compute normal
				// 得到切线正交基在world space下的表示方法， 按列展开即可得到world space -> tangent space的转换矩阵
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
				// todo 
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);

				// 计算tangent space 下的light dir 和 view dir
				o.lightDir = mul(worldToTangent, UnityWorldSpaceLightDir(v.vertex));
				o.viewDir = mul(worldToTangent, UnityWorldSpaceViewDir(v.vertex));
				
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				// get normal
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				// compute normal
				// important
				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// phong 
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				// diffuse
				fixed3 diffuse = _LightColor0.rgb * albedo.rgb * max(0, dot(tangentNormal, tangentViewDir));

				// specular
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * albedo.rgb * pow(saturate(dot(halfDir, tangentNormal)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}


			ENDCG

		}

	}

	Fallback "Specular"

}