// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


/*
		Summary
1. FallBack  pass SubShader 这些关键字都可以随意大小写  在unity中会将它们都转换为大写
2. : POSITION 之类的 为hlsl的语义，相当于传递数据的管道

*/

Shader "AweSomeUnityShaders/Chapter 6/Diffuse Vertex-Level"
{
	Properties{
		// (name, unity Properties)
		_Diffuse("diffuse color:", COLOR)  = (1, 1, 1, 1)
	}

	SubShader{

		// pass1
		pass
		{
			// 使用前向光
			Tags  { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			struct a2v{
				float4 vertex : POSITION;  // POSITION 仅仅表示输入的是一个float4 类型的数据
				float3 normal : NORMAL;
			};
			
			struct v2f{
				float4 pos : SV_POSITION;  // SV开头表示为system-value
				fixed3 color : COLOR;
			};

			v2f vert(a2v v){
				v2f outputValue;
				
				// 转换到裁剪空间中 unity 会默认进行裁减 /w的操作
				outputValue.pos = UnityObjectToClipPos(v.vertex);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				// 这一步避免求逆矩阵
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				// light dir
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				// compute diffuse
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

				outputValue.color = ambient + diffuse;
				return outputValue;
			}


			fixed4 frag(v2f i) : SV_TARGET0 {   // SV_TARGET0表示输出到的位置 它就是一张图片
				return fixed4(i.color, 1.0);
			}
			
			ENDCG
		}
	}

	FallBack "DIFFUSE"
}