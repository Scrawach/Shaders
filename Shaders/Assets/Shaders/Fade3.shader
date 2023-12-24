Shader "Practice/Fade3"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			

			fixed3 random3(fixed3 c) {
			    float j = 4096.0*sin(dot(c,fixed3(17.0, 59.4, 15.0)));
			    fixed3 r;
			    r.z = frac(512.0*j);
			    j *= .125;
			    r.x = frac(512.0*j);
			    j *= .125;
			    r.y = frac(512.0*j);
			    return r-0.5;
			}

			float simplex3d(fixed3 p) {
				const float F3 =  0.3333333;
				const float G3 =  0.1666667;
				 fixed3 s = floor(p + dot(p, F3));
				 fixed3 x = p - s + dot(s, G3);
				 
				 fixed3 e = step(0, x - x.yzx);
				 fixed3 i1 = e*(1.0 - e.zxy);
				 fixed3 i2 = 1.0 - e.zxy*(1.0 - e);
				 
				 fixed3 x1 = x - i1 + G3;
				 fixed3 x2 = x - i2 + 2.0*G3;
				 fixed3 x3 = x - 1.0 + 3.0*G3;
				 
				 fixed4 w, d;
				 
				 w.x = dot(x, x);
				 w.y = dot(x1, x1);
				 w.z = dot(x2, x2);
				 w.w = dot(x3, x3);
				 
				 w = max(0.6 - w, 0.0);
				 
				 d.x = dot(random3(s), x);
				 d.y = dot(random3(s + i1), x1);
				 d.z = dot(random3(s + i2), x2);
				 d.w = dot(random3(s + 1.0), x3);
				 
				 w *= w;
				 w *= w;
				 d *= w;
				 
				 return dot(d, 52.0);
			}

			float fbm(fixed3 p)
			{
				float f = 0.0;	
				float frequency = 1.0;
				float amplitude = 0.5;
				for (int i = 0; i < 3; i++)
				{
					f += simplex3d(p * frequency) * amplitude;
					amplitude *= 0.5;
					frequency *= 2.0 + float(i) / 100.0;
				}
				return min(f, 1.0);
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

			fixed4 blend(fixed4 a, fixed4 b)
            {
                return 1 - (1 - a) * (1 - b);
            }
			
			fixed4 frag (v2f i) : SV_Target
			{
				const fixed3 inkColor = fixed3(0.01, 0.01, 0.1);
				const fixed3 paperColor = fixed3(1.0, 0.98, 0.94);

				const float speed = 0.075;
				const float shadeContrast = 0.55;
				
				fixed2 uv = screenUV(i.uv);
				fixed3 p = fixed3(uv, _Time.y * speed);
				fixed4 col = tex2D(_MainTex, uv);
				float blot = fbm(p * 3.0 + 8.0);
				float shade = fbm(p * 2.0 + 16.0);

				fixed blot1 = saturate(fbm(p + 8.0));
				fixed blot2 = saturate(fbm(p + 1230.1654));
				fixed blot3 = saturate(fbm(p * 2 + 2231.0));
				fixed blot4 = saturate(fbm(p * 4 + 126.0));

				blot1 = smoothstep(0, 0.25, blot1);
				blot2 = smoothstep(0, 0.15, blot2);
				blot3 = smoothstep(0, 0.55, blot3);
				blot4 = smoothstep(0, 0.05, blot4);
				
				blot = 0.5 * blot1 + 0.1 * blot2 + 0.02 * blot3;
				return 0.5 * smoothstep(0, 0.25, blot);
				blot = (blot + (sqrt(uv.x) - abs(0.5 - uv.y)));
				return blot;
				blot = smoothstep(0.65, 0.71, blot) * max(1.0 - shade * shadeContrast, 0.0);
				
				return shade;
			}
			ENDCG
		}
	}
}