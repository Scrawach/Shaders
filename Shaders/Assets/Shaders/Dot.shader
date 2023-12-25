
    Shader "Practice/MyShader"
	{
	Properties{
	
	}
	SubShader
	{
	Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
	Pass
	{
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha
	CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"
			
    

    float4 vec4(float x,float y,float z,float w){return float4(x,y,z,w);}
    float4 vec4(float x){return float4(x,x,x,x);}
    float4 vec4(float2 x,float2 y){return float4(float2(x.x,x.y),float2(y.x,y.y));}
    float4 vec4(float3 x,float y){return float4(float3(x.x,x.y,x.z),y);}


    float3 vec3(float x,float y,float z){return float3(x,y,z);}
    float3 vec3(float x){return float3(x,x,x);}
    float3 vec3(float2 x,float y){return float3(float2(x.x,x.y),y);}

    float2 vec2(float x,float y){return float2(x,y);}
    float2 vec2(float x){return float2(x,x);}

    float vec(float x){return float(x);}
    
    

	struct VertexInput {
    float4 vertex : POSITION;
	float2 uv:TEXCOORD0;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
	//VertexInput
	};
	struct VertexOutput {
	float4 pos : SV_POSITION;
	float2 uv:TEXCOORD0;
	//VertexOutput
	};
	
	
	VertexOutput vert (VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos (v.vertex);
	o.uv = v.uv;
	//VertexFactory
	return o;
	}
    
    #define UVScale 			 0.4
#define Speed				 0.6

#define FBM_WarpPrimary		-0.24
#define FBM_WarpSecond		 0.29
#define FBM_WarpPersist 	 0.78
#define FBM_EvalPersist 	 0.62
#define FBM_Persistence 	 0.5
#define FBM_Lacunarity 		 2.2
#define FBM_Octaves 		 5



//fork from Dave Hoskins
//https://www.shadertoy.com/view/4djSRW
float4 hash43(float3 p)
{
	float4 p4 = frac(vec4(p.xyzx) * vec4(1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+19.19);
	return -1.0 + 2.0 * frac(vec4(
        (p4.x + p4.y)*p4.z, (p4.x + p4.z)*p4.y,
        (p4.y + p4.z)*p4.w, (p4.z + p4.w)*p4.x)
    );
}

//offsets for noise
static vector<float, 3> nbs = (
	vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(1.0, 1.0, 0.0),
	vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0), vec3(1.0, 0.0, 1.0), vec3(1.0, 1.0, 1.0)
);

//'Simplex out of value noise', forked from: https://www.shadertoy.com/view/XltXRH
//not sure about performance, is this faster than classic simplex noise?
float4 AchNoise3D(float3 x)
{
    float3 p = floor(x);
    float3 fr = smoothstep(0.0, 1.0, frac(x));

    float4 L1C1 = lerp(hash43(p+nbs[0]), hash43(p+nbs[2]), fr.x);
    float4 L1C2 = lerp(hash43(p+nbs[1]), hash43(p+nbs[3]), fr.x);
    float4 L1C3 = lerp(hash43(p+nbs[4]), hash43(p+nbs[6]), fr.x);
    float4 L1C4 = lerp(hash43(p+nbs[5]), hash43(p+nbs[7]), fr.x);
    float4 L2C1 = lerp(L1C1, L1C2, fr.y);
    float4 L2C2 = lerp(L1C3, L1C4, fr.y);
    return lerp(L2C1, L2C2, fr.z);
}

float4 ValueSimplex3D(float3 p)
{
	float4 a = AchNoise3D(p);
	float4 b = AchNoise3D(p + 120.5);
	return (a + b) * 0.5;
}

//my FBM
float4 FBM(float3 p)
{
    float4 f, s, n = vec4(0.0);
    float a = 1.0, w = 0.0;
    for (int i=0; i<FBM_Octaves; i++)
    {
        n = ValueSimplex3D(p);
        f += (abs(n)) * a;	//billowed-like
        s += n.zwxy *a;
        a *= FBM_Persistence;
        w *= FBM_WarpPersist;
        p *= FBM_Lacunarity;
        p += n.xyz * FBM_WarpPrimary *w;
        p += s.xyz * FBM_WarpSecond;
        p.z *= FBM_EvalPersist +(f.w *0.5+0.5) *0.015;
    }
    return f;
}


    
    
	fixed4 frag(VertexOutput vertex_output) : SV_Target
	{
	fixed2 uv = vertex_output.uv;
    float aspect = 1 / 1;
    uv /= 1 / UVScale *0.1; uv.x *= aspect;
    fixed4 col = vec4(0.0, 0.0, 0.0, 1.0);
    
    float4 fbm = (FBM(vec3(uv, _Time.y *Speed +100.0)));
    float explosionGrad = (dot(fbm.xyzw, fbm.yxwx)) *0.5;
    explosionGrad = pow(explosionGrad, 1.3);
    explosionGrad = smoothstep(0.0,1.0,explosionGrad);
    
    #define color0 vec3(1.2,0.0,0.0)
    #define color1 vec3(0.9,0.7,0.3)
    
    col.xyz = explosionGrad * lerp(color0, color1, explosionGrad) *1.2 +0.05;
	return col;
	}
	ENDCG
	}
  }
  }
