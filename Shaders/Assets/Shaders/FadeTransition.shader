Shader "Practice/FadeTransition"
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
            fixed4 _MainTex_ST;

            sampler2D _NoiseTex;
            fixed _Progress;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed2 centerOfScreen(fixed2 uv)
            {
                fixed2 temp = uv * 2 - 1.0;
                fixed dx = ddx(temp.x);
                fixed dy = ddy(temp.y);
                fixed aspect = dy / dx;
                temp.x *= aspect;
                return temp;
            }

            fixed2 polar(fixed2 cartesian)
			{
				fixed distance = length(cartesian);
				fixed angle = atan2(cartesian.y, cartesian.x);
				return fixed2(angle / UNITY_TWO_PI + .5, distance * .2);
			}

            fixed noisePattern(fixed2 center, fixed noise0, fixed noise1, fixed progress)
            {
                const fixed NOISE_1_STRENGTH = 0.5;
                
                center.x *= 0.85;
                fixed radius = length(center / progress);
                fixed currentNoise = lerp(noise0, noise1 * NOISE_1_STRENGTH, progress);
                fixed pattern = 1 - radius + currentNoise;
                fixed smoothed = smoothstep(0, 1, pattern);
                
                return smoothed;
            }

            fixed gradientFrom(fixed pattern)
            {
                fixed f1 = smoothstep(0, 0.1, pattern);
                fixed f2 = smoothstep(0.3, 0.4, pattern);
                fixed f3 = smoothstep(0.7, 0.8, pattern);
                fixed f = 0.5 * f1 + 0.25 * f2 + 0.25 * f3;
                return f;
            }

            fixed blend(fixed a, fixed b)
            {
                return 1 - (1 - a) * (1 - b);
            }

            fixed lighten(fixed a, fixed b)
            {
                return max(a, b);
            }

            fixed darken(fixed a, fixed b)
            {
                return min(a, b);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 center = centerOfScreen(i.uv);
                
                fixed2 polarUv = polar(center);
                fixed2 timeOffset = fixed2(_Time.y / 100, _Time.y / 20);
                fixed noise0 = tex2D(_NoiseTex, center / 4 - timeOffset);
                fixed noise1 = tex2D(_NoiseTex, polarUv * 4 - timeOffset);
                fixed pattern = noisePattern(center, noise0, noise1, _Progress);

                fixed noise2 = tex2D(_NoiseTex, center / 5 + timeOffset / 10);

                fixed noiseMovementTime = _Time.y / 8;
                fixed x =sin(noiseMovementTime) + cos(noiseMovementTime * 2.1);
                fixed y = cos(noiseMovementTime) + sin(noiseMovementTime * 1.6);
                fixed n = noisePattern(center - fixed2(x, y), noise2, noise2, _Progress/ 1.2);
                n = smoothstep(0, 0.1, n);

                noiseMovementTime = _Time.y / 10;
                x = sin(noiseMovementTime * 4) - cos(noiseMovementTime * 2.1);
                y = cos(noiseMovementTime * 1.234) - sin(noiseMovementTime / 6);
                fixed m = noisePattern(center - fixed2(x, y), noise2, noise2, _Progress / 1.1);
                m = smoothstep(0, 0.1, m);

                noiseMovementTime = _Time.y / 20;
                x = sin(2 * noiseMovementTime) + cos(noiseMovementTime) - sin(3 * noiseMovementTime);
                y = sin(3 * noiseMovementTime + 2) + cos(4*noiseMovementTime);
                fixed c = noisePattern(center - fixed2(x, y) / 1.5, noise2, noise2, _Progress / 1.1);


                noiseMovementTime = _Time.y / 8;
                x = sin(2 * noiseMovementTime) + cos(noiseMovementTime) - sin(3 * noiseMovementTime);
                y = sin(3 * noiseMovementTime + 2) + cos(4*noiseMovementTime);
                fixed c2 = noisePattern(center - fixed2(x, y) / 2.5, noise2, noise2, _Progress / 1.1);

                c2 = lighten(c, c2);
                
                fixed blackMask = lighten(m / 1.5, n / 1.5);
                fixed whiteMask = lighten(c2, pattern);
                fixed f = gradientFrom(whiteMask) - blackMask;
                

                fixed4 tex = tex2D(_MainTex, i.uv);
                return tex * f;
            }
            ENDCG
        }
    }
}