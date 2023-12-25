Shader "Practice/PerlinThings"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_FlowTex ("Flow Texture", 2D) = "white" {}
		_Tiling ("Tiling", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 0.25
		_FlowOffset ("Flow Offset", Float) = -0.5
		_UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Speed ("Speed", Float) = 1
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

			sampler2D _NoiseTex;
			sampler2D _FlowTex;
			
			fixed _UJump, _VJump;
			fixed _Tiling;
			fixed _FlowStrength;
			fixed _FlowOffset;
			fixed _Speed;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}


			float3 flowUVW (
				float2 uv, float2 flowVector, float2 jump,
				float flowOffset, float tiling, float time, bool flowB
			) {
				float phaseOffset = flowB ? 0.5 : 0;
				float progress = (time + phaseOffset);
				float3 uvw;
				uvw.xy = uv - flowVector + (progress / 50 + flowOffset);
				uvw.xy *= tiling;
				uvw.xy += phaseOffset;
				uvw.xy += (time - progress) * jump;
				uvw.z = 1 - abs(1 - 2 * progress);
				return uvw;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed2 flow = tex2D(_FlowTex, i.uv);
				flow *= _FlowStrength;
				
				float noise = tex2D(_FlowTex, i.uv).a;
				float time = _Time.y * _Speed + noise;

				
				fixed2 jump = fixed2(_UJump, _VJump);
				fixed3 uvwA = flowUVW(i.uv, flow, jump, _FlowOffset, _Tiling, time, false);
				fixed3 uvwB = flowUVW(i.uv, flow, jump, _FlowOffset, _Tiling, time, true);

				fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
				fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

				fixed4 c = (texA + texB);
				
				
				fixed col = tex2D(_NoiseTex,  uvwA.xy);
				fixed col2 = tex2D(_NoiseTex,  uvwA.xy + 0.5);
				fixed col3 = tex2D(_NoiseTex,  uvwA.xy+ 0.75);
				
				fixed step1 = smoothstep(0.2, 0.35, col);
				fixed step2 = smoothstep(0.2, 0.35, col2);
				fixed step3 = smoothstep(0.2, 0.35, col3);
				
				fixed result = 0.2 * step1 + 0.15 * step2 + 0.15 * step3;
				result = saturate(result);
				return result;
			}
			ENDCG
		}
	}
}