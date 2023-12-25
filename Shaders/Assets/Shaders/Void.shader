Shader "Practice/Void"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("Progress", range(0, 10)) = 0.0
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Progress;

            #define PI 3.14159265359
            #define TWO_PI 6.28318530718
            #define HALF_PI 1.57079632679

            // FBM implementation from
            // https://github.com/MaxBittker/glsl-fractal-brownian-noise
            fixed3 mod289(fixed3 x) {
              return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            fixed4 mod289(fixed4 x) {
              return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            fixed4 permute(fixed4 x) {
                 return mod289(((x*34.0)+1.0)*x);
            }

            fixed4 taylorInvSqrt(fixed4 r)
            {
              return 1.79284291400159 - 0.85373472095314 * r;
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
            
            float snoise(fixed3 v)
              {
              const fixed2  C = fixed2(1.0/6.0, 1.0/3.0) ;
              const fixed4  D = fixed4(0.0, 0.5, 1.0, 2.0);

            // First corner
              fixed3 i  = floor(v + dot(v, C.yyy) );
              fixed3 x0 =   v - i + dot(i, C.xxx) ;

            // Other corners
              fixed3 g = step(x0.yzx, x0.xyz);
              fixed3 l = 1.0 - g;
              fixed3 i1 = min( g.xyz, l.zxy );
              fixed3 i2 = max( g.xyz, l.zxy );

              //   x0 = x0 - 0.0 + 0.0 * C.xxx;
              //   x1 = x0 - i1  + 1.0 * C.xxx;
              //   x2 = x0 - i2  + 2.0 * C.xxx;
              //   x3 = x0 - 1.0 + 3.0 * C.xxx;
              fixed3 x1 = x0 - i1 + C.xxx;
              fixed3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
              fixed3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

            // Permutations
              i = mod289(i);
              fixed4 p = permute( permute( permute(
                         i.z + fixed4(0.0, i1.z, i2.z, 1.0 ))
                       + i.y + fixed4(0.0, i1.y, i2.y, 1.0 ))
                       + i.x + fixed4(0.0, i1.x, i2.x, 1.0 ));

            // Gradients: 7x7 points over a square, mapped onto an octahedron.
            // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
              float n_ = 0.142857142857; // 1.0/7.0
              fixed3  ns = n_ * D.wyz - D.xzx;

              fixed4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

              fixed4 x_ = floor(j * ns.z);
              fixed4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

              fixed4 x = x_ *ns.x + ns.yyyy;
              fixed4 y = y_ *ns.x + ns.yyyy;
              fixed4 h = 1.0 - abs(x) - abs(y);

              fixed4 b0 = fixed4( x.xy, y.xy );
              fixed4 b1 = fixed4( x.zw, y.zw );

              //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
              //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
              fixed4 s0 = floor(b0)*2.0 + 1.0;
              fixed4 s1 = floor(b1)*2.0 + 1.0;
              fixed4 sh = -step(h, fixed4(0, 0, 0, 0));

              fixed4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
              fixed4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

              fixed3 p0 = fixed3(a0.xy,h.x);
              fixed3 p1 = fixed3(a0.zw,h.y);
              fixed3 p2 = fixed3(a1.xy,h.z);
              fixed3 p3 = fixed3(a1.zw,h.w);

            //Normalise gradients
              fixed4 norm = taylorInvSqrt(fixed4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
              p0 *= norm.x;
              p1 *= norm.y;
              p2 *= norm.z;
              p3 *= norm.w;

            // Mix final noise value
              fixed4 m = max(0.6 - fixed4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
              m = m * m;
              return 42.0 * dot( m*m, fixed4( dot(p0,x0), dot(p1,x1),
                                            dot(p2,x2), dot(p3,x3) ) );
              }



            float fbm3d(fixed3 x, const in int it) {
                float v = 0.0;
                float a = 0.5;
                fixed3 shift = fixed3(0, 0, 0);

                
                for (int i = 0; i < 32; ++i) {
                    if(i<it) {
                        v += a * snoise(x);
                        x = x * 2.0 + shift;
                        a *= 0.5;
                    }
                }
                return v;
            }

            fixed pattern(fixed2 st, fixed t)
            {                
                float x = fbm3d(
                    fixed3(
                        sin( st.y ),
                        cos( st.y ),
                        pow( st.x, .3 ) + t * .1
                    ),
                    3
                );
	            float y = fbm3d(
                    fixed3(
                        cos( 1. - st.y ),
                        sin( 1. - st.y ),
                        pow( st.x, .5 ) + t * .1
                    ),
                    4
                );
                
                float z = fbm3d(
                    fixed3(
                        x,
                        y,
                        st.x + t * .3
                    ),
                    5
                );
                float r = fbm3d(
                    fixed3(
                        z - x,
                        z - y,
                        z + t * .3
                    ),
                    6
                );

                //return x + st.x * 3;
                return ( r + st.x * 5. ) / 6.;
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
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = centeredUV(i.uv);
                //fixed2 st = uv;
                fixed2 st = fixed2(length(uv) * _Progress, atan2(uv.y, uv.x));
                st.y += st.x * 1.1;
                fixed p = pattern(st, _Time.y / 5);

                fixed mask = 1 - p;
                mask = smoothstep(0, 0.3, mask);
                fixed4 color = fixed4(
                    smoothstep(0.1, 0.5, mask),
                    smoothstep(0.5, 1.0, mask),
                    smoothstep(0.4, 1.0, mask),
                    1);
                return color.r - color.b;
            }
            ENDCG
        }
    }
}