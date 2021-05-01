/*

	summary

	1. 主要是利用_Time时间来计算当前帧的行和列
    2. 利用行列做偏移计算出当前采样的坐标在当前图片中的uv坐标
	3. uv / 行or列计算出具体某帧的图片uv
	float time = floor(_Time.y * _Speed);
	// 计算行 列
	float row = floor(time / _HorizontalAmount);
	float column = time - row * _HorizontalAmount;

	half2 uv = i.uv + half2(column, -row);
	// 得到具体帧的uv
	uv.x /= _HorizontalAmount;
	uv.y /= _VerticalAmount;
	// 计算出uv来采样当前frame image中的一个图片
	fixed4 c = tex2D(_MainTex, uv);

*/
Shader "AweSomeUnityShaders/Chapter 11/Image Sequence Animation"{

	Properties{
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Image Sequence", 2D) = "white"{}
		_HorizontalAmount("Horizontal Amount", float) = 4
		_VerticalAmount("Vertical Amount", float) = 4
		_Speed("Speed", Range(1, 100)) = 30
	}

	SubShader{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

		pass{
			Tags { "LightMode"="ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;
			
			struct a2v {  
			    float4 vertex : POSITION; 
			    float2 texcoord : TEXCOORD0;
			};  

			struct v2f {  
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};  

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET
			{
				float time = floor(_Time.y * _Speed);
				// 计算行 列
				float row = floor(time / _HorizontalAmount);
				float column = time - row * _HorizontalAmount;

				half2 uv = i.uv + half2(column, -row);
				// 得到具体帧的uv
				uv.x /= _HorizontalAmount;
				uv.y /= _VerticalAmount;
				// 计算出uv来采样当前frame image中的一个图片
				fixed4 c = tex2D(_MainTex, uv);

				c.rgb *= _Color;

				return c;
			}
			ENDCG
		}

	}

	Fallback "Transparent/VertexLit"
}