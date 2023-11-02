Shader "Practice/Lines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", color) = (1, 1, 1, 1)
        _Amplitude ("Amplitude", float) = 1
        _Frequency ("Frequency", float) = 1
        
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

            fixed _Amplitude;
            fixed _Frequency;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed rectangle(fixed2 uv)
            {
                fixed left = uv.x;
                fixed right = 1 - uv.x;
                fixed down = uv.y;
                fixed up = 1 - uv.y;
                return left * right * down * up;
            }

            fixed square(fixed2 uv, fixed size)
            {
                return uv.x > size || uv.y > size || uv.x < (1 - size) || uv.y < (1 - size);
            }

            fixed drawLine2(fixed x, fixed y, fixed width)
            {
                fixed top = x - y + width;
                fixed up = abs(smoothstep(0.1, 0.2, top + width));
                fixed down = abs(smoothstep(0.1, 0.2, top));
                return up - down;
            }

            fixed aspect(fixed2 uv)
            {
                uv.x -= 0.5;
                fixed dx = ddx(uv.x);
                fixed dy = ddy(uv.y);
                return dy / dx;
            }

            fixed drawLine(fixed x, fixed y, fixed width)
            {
                return smoothstep(width, 0.0, abs(y - x));
            }

            fixed randomSinFunction(fixed x, fixed time, fixed offset, fixed amplitude, fixed frequency)
            {
                fixed y = sin(x * frequency + offset);
                fixed t = 0.01 * (time * 130);
                y += sin(x*frequency*2.1 + t + offset)*4.5;
                y += sin(x*frequency*1.72 + t*1.121 + offset)*4.0;
                y += sin(x*frequency*2.221 + t*0.437 + offset)*5.0;
                y += sin(x*frequency*3.1122+ t*4.269 + offset)*2.5;
                y *= amplitude*0.06;
                return y;
            }

            float random(fixed2 pos)
            {
                return frac(sin(dot(pos.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }

            fixed perlinNoise(fixed2 uv)
            {
                fixed2 numbers = floor(uv);
                fixed2 fractions = frac(uv);

                fixed a = random(numbers);
                fixed b = random(numbers + fixed2(1, 0));
                fixed c = random(numbers + fixed2(0, 1));
                fixed d = random(numbers + fixed2(1, 1));

                fixed2 u = fractions * fractions * (3.0 - 2.0 * fractions);
                return lerp (a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv;
                uv.x *= aspect(uv);

                float y = 0.4 * frac(sin(uv.x + _Time.y) * 1.0) + 0.5;
                return random(uv * _Time.y);            
            }
            ENDCG
        }
    }
}
