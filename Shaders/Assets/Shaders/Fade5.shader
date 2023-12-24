Shader "Practice/Fade5"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_Progress ("Progress", range(0, 1)) = 0.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			fixed _Progress;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed2 screenUV(fixed2 uv)
            {
                fixed2 temp = uv * 2 - 1.0;
                fixed dx = ddx(temp.x);
                fixed dy = ddy(temp.y);
                fixed aspect = dy / dx;
                temp.x *= aspect;
                return temp;
            }

			fixed2 rectToPolar(fixed2 p, fixed2 ms) {
				p -= ms / 2.0;
				const float PI = 3.1415926534;
				float r = length(p);
				float a = ((atan2(p.y, p.x) / PI) * 0.5 + 0.5) * ms.x;
				return fixed2(a, r);	
			}

			fixed2 polar(fixed2 cartesian)
			{
				fixed distance = length(cartesian);
				fixed angle = atan2(cartesian.y, cartesian.x);
				return fixed2(angle / UNITY_TWO_PI, distance);
			}

			fixed random(fixed2 pixel)
            {
                return frac(sin(dot(pixel, fixed2(12.9898, 78.233))) * 43758.5453123);
            }

            fixed perlinNoise(fixed2 pixel)
            {
                fixed2 i = floor(pixel);
                fixed2 f = frac(pixel);

                fixed a = random(i);
                fixed b = random(i + fixed2(1.0, 0.0));
                fixed c = random(i + fixed2(0.0, 1.0));
                fixed d = random(i + fixed2(1.0, 1.0));

                fixed2 u = f * f * (3.0 - 2.0 * f);

                return lerp(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            }

            #define NUM_OCTAVES 5
            
            fixed fbm(fixed2 pixel)
            {
                fixed v = 0.0;
                fixed a = 0.5;
                fixed2 shift = fixed2(100, 100);
                fixed2x2 rotation = fixed2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));

                for (int i = 0; i < NUM_OCTAVES; ++i)
                {
                    v += a * perlinNoise(pixel);
                    pixel = mul(rotation, pixel) * 2.0 + shift;
                    a *= 0.5;
                }

                return v;
            }
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed2 uv = screenUV(i.uv);
				fixed2 polarUv = polar(uv);
				polarUv.x *= 1;
				polarUv.y *= 0.5;
				fixed2 noiseTimeOffset = fixed2(_Time.y / 25, -_Time.y / 10);
				//fixed noise = tex2D(_NoiseTex, polarUv + noiseTimeOffset);
				fixed noise = perlinNoise(polarUv * 25 + noiseTimeOffset);
				return noise;
				noise = smoothstep(0.1, 0.5, noise);
				noise *= noise;

				fixed circle = length(uv);
				circle = smoothstep(0.1, 0.9, circle);

				fixed noise1 = smoothstep(0.1, 0.2, noise);
				fixed noise2 = smoothstep(0.9, 0.95, noise);
				noise = 0.5 * noise1 + 0.25 * noise2;
				return noise;
				return circle * noise;
				return circle * noise;
				return noise;
			}
			ENDCG
		}
	}
}