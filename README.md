# Dice Triplets - A Matching Game

![sample](doc/sample.png)

List of contents:
- [Overview](#overview)
- [Shadertoy](#shadertoy)
    - [Shadertoy vs Conventional GLSL](#shadertoy-vs-conventional-glsl)
<!-- - [WebGL 2.0](#webgl-2.0) -->
- [Goal & Philosophy](#goal--philosophy)

## Overview
Dice Triplets is a simple, yet fully functioning 2D puzzle game, that runs solely on the GPU. It is a demonstration project of the capabilities of parallel computing and mathematical optimizations used for improving performance in real-time graphics rendering.

While this repository contains the entirety of the project's source code, the project originally was developed and tested in the Shadertoy website (see below) and can be found here: [Dice Triplets Demo](https://www.shadertoy.com/view/fl3BDr).

## Shadertoy
Shadertoy.com is an online community and platform for computer graphics professionals, academics and enthusiasts who share, learn and experiment with rendering techniques and procedural art through GLSL code. Initially released in 2013, it was primarely used by a small community of computer graphics professionals, but as of 2016 and until today, it has succeded in growing an online community, exponentially. Users of all backgrounds and skills are using this tool for creating and sharing shaders through WebGL, as well as for both learning and teaching 3D computer graphics in a web browser.

### Shadertoy vs Conventional GLSL
Typicaly, GLSL code written for vertex and fragment shaders, is formed as such:

```c
/***********************\
Simple Vertex shader
\***********************/
#version 330 es            // Version declerative. Always present!

// Uniform variables
uniform mat4 ViewProjectionMatrix;
uniform mat4 ModelMatrix;

// Vertex Attributes
layout (location = 0) in vec3 pos;

void main() {              // Main function. Always present, no inputs!
   gl_Position = ViewProjectionMatrix * ModelMatrix * vec4(pos, 1);
}

///////////////////////////////////////////////////////////////////////

/***********************\
Simple Fragment shader
\***********************/
#version 330 es            // Version declerative. Always present!
#precision highp float;

// Uniform variables
uniform float iTime;
uniform vec3 iResolution;

#define fragCoord gl_FragCoord.xy
out vec4 fragColor;

void main() {              // Main function. Always present, no inputs!
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    // Output to screen
    fragColor = vec4(color);
}

```

However, in Shadertoy this structure is actually accepted:
```c
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    // Output to screen
    fragColor = vec4(col,1.0);
}
```
Notice most of the nessecary parts are missing. What happens is that Shadertoy tries to simplify the syntax of the and focus exclusively on the fragment shading phase. While Shadertoy does not accept regural GLSL code, it still parses its own syntax and converts it to regural GLSL code before compilation.


<!-- ## WebGL 2.0 -->


## Goal & Philosophy
The goal of the game is simple. All dice initially presented to the board have to be eleminated from it and off the collecting tray. To do that, the player has to match three identical dice by sending them towards the collecting tray, sequentially. Only the brightly lit dice can be moved. If no implications take place (e.g. tray overflows due to lack of matches) the dice vanish completely, freeing up space to continue the proccess.

The absence of time pressure and scoring is calculated and intentional, so as to allow careful planning and strategy from players to develop, in solving the puzzle. However, that is not to be mistaken for the game being mildly difficult or less challenging.
