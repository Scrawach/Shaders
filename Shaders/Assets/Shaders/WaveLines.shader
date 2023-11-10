Shader "Practice/WaveLines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Foreground ("Texture", 2D) = "white" {}
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
            sampler2D _Foreground;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
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

            fixed4 blend(fixed4 a, fixed4 b)
            {
                return 1 - (1 - a) * (1 - b);
            }

            fixed waveLines(fixed2 uv, fixed time)
            {
                fixed wave1 = wave(_Time.y / 4, 0.02, uv, 10 + sin(_Time.y / 5) * 1.5);
                fixed wave2 = wave(_Time.y / 10, 0.08, uv, 5);
                fixed wave3 = wave(-_Time.y / 17, 0.15, uv, 2.5) * 0.2;
                return maxFrom(wave1, wave2, wave3);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv;
                                
                fixed4 foreground = tex2D(_Foreground, i.uv);
                fixed lines = waveLines(uv, _Time.y);
                return blend(lines, foreground);
            }
            ENDCG
        }
    }
}
