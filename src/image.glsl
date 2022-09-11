// Post proccessing & final output to screen.

/////////////////////////////////////////////////////////

#define gamma(fc, p) vec3(pow(fc.r, p), pow(fc.g, p), pow(fc.b, p))

void mainImage( out vec4 O, in vec2 U )
{
    if( texelFetch(iChannel2, ivec2(0), 0).z == 0. ) {
        O = texture(iChannel0, U/R);
    } else {
        O = mix(
        texture(iChannel0, U/R),
        texture(iChannel1, U/R),
        nlerp( texelFetch(iChannel2, ivec2(ACT_FRM, 0), 0)-30., texelFetch(iChannel2, ivec2(ACT_FRM, 0), 0)+80., float(iFrame) )
        );
    }
    O.rgb = gamma(max(O.rgb, 0.), 1.5);
    O.a = 1.;
}
