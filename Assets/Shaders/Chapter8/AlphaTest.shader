/*
	summary
使用unity内置的clip函数进行透明度测试
clip ： 当给定参数中的任何一个分量为负数，那么就会舍弃当前像素的输出颜色
_Cutoff为控制是否可以通过透明度测试
Important:
使用Alpha test的物体要么透明度为1， 要么透明度为0
// Alpha test
	//clip(texColor.a - _Cutoff);
	// _Cutoff为1的时候 就clip
	if((texColor.a - _Cutoff) < 0)
	{
		discard;
	}

*/

Shader "AweSomeUnityShaders/Chapter 8/Alpha Test"{

	Properties{
		_Color("颜色", Color) = (1, 1, 1, 1)
		_MainTex("颜色贴图", 2D) = "white"{}
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
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
			fixed _Cutoff;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;

			};

			v2f vert(a2v v){
				v2f o;
				// transform to clip space
				o.pos = UnityObjectToClipPos(v.vertex);
				// world Normal
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				// world pos
				o.worldPos = UnityObjectToWorldDir(v.vertex);
				// uv
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				return o;
			}

			fixed4 frag(v2f i): SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);

				// Alpha test
				//clip(texColor.a - _Cutoff);
				// _Cutoff为1的时候 就clip
				if((texColor.a - _Cutoff) < 0)
				{
					discard;
				}

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = albedo * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Transparent/Cutout/VertexLit"
}