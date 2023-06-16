// Buffer used for displaying outcome screens.

/////////////////////////////////////////////////////////////

// This following section of code I borrowed from FabriceNeyret2's shader
// https://www.shadertoy.com/view/llySRh

/////////////////////////////////////////////////////////////

int char_id = -1; vec2 char_pos, dfdx, dfdy;
vec4 char(vec2 p, int c) {
    vec2 dFdx = dFdx(p/16.), dFdy = dFdy(p/16.);
 // if ( p.x>.25&& p.x<.75 && p.y>.0&& p.y<1. )  // normal char box
    if ( p.x>.25&& p.x<.75 && p.y>.1&& p.y<.85 ) // thighly y-clamped to allow dense text
        char_id = c, char_pos = p, dfdx = dFdx, dfdy = dFdy;
    return vec4(0);
}
vec4 draw_char() {
    int c = char_id; vec2 p = char_pos + vec2(-0.22, 0)*float(c == 0);
    return c < 0
        ? vec4(0,0,0,1e5)
        : textureGrad( iChannel3, p/16. + fract( vec2(c, 15-c/16) / 16. ),
                       dfdx, dfdy );
}

// --- chars
int CAPS=0;
#define low CAPS=32;
#define caps CAPS=0;
#define spc  u.x-=.5;
#define C(c) spc O+= char(u,64+CAPS+c);
// NB: use either char.x ( pixel mask ) or char.w ( distance field + 0.5 )

#define draw(s, sf) smoothstep((1./R.y)*sf, -(1./R.y)*sf, s)
#define get(id)  texelFetch(iChannel0, ivec2(id, 0), 0)

/////////////////////////////////////////////////////////////

void mainImage( out vec4 O, in vec2 U )
{
    O = vec4(0);vec4 _O = vec4(0);

    if( get(0).z != 0. ) {
        vec2 u = (U-R*.5)/R.y;
        float sf = 1.;
        vec2 abv = ( u+vec2(0.26,0) )*10., blw = ( u+vec2(0.175,0.065) )*20.;
        if( get(0).z == 1. ) { // Win screen
            u = abv;


            caps C(19) C(21) C(3) C(3) C(5) C(19) C(19) C(-31)

            u = blw;

            caps C(5) C(13) C(16) C(20) C(25) spc C(2) C(15) C(1) C(18) C(4)

        } else if( get(0).z == -1. ) { // Fail screen
            vec2 abv = ( u+vec2(0.18,0) )*10., blw = ( u+vec2(0.2,0.065) )*20.; //0.22
            u = abv;


            caps C(6) C(1) C(9) C(12)// C(-18) C(-18)

            u = blw;

            caps C(20) C(18) C(1) C(25) spc C(15) C(22) C(5) C(18) C(6) C(12) C(15) C(23)
        }
        _O = O; O = vec4(0);

        u = ( blw+vec2(-0.065,0.12)*20. );
        vec2 u_1 = u;

        caps u/=2.; C(-64)

        O = _O;//min(_O, O);

        O += draw_char().wwww;
        //O = vec4(1.-saturate(draw((1.-O*2.), 12.)));
    }
    //O.a = 1.;
}
