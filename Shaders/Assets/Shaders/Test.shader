Shader "Practice/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        [NoScaleOffset] _FlowMap ("Flow map", 2D) = "white" {}
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Progress;

            sampler2D _FlowMap;
            sampler2D _NoiseTex;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed aspect(fixed2 uv)
            {
                fixed dx = ddx(uv.x);
                fixed dy = ddy(uv.y);
                return dy / dx;
            }

   #define ITERATIONS 4
            
            fixed distortion(fixed2 uv, fixed time, fixed foaminess)
            {
                fixed2 i = fixed2(uv.x, uv.y);
                fixed color = 0.0;
                fixed foaminess_factor = lerp(0.0, 6.0, foaminess);
                fixed inten = 0.005 * foaminess_factor;

                for (int n = 0; n < ITERATIONS; n++)
                {
                    fixed t = time * (1.0 - (3.5 / float(n + 1)));
                    i = uv + fixed2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
                    color += 1.0 / length(fixed2(uv.x / sin(i.x + t), uv.y / cos(i.y + t)));
                }

                color = 0.2 + color / (inten * float(ITERATIONS));
                color = 1.17 - pow(color, 1.4);
                color = pow(abs(color), 8.0);
                return color / sqrt(foaminess_factor);
            }

            fixed mask(fixed2 uv, fixed time, fixed progress)
            {
                progress = max(0, progress);
                fixed center = pow(length(uv / progress), 2.0);
                fixed foaminess = smoothstep(-3, 1.8, center);
                fixed clearness = 0.1 + 0.9 * smoothstep(0.1, 0.5, center);
                fixed mask = 1 - distortion(uv * 7 - 250, time, foaminess) * center;
                return mask + clearness;
            }

            fixed blob(fixed2 image, fixed2 uv, fixed time, fixed progress)
            {
                fixed bigMask = mask(uv, time, progress);
                fixed smallMask = mask(uv, time, progress - 0.05);
                fixed4 color = tex2D(_MainTex, (image + fixed2((sin(time) - 1) / 20, 0)));
                return saturate(lerp(bigMask * 0.1, color * 2, max(0, smallMask)));
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv * 2 - 1;
                //uv.x *= aspect(uv);
                fixed time = _Time.y * 0.2;
                
                fixed blob1 = blob(i.uv, uv, time, _Progress);

                return blob1;
            }
            ENDCG
        }
    }
}