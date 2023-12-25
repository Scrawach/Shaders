Shader "Practice/AnotherPractice"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FlowTex ("Flow Texture", 2D) = "white" {}
        _Progress ("Progress", range(-10, 10)) = 0.0
        _AnotherX ("Koef X", range(-10, 10)) = 0.0
        _AnotherY ("Koef Y", range(-10, 10)) = 0.0
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
            fixed _Progress;
            fixed _AnotherX;
            fixed _AnotherY;

            sampler2D _FlowTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed circle(fixed2 center, fixed radius)
            {
                return length(center) - radius;
            }

            fixed2 centeredUV(fixed2 uv)
            {
                fixed2 temp = uv * 2 - 1.0;
                fixed dx = ddx(temp.x);
                fixed dy = ddy(temp.y);
                fixed aspect = dy / dx;
                temp.x *= aspect;
                return temp;
            }

            fixed2 rectToPlanar(fixed2 position, fixed2 ms)
            {
                const fixed PI = 3.141592;
                position -= ms / 2.0;
                fixed r = length(position);
                fixed a = ((atan2(position.y, position.x) / PI) * 0.5 + 0.5) * ms.x;
                return fixed2(a, r);
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
            
            fixed fbm(fixed2 pixel)
            {
                #define NUM_OF_OCTAVES 5
                fixed v = 0.0;
                fixed a = 0.5;
                fixed2 shift = fixed2(100, 100);
                fixed2x2 rotation = fixed2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));

                for (int i = 0; i < NUM_OF_OCTAVES; ++i)
                {
                    v += a * perlinNoise(pixel);
                    pixel = mul(rotation, pixel) * 2.0 + shift;
                    a *= 0.5;
                }

                return v;
            }

            fixed pattern(fixed2 pixel)
            {
                fixed2 q = fixed2(fbm(pixel + fixed2(0, 0)), fbm(pixel + fixed2(_AnotherX, _AnotherY + _Time.y)));
                return fbm(pixel + _Progress * q);
            }

            fixed2 radialUv(fixed2 center)
            {
                const fixed PI = UNITY_PI;
                fixed x = atan2(center.x, center.y) / PI + .5;
                fixed y = length(center);
                return fixed2(x, y);
            }

            fixed2 flowUV (fixed2 uv, fixed2 flowVector, fixed time) {
                fixed progress = frac(time);
	            return uv + flowVector * progress;
            }

            fixed3 flowUVW (fixed2 uv, fixed2 flowVector, fixed time, bool flowB)
            {
                fixed phaseOffset = flowB ? 0.5 : 0;
                fixed progress = frac(time + phaseOffset);
                fixed3 uvw;
                uvw.xy = uv + flowVector * progress + phaseOffset;
                uvw.z = 1 - abs(1 - 2 * progress);
                return uvw;
            }

            fixed fbmPattern(fixed2 pixel, fixed time)
            {
                fixed2 r = 0;
                r.x = fbm( pixel + fixed2(1.7,9.2) + 0.15 * time);
                r.y = fbm( pixel + fixed2(8.3,2.8) + 0.126 * time);
                return fbm(pixel + _Progress * r);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 center = centeredUV(i.uv);
                fixed2 uv = center;
                fixed time = _Time.y;

                fixed f = fbmPattern(uv, time);

                
                return smoothstep(0.2, 1, f);                
            }
            ENDCG
        }
    }
}
