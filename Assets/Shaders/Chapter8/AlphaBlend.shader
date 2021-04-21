// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


/* 
	Summary
源颜色为 片元着色器产生的颜色
目标颜色为  已经存在于颜色缓冲中的颜色


Important fixed4(ambient + diffuse, texColor.a * _AlphaScale);
主要是将texColor.a的透明度通道与AlphaScale相乘得到最终的透明度

Blend SrcAlpha OneMinusSrcAlpha
设置混合因子
公式是 ： DstColor = SrcColor * srcAlpha + OneMinusSrcAlpha * DstColor

Tips: 要使用Alpha Blend 首先需要开启深度测试，但需要关闭深度写入
但是对于复杂的物体来说，这种方法得不到正确的结果
*/
Shader "AweSomeUnityShaders/Chapter 8/Alpha Blend"{

	Properties{
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_AlphaScale ("Alpha Scale", Range(0, 1)) = 1
	}

	SubShader{
		pass{
			Tags { "LightMode" = "ForwardBase" }

			// Alpha Blend需要关闭深度写入
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;

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
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed4 texColor = tex2D(_MainTex, i.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
			}

			ENDCG
		}
	}

	Fallback "Transparent/VertexLit"
}