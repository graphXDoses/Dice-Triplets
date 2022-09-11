// Logic buffer.

/////////////////////////////////////////////////////////

#define hash(p)  (mod((p*2654435761.), pow(2., 32.)) / pow(2., 32.))
#define get(id)  texelFetch(iChannel0, ivec2(id, 0), 0)

vec3 calcBoardSize(int[6] l) {
    int g = 0;
    int[6] pool;
    float res = 0.;
    // Find occuring dice ( weight > 0 )
    for(int s=0; s<6; s++) {
        if(l[s] > 0) {
            pool[g] = l[s];
            g++;
        } else { continue; }
    }
    // Find board dimentions
    for(int s=0; s<g; s++) {
        res += float(pool[s])*3.;
    }
    for(float s=2.; s<8.; s++) {
        float q = s*3.;
        // Board dimentions validity check. If invalid board is presented, draw no board.
        if( mod(res, q) == 0. ) {
            float temp1 = res/q, temp2 = res/temp1;
            if( all(lessThanEqual(vec2(temp1, temp2), vec2(21, 16))) ) {
                float mi = min(temp1, temp2), ma = max(temp1, temp2);
                if(mi<=16. && ma>16.) return vec3(ma, mi, res);
                return vec3(mi, ma, res);
            } else { continue; }
        } else { continue; }
    }
    return vec3(0);
}

void init(int id, inout vec4 O) {
    if( iFrame == 0 ) {
        O = vec4(0);
        if (id == 0 ) O = vec4(iDate.a,0,0,0);
        if (id == 1 ) O = vec4(calcBoardSize(diceWeights),0);
        if (id >= 2 && id <= 7) O = vec4((id-2) % 6,diceWeights[(id-2) % 6]*3,0,0);
    } else if(iFrame == 1) {
        // Place the total number of dice, sequentially.
        if( id >= 8 && id < int(get(1).z)+8 ) {
            int g = 0;
            int[6] pool;
            for(int s=0; s<6; s++) {
                int len = int(get(s+2).y);
                if(len > 0) {
                    pool[g] = int(get(s+2).x);
                    g++;
                } else { continue; }
            }
            O = vec4(pool[(id-8)%g],0,0,1);
        }
    } else if( iFrame == 2 ) {
        // Shuffle dice, vertically.
        // This way it is guaranteed for each dice to appear at least once in a column,
        // thanks to the previous sequential order configuration.
        if( id >= 8 && id < int(get(1).z)+8 ) {
            int[336] pool;
            for(int s=0; s<int(get(1).z); s++) {
                pool[s] = int(get(s+8).x);
            }
            for(int s=int(get(1).z)-1; s>0; s--) {
                int j = int(hash(get(0).x) * float(s)) % int(get(1).y);
                j += int(get(1).y)*int(float(s)/get(1).y);
                j = j % int(get(1).z);
                int temp   = pool[s];
                pool[s] = pool[j];
                pool[j] = temp;
            }
            O = vec4(pool[(id-8)],-1,0,1);
            if( (id-8) % int(get(1).y) == int(get(1).y)-1 ) O.a = 2.;
        }
    }
}

void mainImage( out vec4 O, in vec2 U )
{
    O = texelFetch(iChannel0, ivec2(U), 0);
    int id = int((U.x + U.y*R.x) - floor(R.x/2.));

    init(id, O);

    // Accepting clicks for proccessing after 150 frames
    // ( required for board to settle ), as long as the game is still on.
    if( iFrame > 150 && iMouse.w > 0.5 && get(0).z == 0. ) {

        // For a click to be considered meaningful, it has to hit
        // an active dice( alpha value of 2 ), given it occured a proper amount of frames
        // after the last meaningful hit. If there is no last meaningful hit, time delay restriction
        // has no effect.

        if( texelFetch(iChannel1, ivec2(iMouse.xy), 0).a == 2.
        && iFrame > int(get(ACT_FRM).z + ( get(MATCH).x > 0. ? 46. : 31. ) ) ) {

            if( get(TRAY.y).z == 0. && id == 0 ) {
                O.y++;
                if( O.y == get(1).z ) { O.z = 1.; } // If the total meaningful hits, equal the total amount of dice, its a win!
            }

            // Stores hit time permanently( Has no life time. )
            if( id == ACT_FRM ) { O = vec4(iFrame); }


            if( id==HIT || ( id>=TRAY.x && id<=TRAY.y ) || ( id>=2 && id<=7 ) ) {
                // Locates both targeted and diadochic dice.
                vec2 u = (iMouse.xy - R*.5)/R.y;
                float sf, ip = uvBoard(sf, u, int(get(1).x), true );
                int col = int((get(1).y) * ip);
                int tID, dID = -1;
                for(int i=8+col+(int(get(1).y))-1; i>8+col-1; i--) {
                    if(get(i).a == 2.) {
                      tID = i;
                      if(get(i-1).a == 1.) dID = i-1;
                      break;
                    }
                }
                // Stores the occurances of target dice, recorded to have been in tray.
                if( id>=2 && id<=7 ) {
                    if( get(id).x == get(tID).x ) { O = get(id); O.z++; }
                }
                if( id==HIT ) {
                    // Hit registration
                    O = vec4(tID,dID,iFrame,0); // Hit time here is stored temporarily( with a short life time ).
                } else {
                    int mark=-1, occ=0;
                    // Iterate through the tray to find the next empty space.
                    for(int i=TRAY.x; i<=TRAY.y; i++) {
                        if( all(equal(get(i), vec4(0))) ) { mark=i; break; } else continue;
                    }
                    vec4[TRAY_SIZE] pool; for(int i=0; i<TRAY_SIZE; i++) { pool[i] = get(i+TRAY.x); }
                    mark-=TRAY.x;
                    // Backtrack checking of same dice existance.
                    for(int j=mark-1; j>=0; j--) {
                        if( get(pool[j].x).x == get(tID).x ){
                            mark = j+1+TRAY.x;
                            occ = 1;
                            break;
                        }
                    }
                    O.y = 0.;

                    // Y component of dice in tray are states, with:
                    // 0: idle
                    // 1: moving from board position, towards tray position.
                    // 2: shift one position( tray ) to the right.( make way for incoming dice )
                    // 3: shift three positions( tray ) to the left.( take the space of the previously matched )
                    // 4: vanish.( confirmed matched )

                    // If similar dice are found, reorder tray.
                    if( occ == 1 ) {
                        if( id==mark )
                        { O = vec4(tID,1,iFrame,1); }
                        else if( id>mark ) {
                            O = get(id-1);
                            if(get(id-1).z > 150.) { O.y = 2.; O.a = 1.; }
                        }
                    } else if( occ == 0 ) {
                        if( id==mark+TRAY.x )
                        { O = vec4(tID,1,iFrame,1); }
                    }
                }
            }
        }
    }

    if( get(ACT_FRM).z > 0. && iFrame == int(get(ACT_FRM).z+30.) ) {
        // Overflow check.
        if( id == 0 ) {
            if( get(TRAY.y).z > 0. && mod(get( get(get(HIT).x).x+2. ).z, 3.) != 0. ) O.z = -1.;
        }

        // Checking for matches.
        if( ( id>=TRAY.x && id<=TRAY.y ) || ( id>=RSRV.x && id<=RSRV.y || id == MATCH ) ) {
            float n = get(get(HIT).x).x;
            int mark=-1;
            if( mod(get( n+2. ).z, 3.) == 0. ) {
                for(int i=TRAY.x; i<=TRAY.y; i++) {
                    if( get(get(i).x).x == n ) { mark=i; break; }
                }
                if( id >= mark ) {
                    O = get(min(id+3, TRAY.y+1));
                    if(O.z > 0.) { O.y = 3.; O.a = 1.; }
                } else {
                    O = get(id);
                }
                if( id>=RSRV.x && id<=RSRV.y ) {
                    O = get((id-RSRV.x)+TRAY.x);
                    if( (id-RSRV.x)+TRAY.x >= mark && (id-RSRV.x)+TRAY.x <= TRAY.y ) {
                        if( get(O.x).x == n ) {
                            O = vec4(get((id-RSRV.x)+TRAY.x).x, 4, mark, 1);
                        }
                    }
                }
                // Match indicator switch.
                if( id == MATCH ) {
                    O = vec4(1);
                }
            }
        }
    }

    // Reserve reset.
    if( id>=RSRV.x && id<=RSRV.y ) { if(get(id).a == 0. && get(id).y == 4.) { O = vec4(0); } }

    // Changes taking place during hit's life.
    if( get(HIT).z > 0. ) {

        if( id==HIT ) {
            if( get(HIT).w<1. ) {
                O.a = nlerp( get(HIT).z, get(HIT).z+30., float(iFrame) );
            } else {
                O = vec4(0);
            }
        }
        if( id == int(get(HIT).x) ) {
            O.a = 0.;
            O.z = max(O.z, get(HIT).w);
        }
        if( id == int(get(HIT).y) && int(get(HIT).y) != -1 ) { O.a = 1. + get(HIT).w; }

        if( ( id>=TRAY.x && id<=TRAY.y ) ) {
            if( get(id).w > 0. ) {
                if( get(id).y == 2. ) {
                    O.w = 1. - nlerp( get(ACT_FRM).z, get(ACT_FRM).z+15., float(iFrame) );
                } else { O.w = 1. - get(HIT).w; }
            }
        }
    }

    // Changes taking place according to dice in tray dynamic.
    if( iFrame > int(get(ACT_FRM).z+30.) ) {
        if( ( id>=TRAY.x && id<=TRAY.y ) || ( id>=RSRV.x && id<=RSRV.y ) ) {
            if( get(id).w > 0. ) {
                if( get(id).y == 3. ||  get(id).y == 4. ) {
                    O.w = 1. - nlerp( get(ACT_FRM).z-30., get(ACT_FRM).z+46., float(iFrame) );
                }
            }
        } else if( id == MATCH && get(MATCH).x == 1. ) {
            O = vec4(1) * float((1.-nlerp( get(ACT_FRM).z-30., get(ACT_FRM).z+46., float(iFrame) ) > 0.) );
        }
    }
}
