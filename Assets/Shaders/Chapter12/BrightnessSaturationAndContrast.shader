/*
        summary
    亮度饱和度对比度计算的顺序不同，会影响输出的结果
    顺序一般为 亮度  饱和度  对比度
    appdata_img post effect一般采用抓取屏幕的方式来输出图片
    appdata_img 为屏幕的相关信息  包含了屏幕的顶点等信息

    post effect一般以_MainTex为默认输入

    计算亮度
    finalColor.rgb *= _Brightness;

    计算饱和度
    fixed lumiance = 0.2125 * ImageColor.r + 0.7154 * ImageColor.g + 0.0721 * ImageColor.b;

    fixed3 lumianceColor = fixed3(lumiance, lumiance, lumiance);
    finalColor = lumianceColor.rgb * _Saturation + (finalColor - lumianceColor) * _Saturation;

    // 计算对比度
    avgColor = fixed3(0.5, 0.5, 0.5);
    finalColor = lerp(avgColor, finalColor, _Contrast);
    


*/

Shader "AweSomeUnityShaders/Chapter 12/Brightness Saturation And Contrast"{

    Properties{
        _MainTex("Base(RGB)", 2D) = "white"{}
        _Brightness("亮度", Float) = 1
        _Saturation("饱和度", Float) = 1
        _Contrast("对比度", Float) = 1
    }

    SubShader{
        
        pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};

            v2f vert(appdata_img v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed4 renderTex = tex2D(_MainTex, i.uv);
                // compute brightness  亮度
                fixed3 finalColor = renderTex.rgb * _Brightness;

                // compute saturation  饱和度
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 lumianceColor = fixed3(luminance, luminance, luminance);
                finalColor = lerp(lumianceColor, finalColor, _Saturation);

                // compute contrast
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor, renderTex.a);
            }


            ENDCG
        }


    }

    Fallback Off
    
}