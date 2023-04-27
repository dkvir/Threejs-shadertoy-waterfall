uniform float iTime;
uniform vec3 iResolution;
uniform sampler2D iChannel0;


#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
//#define UI3 uvec3(UI0, UI1, 2798796415U)
//#define UI4 uvec4(UI3, 1979697957U)
#define UIF (1.0 / float(0xffffffffU))


float hash12(vec2 p)
{
	uvec2 q = uvec2(ivec2(p)) * UI2;
	uint n = (q.x ^ q.y) * UI0;
	return float(n) * UIF;
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);
    //vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);


    return mix( mix( hash12( i + vec2(0.0,0.0) ), 
                     hash12( i + vec2(1.0,0.0) ), u.x),
                mix( hash12( i + vec2(0.0,1.0) ), 
                     hash12( i + vec2(1.0,1.0) ), u.x), u.y);
}

float mNoise( in vec2 pos )
{
    vec2 q = pos;
    const mat2 m = mat2( 0.36,  0.80,  -0.80,  0.36 );
                    
    float amplitude = 0.5;
    float f  = amplitude*noise( q );
    float scale = 2.12;
    for (int i = 0; i < 4; ++i)
    {    
        q = m*q*scale; //q*=scale;
    	f += amplitude * noise( q );
        amplitude *= 0.5;
    }
    return f;
}


// voronoi stars - simplified and slightly optimized to use a single texture fetch for the randomness
vec3 stars(in vec2 pos)
{
    vec3 col = vec3(0.0);
    vec2 n = floor(pos);
    vec2 f = fract(pos);
    vec2 dir = sign(f-0.5);
    for( float j=0.0; j<=1.0; j+=1.0 )
    {
   		for( float i=0.0; i<=1.0; i+=1.0 )    
	    {
            vec2 cell = vec2(i*dir.x,j*dir.y);
            vec2 p = (n + cell)+0.5;
            vec4 rnd1 = texture( iChannel0, p/256.0, -100.0 ).xyzw; // random offset,col,brightness
            float d = length(cell + rnd1.xy - f);                
            rnd1.w = max(0.2,rnd1.w);
            // falloff
            float dist = max(0.1, 1.0 - d);
            float starfo = pow(dist, 60.0) * 6.5 + pow(dist, 120.0);
	        col += vec3(rnd1.z*0.2) * rnd1.w * starfo;
        }
    }
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
	
	vec2 uv = p;
    
    uv.x *= length(p-vec2(1.0));
    
    float ny = p.y+0.5; // ypos 0-1

    uv.y *= 1.2;
    uv.x *= 3.55;

	float t = iTime * .915;
    uv.y += t;
    
    float fval1 = mNoise(uv);
    uv.x *= 0.74;
    
    float fval = 0.33+(ny*0.1); // 0.13 less fuckage
    uv.x += 3.5+(fval1*fval); // here, we fuck layer2 with layer1 a touch for a lavalamp style effect
    uv.y -= t*0.53;
    float fval2 = mNoise(uv);
    
    float cut = 0.3;  
    fval1 = smoothstep(cut-0.1,1.8,fval1);
    fval2 = smoothstep(cut,1.8,fval2);
    fval1 = fval1+fval2;

    // colors (layer1)
    vec3 col1top = vec3(0.65,1.0,0.5);
    vec3 col1bot = vec3(0.85,0.86,0.85);

    // colors (layer2)
    vec3 col2top = vec3(1.1,0.75,0.5)*1.8;
    vec3 col2bot = vec3(1.0,0.85,0.7)*1.8;
    
    vec3 col1 = mix(col1bot,col1top,ny)*fval1;
    vec3 col2 = mix(col2bot,col2top,ny)*fval2;
    
    // this blend is calculated with the asspluck constant
    float blend = 0.5+(sin(fval1*4.25+fval2*1.75)*0.25);
    vec3 color = mix(col1,col2,blend)*1.11;

    // test it with a starfield background...
    color = clamp(color,vec3(0.0),vec3(1.0));
    float a = smoothstep(0.4,0.0,length(color)); // a = starmask
    color +=  stars(p*15.0) * a;


    // mouse = rgb swizzle
    //if (iMouse.z>0.5)
        color = color.zyx;
    // vignetting	
   color *= 1.0 - 0.4*dot(p,p);		// vignette


	fragColor = vec4(color.xyz,1.0);
}


void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec4 fragColor;
    mainImage(fragColor, fragCoord);
    gl_FragColor = fragColor;
}
