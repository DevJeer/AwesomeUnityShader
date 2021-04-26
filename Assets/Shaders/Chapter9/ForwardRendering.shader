// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


/*
            summary
    unity中的高级光照
    点光源，太阳光，聚光灯
    对于多光源来说，我们有多种渲染的路径：前向渲染，延迟渲染，当灯光比较多的时候，一般使用延迟渲染，当前脚本使用前向渲染

    多光源前向渲染
    使用两个pass  
        pass1：based pass      主要计算directional light 自发光 环境光这种只需要渲染一次的东西
                pass1只执行一次
        pass2：additional pass 主要用来计算点光源  聚光灯这些需要多次叠加的灯光
            tips：需要设置开启blend  pass2需要执行多次（和光源的数量有关）

    光源的衰减：
        点光源和聚光灯是随着距离衰减的，所以需要计算一个衰减系数
        unity中衰减系数是直接存储在_LightTexture0中的，我们通过访问它对角线上的点，并利用unity提供的UNITY_ATTEN_CHANNEL就可以获得衰减系数
    
    重点是：如何计算衰减并应用上
    ***计算：通过LUT查找
    ***应用，directional light的衰减为1，其他应用在diffuse 和 specular上
*/

Shader "AweSomeUnityShaders/Chapter 9/Forward Rendering"{

    Properties{
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader{
        Tags { "RenderType" = "Opaque" }
        // pass1 计算forward base light color
        pass{
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            // 使用这个编译指令可以保证shader中使用光照衰减等光照变量可以被正确赋值
            #pragma multi_compile_fwdbase
            #pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            fixed _Gloss;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = UnityObjectToWorldDir(v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                // 在base pass中，光照一定是directional light
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 halfDir = normalize(viewDir + worldLightDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * saturate(pow(saturate(dot(halfDir, worldNormal)), _Gloss));

                fixed atten = 1.0;
                return fixed4(ambient + atten * (specular + diffuse), 1.0);
            }

            ENDCG
        }

        // pass 2 为additional light 每个除太阳光之外的每个光源都要执行一次这个pass
        pass{
            Tags {"LightMode" = "ForwardAdd" }
            // 开启混合，可以将结果与base混合
            Blend One One
            CGPROGRAM
            // 可以保证在Additional Pass中访问到正确的光照变量
            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

            v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}

            fixed4 frag(v2f i) : SV_Target {
                fixed3 worldNormal = normalize(i.worldNormal);
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                // 使用_LightColor0来获得默认的光照颜色  它可以是点光源 平行光 聚光灯
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 这些宏是unity内部定义的，如果当前处理的光源是下面中的一种类型，那么就会定义相应的宏
                #ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
                #else
                    #if defined(POINT)
                        // 点光源随距离衰减

                        // important
                        // 得到光源在光源空间中的位置
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                        // 这里使用lightcoord * lightcoord避免开方， 使用rr是因为衰减值只保存在_LightTexture0的对角线处
                        // unity使用_LightTexture0来保存光源衰减的值，如果对当前光源使用了cookie，那么衰减查找的纹理是_LightTextureB0
                        // UNITY_ATTEN_CHANNEL可以得到衰减纹理中的衰减值所在的分量，---->得到最终衰减值
                        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined(SPOT)
                        // 聚光灯随距离衰减
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                        // 这里可以看到spotlight是使用了cookie的
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * 
                        tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        // 其他光源不随距离衰减
                        fixed atten = 1.0;
                    #endif
                #endif
                // additonal 不计算环境光
                return fixed4((diffuse + specular) * atten, 1.0);
            }
            
            ENDCG
        }
    }
	
    Fallback "Specular"
}