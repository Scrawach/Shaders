Shader "Practice/Fade6"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			float4 _MainTex_ST;
			fixed _Progress;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed snoise(fixed3 uv, float res)
			{
				const fixed3 s = fixed3(1e0, 1e2, 1e3);
				
				uv *= res;
				
				fixed3 uv0 = floor(fmod(uv, res))*s;
				fixed3 uv1 = floor(fmod(uv+1., res))*s;
				
				fixed3 f = frac(uv); f = f*f*(3.0-2.0*f);

				fixed4 v = fixed4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
		      				  uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);

				fixed4 r = frac(sin(v*1e-1)*1e3);
				float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
				
				r = frac(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
				float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
				
				return lerp(r0, r1, f.z)*2.-1.;
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
			
			fixed2 polar(fixed2 cartesian)
			{
				fixed distance = length(cartesian);
				fixed angle = atan2(cartesian.y, cartesian.x);
				return fixed2(angle / UNITY_TWO_PI + .5, distance * .2);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed2 t = i.uv;
				fixed2 uv = screenUV(i.uv);
				fixed2 polarUv = polar(uv);

				fixed color = 5 * _Progress - (5 * _Progress * length(uv));
				for (int i = 1; i <= 5; i++)
				{
					fixed power = pow(2.0, fixed(i));
					color += (5 * _Progress / power) * snoise(fixed3(polarUv, .5) + fixed3(0., -_Time.y * 0.05, _Time.y * 0.01), power * 16);
				}
				
				color = smoothstep(0.4, 0.7, color);


				fixed tex = tex2D(_MainTex, t);
				return color * tex;
			}
			ENDCG
		}
	}
}