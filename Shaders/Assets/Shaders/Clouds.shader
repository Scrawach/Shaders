Shader "Practice/Clouds"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("Progress", range(0, 1)) = 0
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
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Progress;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
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

            fixed4 blend(fixed4 a, fixed4 b)
            {
                return 1 - (1 - a) * (1 - b);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                
                fixed2 uv = i.uv * 8;
                fixed time = _Time.y;
                
                fixed2 q = 0;
                q.x = fbm(uv + 0);
                q.y =  fbm(uv + 1);

                fixed2 r = 0;
                r.x = fbm( uv + 1.0*q + fixed2(1.7,9.2)+ 0.15* time );
                r.y = fbm( uv + 1.0*q + fixed2(8.3,2.8)+ 0.126* time);

                fixed f = fbm(uv + r);

                fixed t1 = clamp((f*f)*4.0,0.0,1.0);
                fixed t2 = clamp(length(q), 0.0, 1.0);
                fixed t3 = clamp(length(r.x), 0.0, 1.0);
                
                fixed4 color = lerp(fixed4(0.101961,0.619608,0.666667, 1.0), fixed4(0.666667,0.666667,0.498039, 1.0), t1);
               
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed noise = smoothstep(0.2, 1, f);
                fixed f2 = fbm(uv + r * 3 + fixed2(time / 2, 0));


                fixed2 center = i.uv * 2 - 1;
                fixed progress = smoothstep(0, 1, _Progress);
                fixed radius = length(center / progress);
                fixed circle = smoothstep(1, 0, radius);


                fixed test = fbm(uv + r + fixed2(time / 10, 0));
                fixed smothTest = clamp(smoothstep(0, 1.0, test), 0, 1);
                fixed4 color1 = lerp(0, col, pow(smothTest, 1.2));
                return color1;

                color = lerp(color, fixed4(0, 0, 0.164706, 1), t2);
                color = lerp(color, fixed4(0.66667, 1, 1, 1), t3);
                return (f * f * f + .6 * f * f + .5 *f) *f;
            }
            ENDCG
        }
    }
}