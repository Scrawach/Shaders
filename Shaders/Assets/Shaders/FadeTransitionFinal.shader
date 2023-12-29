Shader "Practice/FadeTransitionFinal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _NoiseTex ("Noise Texture", 2D) = "white" {}
        _NoiseStrength ("Noise Strength", float) = 0.5
        _OffsetX ("Offset X", float) = 0.0
        _OffsetY ("Offset Y", float) = 0.0
        _TimeScale ("Time Scale", float) = 1.0
        _Progress ("Progress", range(0, 1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed2 uv : TEXCOORD0;
                fixed4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            fixed4 _MainTex_ST;

            sampler2D _NoiseTex;
            fixed _NoiseStrength;
            fixed _TimeScale;
            fixed _Progress;

            fixed _OffsetX;
            fixed _OffsetY;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed2 centerOfScreen(fixed2 uv)
            {
                fixed2 center = uv * 2 - 1.0;
                fixed dx = ddx(center.x);
                fixed dy = ddy(center.y);
                fixed aspect = dy / dx;
                center.x *= aspect;
                return center;
            }

            fixed2 polar(fixed2 cartesian)
            {
                fixed distance = length(cartesian);
                fixed angle = atan2(cartesian.y, cartesian.x);
                return fixed2(angle / UNITY_TWO_PI + .5, distance * .2);
            }

            fixed pattern(fixed2 center, fixed noise, fixed progress)
            {
                center.x *= 0.85;
                fixed radius = length(center / progress);
                fixed pattern = 1 - radius + noise * _NoiseStrength;
                return smoothstep(0, 1, pattern);
            }

            fixed gradientFrom(fixed pattern)
            {
                fixed f1 = smoothstep(0, 0.1, pattern);
                fixed f2 = smoothstep(0.3, 0.4, pattern);
                fixed f3 = smoothstep(0.7, 0.8, pattern);
                fixed f = 0.5 * f1 + 0.25 * f2 + 0.25 * f3;
                return f;
            }

            fixed lighten(fixed a, fixed b)
            {
                return max(a, b);
            }

            fixed blackMask(fixed2 center, fixed noise, fixed time, fixed progress)
            {
                fixed offset = time / 8;
                fixed x = sin(offset) + cos(2.1 * offset);
                fixed y = cos(offset) + sin(1.6 * offset);
                fixed noisePattern1 = pattern(center - fixed2(x, y), noise, progress);
                noisePattern1 = smoothstep(0, 0.25, noisePattern1);

                offset = time / 10;
                x = sin(4 * offset) - cos(2.1 * offset);
                y = cos(1.234 * offset) - sin(offset / 6);
                fixed noisePattern2 = pattern(center - fixed2(x, y), noise, progress);
                noisePattern2 = smoothstep(0, 0.25, noisePattern2);
                return lighten(noisePattern1, noisePattern2);
            }

            fixed whiteMask(fixed2 center, fixed noise, fixed time, fixed progress)
            {
                fixed offset = time / 20;
                fixed x = sin(2 * offset) + cos(offset) - sin(3 * offset);
                fixed y = sin(3 * offset + 2) + cos(4 * offset);
                fixed noisePattern1 = pattern(center - fixed2(x, y) / 1.5, noise, smoothstep(0.2, 1.0, progress));

                offset = time / 8;
                x = sin(2 * offset) + cos(offset) - sin(3 * offset);
                y = sin(3 * offset + 2) + cos(4 * offset);
                fixed noisePattern2 = pattern(center - fixed2(x, y) / 1.5, noise, smoothstep(0.4, 1.0, progress));
                return lighten(noisePattern1, noisePattern2);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 offset = fixed2(_OffsetX, _OffsetY) + fixed2(sin(_Time.y / 10), cos(_Time.y / 10)) / 2;
                fixed2 uv = centerOfScreen(i.uv) + offset;
                fixed2 polarUV = polar(uv);
                fixed time = _Time.y * _TimeScale;

                fixed2 noiseTimeOffset = fixed2(time / 100, time / 20);
                fixed noise = tex2D(_NoiseTex, uv / 5 - noiseTimeOffset / 10);
                fixed polarNoise = tex2D(_NoiseTex, polarUV * 4 - noiseTimeOffset);

                fixed mask = pattern(uv, polarNoise, _Progress);
                mask = lighten(mask, whiteMask(uv, polarNoise, time, _Progress));
                mask = gradientFrom(mask) - blackMask(uv, noise, time, _Progress) / 1.5;

                fixed4 tex = tex2D(_MainTex, i.uv);
                return mask * tex;
            }
            ENDCG
        }
    }
}