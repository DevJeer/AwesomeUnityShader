// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
				summary
	
		// compute up Dir 防止法线与upDir重合
		float3 upDir = abs(normalDir.y > 0.99) ? float3(0, 0, 1) : float3(0, 1, 0);
		// left hand space
		float3 rightDir = normalize(cross(normalDir, upDir));
		upDir = normalize(cross(rightDir, normalDir));

		main  right  为x轴
			  up     为y轴
			  normal 为z轴

		广告牌的关键是如何构建旋转矩阵
		旋转矩阵构建可以分为两个思路
		假设在model space  物体原点为(0, 0, 0) 摄像机的方向为normal的方向
		1. 法线不变，这意味着物体始终会朝向摄像机
			当法线不变的时候，为了防止法线与upDir重合，可以手动将UpDir设置为(0, 0, 1)
			这样我们可以得到rightDir    rightDir = cross(normal, UpDir) 这是在左手坐标系下
			得到rightDir之后，我们又可以得到upDir   upDir = cross(rightDir, normalDir) 这是在左手坐标系下

			这样我们就完成了旋转矩阵的构建
		2. upDir不变，
			当upDir不变，则rightDir =cross(normal, upDir)
			              upDir = cross(rightDir, normalDir);  这里因为_VerticalBillboarding为0的时候，normalDir.y == 0
						  所以upDir是固定的
*/
Shader "AweSomeUnityShaders/Chapter 11/Billboard"{


	Properties{
		_MainTex("MainTex", 2D) = "white"{}
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding("Vertical Restrains", Range(0, 1)) = 1
	}

	SubShader{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

		pass{
			Tags { "LightMode" = "ForwardBase" }

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;

			struct a2v{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			struct v2f{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;

				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				float3 normalDir = viewer - center;

				normalDir.y = normalDir.y * _VerticalBillboarding;
				// 当_VerticalBillboarding为1的时候，法线固定。否则upDir固定
				normalDir = normalize(normalDir);

				// compute up Dir 防止法线与upDir重合
				float3 upDir = abs(normalDir.y > 0.99) ? float3(0, 0, 1) : float3(0, 1, 0);
				// left hand space
				float3 rightDir = normalize(cross(normalDir, upDir));
				upDir = normalize(cross(rightDir, normalDir));
				// 得到偏移
				float3 centerOffs = v.vertex.xyz - center;
				// 根据旋转矩阵对当前顶点进行移动
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

				o.pos = UnityObjectToClipPos(localPos);
				o.uv = v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				return o;

			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 color = tex2D(_MainTex, i.uv);
				color.rgb *= _Color.rgb;
				
				return color;
			}
			ENDCG

		}


	}

	Fallback "Transparent/VertexLit"
}