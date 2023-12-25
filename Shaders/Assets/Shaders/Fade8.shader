Shader "Practice/Fade8"
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
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
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
            
            fixed borderTest(fixed2 uv)
            {
                uv = fixed2(atan2(uv.y, uv.x), length(uv));
                uv.x += _Time * 10;
                fixed ring = length(uv.y - _Progress);
                
                fixed influenceDistance = smoothstep(lerp(0, 0.2, 1), 0.7, uv.y);
                fixed noise = tex2D(_NoiseTex, uv * 2);

                fixed step1 = abs(sin(uv.x * 2 + noise.x * 3));
                fixed step12 = abs(cos(uv.x * 2 + noise.x * 3));
                step1 *= step12;
                
                fixed step2 = ring + step1;
                fixed border2 = cos(4 * influenceDistance) * -0.88;
                fixed border1 = smoothstep(0.25, 0, step2);
                return border1;
            }

            fixed transition_with_noise(fixed2 uv, fixed4 noise, fixed progress)
            {
                fixed radius = length(uv);
                //radius = smoothstep(0, 1, smoothstep(0, length(uv), progress));
                fixed pattern = smoothstep(0, 1, 1 - radius + noise);
                pattern = pattern - ( 1 - progress);
                return pattern;
            }

            fixed2 polar(fixed2 cartesian)
			{
				fixed distance = length(cartesian);
				fixed angle = atan2(cartesian.y, cartesian.x);
				return fixed2(angle / UNITY_TWO_PI + .5, distance * .2);
			}

            fixed movingNoise(fixed2 uv)
            {
                fixed2 noise0Movement;
                fixed noiseMovementTime = _Time.y / 20;
                noise0Movement.x =sin(noiseMovementTime) + cos(noiseMovementTime * 2.1);
                noise0Movement.y = cos(noiseMovementTime) + sin(noiseMovementTime * 1.6);
                fixed noise0 = tex2D(_NoiseTex, uv / 4 + noise0Movement / 10);
                noise0 *= noise0;
                return noise0;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = screenUV(i.uv);
                fixed2 polarUv = polar(uv);
                fixed2 timeOffset = fixed2(_Time.y / 100, _Time.y / 30);

                fixed noise0 = movingNoise(uv) * 0;
                
                fixed maskTransition = (sin(_Time.y / 2) / 2 + 0.5) / 5;
                fixed mask = smoothstep(0.0 + maskTransition, 0.12 + maskTransition, noise0);
                
                fixed noise = tex2D(_NoiseTex, polarUv - timeOffset / 3);
                noise *= noise;
                
                fixed tran = transition_with_noise(uv, noise, _Progress);
                
                fixed f1 = smoothstep(0.1, 0.2, tran);
                
                fixed f2 = smoothstep(0.3, 0.5, tran);
                fixed f3 = smoothstep(0.6, 0.8, tran);


                fixed4 tex = tex2D(_MainTex, i.uv);
                
                fixed m = 0.5 * f1 + 0.25 * f2 + 0.125 * f3 - 0.6 * (f1 * mask);
                return m * tex;
            }
            ENDCG
        }
    }
}