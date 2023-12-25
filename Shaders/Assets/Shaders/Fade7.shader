Shader "Practice/Fade7"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Color", color) = (0, 0, 0, 0)
        _Color2 ("Color 2", color) = (1, 1, 1, 1)
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
            #include "Fbm.cginc"

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

            fixed4 _Color1;
            fixed4 _Color2;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                const fixed OCTAVES = 5;
                fixed2 uv = i.uv * 5;

                fixed2 q = 0;
                q.x = fbm(uv, 5);
                q.y = fbm(uv + 1.0, 5);

                fixed2 r = 0;
                r.x = fbm(uv + 1.0 * q + fixed2(1.7, 9.2) + 0.15 * _Time.y, 5);
                r.y = fbm(uv + 1.0 * q + fixed2(8.3, 2.8) + 0.126 * _Time.y, 5);

                fixed f = fbm(uv + r, 5);

                fixed3 color = lerp(fixed3(0.101961,0.619608,0.666667),
                            fixed3(0.666667,0.666667,0.498039),
                            clamp((f*f)*4.0,0.0,1.0));

                color = lerp(color,
                            fixed3(0,0,0.164706),
                            clamp(length(q),0.0,1.0));

                color = lerp(color,
                            fixed3(0.666667,1,1),
                            clamp(length(r.x),0.0,1.0));

                fixed result = f * f * f + .6 * f * f + .5 * f;
                return smoothstep(0.1, 0.9, result);
                return fixed4(result * color, 1);
            }
            ENDCG
        }
    }
}