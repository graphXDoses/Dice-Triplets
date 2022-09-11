// Buffer used for drawing art elements.

/////////////////////////////////////////////////////////

const int TOTAL_LAYERS = 6;

#define hexToRGB(c) vec3(c >> 16, (c >> 8) & 255, c & 255) / 255.
#define getLogic(id) texelFetch(iChannel0, ivec2(id, 0), 0)
#define spacing(n) (1.-shadow*1.9)*float(n)
#define boardRel(id) vec2( floor(float(id-8) / getLogic(1).y)-(getLogic(1).x/2.-float(TRAY_SIZE)/2.), 2.-(shadow-outline*3.) + ((getLogic(1).y-mod(float(id-8), getLogic(1).y)-1.)/2.)*.77 )

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec3 bitBox(vec2 uv, vec2 size, int n)
{
    vec2 bsize = vec2(n);
    uv += size; uv /= size/(float(n)/2.);
    vec2 p = uv;
    uv = floor(uv);
    if ( any(greaterThan(uv, bsize-1.)) || any(lessThan(uv, vec2(0))) ) return vec3(1e8);
    return vec3(p-(uv+.5), (uv.x + uv.y*bsize.x) );
}

void aStack(inout float layer, in float sdf) { layer = min(layer, sdf); }

float dfMask(in float sdf, float sf) {sdf = smoothstep((1./R.y)*sf, (-1./R.y)*sf, sdf); return saturate(sdf);}

int hasDot(int id, int num) { return (num >> id) & 1; }

float layer[TOTAL_LAYERS] = float[TOTAL_LAYERS](
    1., 1., 1., 1., 1., 1.
);
vec3 color[TOTAL_LAYERS]  = vec3[TOTAL_LAYERS](
    vec3(31./255.), vec3(15./255.), vec3(0), vec3(1), hexToRGB(0xd6b38b), vec3(0)
);

void layering(vec2 uv, int n) {
    vec3 id = bitBox(uv-vec2(0., shadow), vec2(.5-(bevel+shadow)), 3);
    aStack(layer[3], sdBox(uv-vec2(0., shadow), vec2(.5-(bevel+shadow)))-bevel);
    aStack(layer[4], sdBox(uv, vec2(.5-(bevel+shadow)))-bevel);
    aStack(layer[5], min(layer[3], layer[4])-outline);

    if ( hasDot(int(id.z), NUMS[n%6]) == 1 ) aStack(layer[2], length(id.xy)-.4);
}

void mainImage( out vec4 O, in vec2 U )
{
    O = vec4(vec3(51./255.),0);
    vec2 u = (U - R*.5)/R.y, q = u, uzo = q;
    ivec2 BOARD_DIM = ivec2(getLogic(1).xy);
    float sf=1., ip = uvBoard(sf, q, BOARD_DIM.x, false );

    // RENDERING OF TRAY //

    q += vec2(float(BOARD_DIM.x/2), 2);
    aStack(layer[0], sdBox(q-vec2(0., shadow*2.-outline*3.), vec2(.5*float(TRAY_SIZE)-outline*5., .5+outline))-bevel);
    aStack(layer[1], sdBox(q-vec2(0., shadow/2.), vec2((.5*float(TRAY_SIZE)), .5-(shadow/sf)))-bevel);
    layer[1] = max(layer[1], layer[0]);
    O = mix(O, vec4(color[0], 1), dfMask(layer[0], sf));
    O = mix(O, vec4(color[1], 1), dfMask(layer[1], sf));

    // RENDERING OF DICE IN BOARD //

    sf, ip = uvBoard(sf, u, BOARD_DIM.x, true );

    u.y -= 7.5*(cos(min(iTime*(1.5+(float(BOARD_DIM.x)-ip)/10.), acos(-1.)))+1.)/2.;

    vec2 p = u;int cols = int(ip);

    for(int rows=0; rows<BOARD_DIM.y; rows++) {
        float dS = getLogic(8+(rows)+(cols*BOARD_DIM.y)).a;
        if(dS == 0.) continue;

        u+=vec2( 0. , -spacing(BOARD_DIM.y-rows)/2.1);

        layering(u, int(getLogic(8+(rows)+(cols*BOARD_DIM.y)).x));

        for(int i=TOTAL_LAYERS-1; i>1; i--)
        {
            vec3 c;
            if (i == 2) sf = SCALE*3.; else sf = SCALE;
            if(i==3) {
                c = mix(
                    mix(color[i], hexToRGB(0x65625d)*1.5, nlerp(120., 150., float(iFrame))),
                    color[i],
                    saturate(getLogic(8+(rows)+(cols*BOARD_DIM.y)).a - 1.)
                );
            } else { c = color[i]; }
            O = mix(O, vec4(c, dS), dfMask(layer[i], sf));
            layer[i] = 1.;
        }

        u = p;
    }

    q += vec2((float(TRAY_SIZE)/2.)-.5, -(shadow+outline));
    p = q;
    sf, ip = uvBoard(sf, uzo, TRAY_SIZE, true );
    uzo+=vec2( 0. , 1.5+shadow/2. );

    // RENDERING OF IDLE DICE IN TRAY //

    if( ip>-1. && int(ip)<TRAY_SIZE ) {
        if( getLogic(TRAY.x+int(ip)).z > 150. && getLogic(TRAY.x+int(ip)).w == 0. ) {

            layering(uzo, int(getLogic(getLogic(TRAY.x+int(ip)).x).x));

            for(int i=TOTAL_LAYERS-1; i>1; i--)
            {
                if (i == 2) sf = SCALE*3.; else sf = SCALE;
                O.rgb = mix(O.rgb, color[i], dfMask(layer[i], sf));
                layer[i] = 1.;
            }
        }
    }

    // RENDERING OF MOVING DICE IN/TOWARDS TRAY //

    if( getLogic(MATCH).x == 1. ) {
        for(int s=RSRV.x; s<=RSRV.y; s++) {
            if( getLogic(s).y == 0. || getLogic(s).a == 0. ) { continue; }

            if( getLogic(s).y == 4. ) {
                p.x -= float(s-RSRV.x);
                p *= (1.-shadow*2.+outline*2.);
            }

            layering(p, int(getLogic(getLogic(s).x).x));

            for(int i=TOTAL_LAYERS-1; i>1; i--)
            {
                if (i == 2) sf = SCALE*3.; else sf = SCALE;
                O.rgb = mix(mix(O.rgb, color[i], dfMask(layer[i], sf)), O.rgb, ss(cos(getLogic(s).a*3.)*.5+.5));
                layer[i] = 1.;
            }
            p = q;
        }
    }

    for(int s=TRAY.x; s<=TRAY.y; s++) {
        if( getLogic(s).y == 0. || getLogic(s).a == 0. ) { continue; }


        if( getLogic(s).y == 1. ) {
            p.x -= mix( boardRel(int(getLogic(s).x)).x, float(s-TRAY.x), ss(getLogic(getLogic(s).x).z) );//0. );
            p *= (1.-shadow*2.+outline*2.);
            p.y -= mix(boardRel(int(getLogic(s).x)).y, 0., ss(1.-getLogic(s).a) );
        } else if( getLogic(s).y == 2. ) {
            p.x -= mix( float(s-TRAY.x-1), float(s-TRAY.x), ss(1.-getLogic(s).a) );//0. );
            p *= (1.-shadow*2.+outline*2.);
        } else if( getLogic(s).y == 3. ) {
            p.x -= mix( float(s-TRAY.x+3), float(s-TRAY.x), ss(1.-getLogic(s).a) );//0. );
            p *= (1.-shadow*2.+outline*2.);
        }

        layering(p, int(getLogic(getLogic(s).x).x));

        for(int i=TOTAL_LAYERS-1; i>1; i--)
        {
            if (i == 2) sf = SCALE*3.; else sf = SCALE;
            O.rgb = mix(O.rgb, color[i], dfMask(layer[i], sf));
            layer[i] = 1.;
        }
        p = q;
    }
}
