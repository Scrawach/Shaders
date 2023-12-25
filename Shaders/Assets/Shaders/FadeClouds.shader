Shader "Practice/FadeClouds"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed2 hash(fixed2 p)
            {
                p = fixed2(dot(p, fixed2(127.1, 311.7)), dot(p, fixed2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }

            fixed noise(fixed2 p)
            {
                const float K1 = 0.366025404; // (sqrt(3)-1)/2;
                const float K2 = 0.211324865; // (3-sqrt(3))/6;
	            fixed2 i = floor(p + (p.x+p.y)*K1);	
                fixed2 a = p - i + (i.x+i.y)*K2;
                fixed2 o = (a.x>a.y) ? fixed2(1.0,0.0) : fixed2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
                fixed2 b = a - o + K2;
	            fixed2 c = a - 1.0 + 2.0*K2;
                fixed3 h = max(0.5-fixed3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	            fixed3 n = h*h*h*h*fixed3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
                return dot(n, 70.0);	
            }

            fixed fbm(fixed2 n)
            {
                const fixed2x2 m = fixed2x2( 1.6,  1.2, -1.2,  1.6 );
                fixed total = 0.0;
                fixed amplitude = 0.1;
                for (int i = 0; i < 8; i++)
                {
                    total += noise(n) * amplitude;
                    n = mul(m, n);
                    amplitude *= 0.4;
                }
                return total;
            }

            fixed2 polar(fixed2 cartesian)
			{
				fixed distance = length(cartesian);
				fixed angle = atan2(cartesian.y, cartesian.x);
				return fixed2(angle / UNITY_TWO_PI + .5, distance * .2);
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

            fixed clouds(fixed2 uv, fixed size, fixed time)
            {
                const fixed2x2 m = fixed2x2( 1.6,  1.2, -1.2,  1.6 );
                fixed q = fbm(uv * size * 0.5);
                fixed2 origin = uv;
                
                fixed r = 0.0;
                uv *= size;
                uv -= q - time;
                fixed weight = 0.8;
                for (int i = 0; i < 8; i++)
                {
                    r += abs(weight * noise(uv));
                    uv = mul(m, uv) + time;
                    weight *= 0.7;
                }

                // noise shape
                fixed f = 0.0;
                fixed2 t = origin;
                t *= size;
                t -= q - time;
                weight = 0.7;
                for (int i=0; i<8; i++){
		            f += weight*noise( t );
                    t = mul(m, t) + time;
		            weight *= 0.6;
                }
                    
                f *= r + f;
                return f;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 center = screenUV(i.uv);
                fixed f1 = clouds(center, 0.5, _Time.y * 0.03);
                fixed f2 = clouds(center + _Time.y * 0.01, 0.2, _Time.y * 0.01);
                fixed f3 = clouds(center + _Time.y * 0.1, 1, _Time.y * 0.001);
                f1 = smoothstep(0,0.2,f1);
                f2 = smoothstep(0, 0.2,f2);
                f3 = smoothstep(0, 0.2, f3);

                fixed result = 0.5 * f2 + 0.25 * f1 + 0.01 * f3;
                return result * 0.3;
            }
            ENDCG
        }
    }
}