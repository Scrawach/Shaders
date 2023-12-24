Shader "Practice/Ink"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Octave1 ("Texture", 2D) = "white" {}
        _Octave2 ("Texture", 2D) = "white" {}
        _Octave3 ("Texture", 2D) = "white" {}
        _Octave4 ("Texture", 2D) = "white" {}
        _Emptiness ("Emptiness", float) = 0.0
        _Sharpness ("Sharpness", float) = 0.0
        _Speed ("Speed", float) = 0.0
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
                float4 position : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _Octave1;
            float4 _Octave1_ST;
            
            sampler2D _Octave2;
            float4 _Octave2_ST;
            
            sampler2D _Octave3;
            float4 _Octave3_ST;
            
            sampler2D _Octave4;
            float4 _Octave4_ST;

            float _Speed;
            float _Emptiness;
            float _Sharpness;
            
            v2f vert (appdata v)
            {
                fixed time = _Time.x;
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv0.xy = TRANSFORM_TEX(v.uv, _Octave1) + _Time.x * 1.0 * _Speed * half2(1.0, 0.0);
                o.uv0.zw = TRANSFORM_TEX(v.uv, _Octave2) + _Time.x * 1.5 * _Speed * half2(0.0, 1.0);
                o.uv1.xy = TRANSFORM_TEX(v.uv, _Octave3) + _Time.x * 2.0 * _Speed * half2(0.0, -1.0);
                o.uv1.zw = TRANSFORM_TEX(v.uv, _Octave4) + _Time.x * 2.5 * _Speed * half2(-1.0, 0.0);

                return o;
            }
                                    
            fixed4 frag (v2f i) : SV_Target
            {
                float4 n0 = tex2D(_Octave1, i.uv0.xy);
                float4 n1 = tex2D(_Octave2, i.uv0.zw);
                float4 n2 = tex2D(_Octave3, i.uv1.xy);
                float4 n3 = tex2D(_Octave4, i.uv1.zw);
                float4 fbm = 1.5 * n0 + 0.25 * n1 + 0.125 * n2 + 0.0625 * n3;

                fbm = smoothstep(0.1, 0.5, fbm);
                return fbm * fbm;
                fbm = clamp(fbm, _Emptiness, _Sharpness) - _Emptiness;
                fbm /= _Sharpness - _Emptiness;

                fbm = smoothstep(0, 1, fbm);
                fixed fbm2 = smoothstep(0.1, .6, fbm);
                fixed fbm3 = smoothstep(0.4, .6, fbm);
                return fbm2 - fbm3;
            } 
            ENDCG
        }
    }
}
