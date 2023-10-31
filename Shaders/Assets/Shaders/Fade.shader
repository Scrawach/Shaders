Shader "Practice/Fade"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _Progress ("Progress", float) = 0.0
        _TimeScale ("Time Scale", float) = 0.0
        [NoScaleOffset] _FlowMap ("Flow (RG, A noise)", 2D) = "black" {}
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

            sampler2D _FlowMap;
            
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

            fixed2 screenUV(fixed2 uv)
            {
                fixed2 temp = uv * 2 - 1.0;
                fixed dx = ddx(temp.x);
                fixed dy = ddy(temp.y);
                fixed aspect = dy / dx;
                temp.x *= aspect;
                return temp;
            }

            fixed4 transition(fixed2 uv, fixed progress)
            {
                fixed add = sin(uv.x * 50) + sin(uv.y * 50);
                add *= 0.012;
                fixed result = length(uv) + add < progress;
                return fixed4(result, result, result, 1.0);
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
            
            fixed4 frag (v2f input) : SV_Target
            {
                fixed time = _Time.y * _TimeScale;
                fixed2 uv = screenUV(input.uv);
                float2 flowVector = tex2D(_FlowMap, uv).rg * 2;
                fixed flowNoise = tex2D(_FlowMap, uv).a;
                //fixed2 flow = flowUV(uv / 5, flowVector, time);
                //fixed4 noise = tex2D(_NoiseTex, flow);
                
                fixed3 uvwA = flowUVW(uv, flowVector, time + flowNoise, false);
                fixed3 uvwB = flowUVW(uv, flowVector, time + flowNoise, true);
                
                
                
                fixed4 noise_uwvA = tex2D(_NoiseTex, uvwA.xy / 50 ) * uvwA.z;
                fixed4 noise_uwvB = tex2D(_NoiseTex, uvwB.xy / 50 ) * uvwB.z;
                fixed4 noise = (noise_uwvA + noise_uwvB);
                //return noise;

                fixed result = transition_with_noise(uv,  noise, _Progress);
                fixed result1 = transition_with_noise(uv + fixed2(0.5, -0.7),  noise, _Progress - 0.15);
                fixed result2 = transition_with_noise(uv + fixed2(0.2, -0.5),  noise, _Progress - 0.25);
                fixed result3 = transition_with_noise(uv + fixed2(-0.6, 0.5),  noise, _Progress - 0.35);
                fixed result4 = transition_with_noise(uv,  noise, _Progress / 2);
                
                fixed2 tex = tex2D(_MainTex, input.uv + fixed2(sin(_Time.y / 10) / 20, 0));


                fixed alpha = 1 - smoothstep(0, _Progress, length(uv));


                fixed first = result - result1 - result2 - result3;
                fixed second = max(0, result1 - result2 - result3);
                fixed third = max(0, result2 - result3);
                fixed sum = result + result1 + result2 + result3;


                float grainFactor = filmGrainNoise(_Time.y, uv);
                fixed3 pixelColor = lerp(tex.r, fixed3(0, 0, 0), grainFactor * 0.4);
                return (sum * 0.25 - result4 * 0.3) * fixed4(pixelColor, 1);
                
                fixed res = (result2 + result + result1 + result3) * 0.3f * tex.x;
                
           
                return res;
            } 
            ENDCG
        }
    }
}
