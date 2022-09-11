// Global scope stuff.

/////////////////////////////////////////////////////////

#define saturate(x) clamp(x, 0., 1.)
#define nlerp(t0, t1, t) saturate((t-t0)/(t1-t0))
#define R iResolution.xy
#define ss(v) smoothstep(0., 1., v)

// TODO: Add more levels
// if level 0 is too easy, you may find the other one pretty challenging.
#define LEVEL 1

#if LEVEL == 0
// Triplet occurance in board
const int diceWeights[6] = int[6](
    15, // 1's
    15, // 2's
    15, // 3's
    15, // 4's
    15, // 5's
    15  // 6's
);
#else
const int diceWeights[6] = int[6](
    5, // 1's
    5, // 2's
    5, // 3's
    5, // 4's
    5, // 5's
    5  // 6's
);
#endif

const int TRAY_SIZE = 5;
const int[6] NUMS = int[6]( 16, 68, 84, 325, 341, 365 );
float SCALE = 12.3, bevel = 0.05, shadow = 0.1, outline = 0.01;

const int HIT = 344;
const ivec2 TRAY = ivec2(HIT+1, HIT+TRAY_SIZE);
const ivec2 RSRV = ivec2(TRAY.y+2, TRAY.y+2+TRAY_SIZE);
const int ACT_FRM = RSRV.y+1;
const int MATCH = ACT_FRM+1;

float uvBoard(inout float sf, inout vec2 u, int x_axis, bool decimate ) {
    sf = SCALE;
    u -= vec2((1./SCALE)*(float(x_axis)/2.), -0.2);
    u *= SCALE;

    float ip = u.x;
    ip = floor(u.x)+float(x_axis);
    ip = ip > float(x_axis-1) || ip < -1. ? -1. : ip;
    u = decimate ? vec2(fract(u.x)-.5, u.y)*(1.-shadow*2.+outline*2.) : vec2(u.x, u.y);

    return ip;
}
