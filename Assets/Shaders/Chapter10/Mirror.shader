/*
		summary
	镜子的效果是翻转x轴
	o.uv.x = 1.0 - o.uv.x;

	1. 将摄像机看到的图像渲染到renderTexture上
	2. 使用当前的shader采样renderTexture
*/

Shader "AweSomeUnityShaders/Chapter 10/Mirror"{

	Properties{
		_MainTex("Main Tex", 2D) = "white"{}
	}

	SubShader{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
		pass{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;

			struct a2v {
				float4 vertex : POSITION;
				float3 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				// Important
				// flip x
				o.uv.x = 1.0 - o.uv.x;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				return tex2D(_MainTex, i.uv);
			}

			ENDCG
		}
	}
	Fallback Off

}