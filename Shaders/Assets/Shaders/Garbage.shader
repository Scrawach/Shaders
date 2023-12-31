Shader "Practice/Garbage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _Foreground ("Foreground", 2D) = "white" {}
        _Progress ("Progress", range(0, 1)) = 0.0
        _TimeScale ("Time Scale", float) = 0.0
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
                UNITY_FOG_COORDS(1)
                float4 position : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _Foreground;
            
            float _Progress;
            fixed _TimeScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
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

            fixed2 screenUV(fixed2 uv)
            {
                fixed2 temp = uv * 2 - 1.0;
                fixed dx = ddx(temp.x);
                fixed dy = ddy(temp.y);
                fixed aspect = dy / dx;
                temp.x *= aspect;
                return temp;
            }

            fixed4 transition_with_noise(fixed2 uv, fixed4 noise, fixed progress)
            {
                fixed add = sin(uv.x * 50) + sin(uv.y * 50);
                add *= 0.01;
                fixed radius = length(uv);
                fixed sum = (radius + noise + add);
                fixed result = sum < progress;
                return fixed4(result, result, result, 1.0);
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

            fixed4 frag2(v2f input) //: SV_Target
            {
                fixed time = _Time.y * _TimeScale;
                fixed2 uv = screenUV(input.uv);
                fixed radius = length(uv);
                fixed circle = 0.1 / radius;
                fixed result = smoothstep(0.2, 1, circle);


                fixed4 noiseTexture = tex2D(_NoiseTex, uv / 10 + time);
                noiseTexture = smoothstep(0.3, 0.9, noiseTexture);


                fixed window = _Progress > radius;
                fixed edge = _Progress + 0.1 > radius;
                fixed resultCircle = edge - window;
                return resultCircle * noiseTexture + window;
                return result * noiseTexture;
            }

            float filmGrainNoise(in float time, in fixed2 uv)
            {
                return frac(sin(dot(uv, fixed2(12.9898, 78.233) * time)) * 43758.5453);
            }


            fixed4 transition_with_noise2(fixed2 uv, fixed noise, fixed progress)
            {
                fixed radius = length(uv);
                fixed sum = (radius + noise);
                fixed result = sum - progress;
                return result;
                return smoothstep(0.2, 0.5, result);
                return smoothstep(0, 0.5, result);
                return fixed4(result, result, result, 1.0);
            }

            fixed4 overlayBlending(fixed4 a, fixed4 b)
            {
                if (a.x < 0.5)
                    return 2 * a * b;
                return 1 - 2 * (1 - a) * (1 - b);
            }

            float sine(fixed2 p, float o)
            {
                #define A .1 // Amplitude
                #define V 8. // Velocity
                #define W 3. // Wavelength
                #define T .005 // Thickness
                #define S 3. // Sharpness
                return pow(T / abs((p.y + sin((p.x * W + o)) * A)), S);
            }

            float wave(float time, fixed amplitude, fixed2 uv, float phase) {
                float wave = sin(time + uv.x * phase);
                float blur = amplitude * smoothstep(.5, 0., abs(uv.x - 0.5));
                uv.y += phase * blur * wave;
                blur = smoothstep(-0.01, 0.2, blur);
                fixed result = sine(uv * 2 - fixed2(0.5, 1.0), 0);
                return clamp(result, 0, 1) * blur;
            }

            fixed maxFrom(fixed a, fixed b, fixed c)
            {
                fixed temp = max(a, b);
                return max(temp, c);
            }


            fixed waveLines(fixed2 uv, fixed time)
            {
                fixed wave1 = wave(_Time.y / 4, 0.02, uv, 10 + sin(_Time.y / 5) * 1.5);
                fixed wave2 = wave(_Time.y / 10, 0.08, uv, 5);
                fixed wave3 = wave(-_Time.y / 17, 0.15, uv, 2.5) * 0.2;
                return maxFrom(wave1, wave2, wave3);
            }

            
            fixed4 frag (v2f input) : SV_Target
            {
                fixed time = _Time.y * _TimeScale;
                fixed2 uv = screenUV(input.uv);

                fixed progress = (_Progress - 0.7) * 3 + 0.5;

                fixed2 r = 0;
                r.x = fbm( uv + 1.0 + fixed2(1.7,9.2)+ 0.15 * time);
                r.y = fbm( uv + 1.0 + fixed2(8.3,2.8)+ 0.126 * time);

                fixed f = fbm((uv + fixed2(sin(time / 10), 0)) + r * 2);
                
                
                fixed4 tex = tex2D(_MainTex, input.uv + fixed2(sin(_Time.y / 10) / 20, 0));
                fixed final = transition_with_noise2(uv, f, progress);
                fixed finalOuter = (1 - clamp(final, 0, 1));
                fixed4 fore = tex2D(_Foreground, input.uv);

                fixed f2 = fbm((uv / 10 + fixed2(sin(time / 10) / 2, 0)) * 6 + r * 2);
                fixed mask1 = smoothstep(0.2, 0.6, f) * 1.2;
                
                fixed4 screen = finalOuter *smoothstep(0.35, 0.6, f) * tex;

                
                fixed mask2 = smoothstep(0.2, 0.9, f2) * mask1 * finalOuter;

                fixed mask1final = smoothstep(0.1, 0.5, mask1);
                fixed mask1final2 = smoothstep(0.5, 0.9, mask1);
                fixed border = (1 - mask1final2) - (1 - mask1final);
                fixed maskResult = 1 - saturate((1 - mask1final) + border * 0.6);

                mask2 = maskResult + 0.3;
                fixed finalOuter1 = smoothstep(0.1, 0.8, finalOuter);

                fixed finalBorders = finalOuter1 - finalOuter;

                
                finalOuter = finalBorders * 0.6 + finalOuter;

                fixed maskOut =  min(mask2 * mask2, finalOuter);
                fixed lines = waveLines(input.uv, _Time.y);
                fixed maskedLines = lines * (1 - finalOuter);
                maskedLines = lerp(maskedLines, 0, _Progress + 0.3);

                fixed result = max(maskOut * tex, maskedLines);
                //return mask2 * finalOuter;
                return blend(result, fore / 2);
                return pow(blend(fore / 2, screen), 0.8);
                return finalOuter * smoothstep(0.1, 0.8, f) * tex;
            } 
            ENDCG
        }
    }
}
