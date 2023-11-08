Shader "Practice/Blur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Progress ("Progress", range(0, 1)) = 0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed directions = 16.0;
                fixed quality = 3.0;
                fixed size = 32 * _Progress;

                fixed2 radius = size / _ScreenParams.xy;
                fixed2 uv = i.uv;
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed alpha = col.a;
                for (fixed d = 0.0; d < UNITY_PI; d += UNITY_PI / directions)
                {
                    for (fixed i1 = 1.0 / quality; i1 <= 1.0; i1 += 1.0 / quality)
                    {
                        col += tex2D(_MainTex, uv + fixed2(cos(d), sin(d)) * radius * i1);
                    }
                }

                col /= quality * directions - 15.0;
                return col;
            }
            ENDCG
        }
    }
}
