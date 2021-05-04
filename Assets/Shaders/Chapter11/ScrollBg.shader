
// https://zhuanlan.zhihu.com/p/158462351 frac
/*
		summary
	1. 计算uv坐标   根据时间来进行计算  frac函数
	o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
	o.uv.xy += frac(float2(_Scroll1X, 0.0) * _Time.y);

	2. 根据得到的uv进行采样，双背景的时候，根据a值进行lerp
		fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
		c.rgb *= _Multiplier;
		c.rgb *= _Color.rgb;

*/
Shader "AweSomeUnityShaders/Chapter 11/Scrolling Background"{

	Properties{
		_MainTex("Base Layer", 2D) = "white"{}
		_DetailTex("2nd Layer", 2D) = "white"{}
		_Scroll1X("Base Layer scroll speed", float) = 1.0
		_Scroll2X("2nd Layer Speed", float) = 1.0
		_Multiplier("Layer Multiplier", float) = 1

		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}

	SubShader{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
		pass{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			// 这块尝试写不一致试试
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _Scroll1X;
			float _Scroll2X;
			// 控制整体亮度
			float _Multiplier;

			float4 _Color;

			struct a2v{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
			

			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				// frac返回当前向量中每个分量的小数部分
				// frac(v) = v - floor(v)
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.xy += frac(float2(_Scroll1X, 0.0) * _Time.y);
				o.uv.zw = v.texcoord.xy * _DetailTex_ST.xy + _DetailTex_ST.zw;
				o.uv.zw += frac(float2(_Scroll2X, 0.0) * _Time.y);

				return o;
			}

			fixed4 frag(v2f i) :SV_TARGET
			{
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);

				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
				c.rgb *= _Color.rgb;
				c.rgb *= _Multiplier;
				

				return c;
			}

			ENDCG

		}
	}

	Fallback "VertexLit"




}