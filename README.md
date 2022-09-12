# Dice Triplets - A Matching Game

![sample](doc/sample.png)

List of contents:
- [Overview](#overview)
- [WebGL](#webgl)
- [Shadertoy](#shadertoy)
    - [Shadertoy code vs Conventional GLSL code](#shadertoy-code-vs-conventional-glsl-code)
    - [Built-in Uniforms](#)
<!-- - [WebGL 2.0](#webgl-2.0) -->
- [Game design](#game-design)
    - [Goal & philosophy](#goal--philosophy)
    - [Logic buffer](#logic-buffer)
    - [Render buffer](#render-buffer)
    - [Overlay buffer](#overlay-buffer)
    - [Common buffer](#common-buffer)

## Overview
Dice Triplets is a simple, yet fully functioning 2D puzzle game, that runs solely on the GPU. It is a demonstration project of the capabilities of parallel computing and mathematical optimizations used for improving performance in real-time graphics rendering.

While this repository contains the entirety of the project's source code, the project originally was developed and tested in the Shadertoy website (see below) and can be found here: [Dice Triplets Demo](https://www.shadertoy.com/view/fl3BDr).

## WebGL
WebGL (short for Web Graphics Library) is a JavaScript API for rendering interactive 2D and 3D graphics within any compatible web browser without the use of plug-ins. WebGL is fully integrated with other web standards, allowing GPU-accelerated usage of physics and image processing and effects as part of the web page canvas. WebGL elements can be mixed with other HTML elements and composited with other parts of the page or page background.

WebGL programs consist of control code written in JavaScript and shader code that is written in OpenGL ES Shading Language (GLSL ES), a language similar to C or C++, and is executed on a computer's graphics processing unit (GPU). WebGL is designed and maintained by the non-profit Khronos Group.


## Shadertoy
Shadertoy.com is an online community and platform for computer graphics professionals, academics and enthusiasts who share, learn and experiment with rendering techniques and procedural art through GLSL code. Initially released in 2013, it was primarely used by a small community of computer graphics professionals, but as of 2016 and until today, it has succeded in growing an online community, exponentially. Users of all backgrounds and skills are using this tool for creating and sharing shaders through WebGL, as well as for both learning and teaching 3D computer graphics in a web browser.

### Shadertoy code vs Conventional GLSL code
Typicaly, GLSL code written for vertex and fragment shaders, is formed as such:

```c
/*********************************************************************\
Example case of a simple Vertex shader
\*********************************************************************/
#version 330 es            // Version directive. Always present and strictly the first line of code!

// Uniform variables
uniform mat4 ViewProjectionMatrix;
uniform mat4 ModelMatrix;

// Vertex Attributes
layout (location = 0) in vec3 pos;

void main() {              // Main function. Always present, no inputs!
   gl_Position = ViewProjectionMatrix * ModelMatrix * vec4(pos, 1);
}

///////////////////////////////////////////////////////////////////////

/*********************************************************************\
Example case of a simple Fragment shader
\*********************************************************************/
#version 330 es            // Version directive. Always present and strictly the first line of code!
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
    fragColor = vec4(col);
}

```

However, in Shadertoy this syntax is actually deemed valid:
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
Both examples of code produce the exact same output.

Notice though that in Shadertoy example, most of the nessecary parts are missing. What happens is that Shadertoy tries to simplify the syntax of the code and focus exclusively on the fragment shading phase. While Shadertoy does not accept conventionally written GLSL code, it still parses its own syntax and converts it to regural GLSL before compilation.

### Built-in Uniforms
Table of Shadertoy built-in uniform values provided to every shader.

| Type | Name | Description |
| -- | -- | -- |
| vec3 | iResolution | viewport resolution (in pixels), z: pixel aspect ratio |
| float | iTime | shader playback time (in seconds) |
| float | iTimeDelta | render time (in seconds) |
| int | iFrame | shader playback frame |
| float | iChannelTime[4] | channel playback time (in seconds) |
| vec3 | iChannelResolution[4] | channel resolution (in pixels) |
| vec4 | iChannel0..3 | mouse pixel coords. xy: current (if MLB down), zw: click |
| sampler2D / samplerCube | dvs | input channel. XX = 2D/Cube |
| vec4 | iDate | (year, month, day, time in seconds) |
| float | iSampleRate | sound sample rate (i.e., 44100) |

<!-- ## WebGL 2.0 -->

---

## Game design

### Game goal & philosophy
The goal of the game is simple. All dice initially presented to the board have to be eleminated from it and off the collecting tray. To do that, the player has to match three identical dice by sending them towards the collecting tray, sequentially (different dice in-between dont break the sequence). Only the brightly lit dice can be moved. If no implications take place (e.g. tray overflows) the dice vanish completely, freeing up space to continue the proccess.

The absence of time pressure and scoring is calculated and intentional, so as to allow careful planning and strategy from players to develop, in solving the puzzle. However, that is not to be mistaken for the game being mildly difficult or less challenging. On the other side of the coin, if players seek a less challenging experience than the default provided, the game offers a second level design with a greater size board.

### Logic buffer
The logic buffer (or buffer B) is responsible for keeping track, altering and updating information related to the application such as last action frame, dice positions and indices, etc. It uses its own coordinate system to identify each fragment based on its position and the buffer resolution, by enumeration. Example: *For a resolution of (800, 450), the fragment on position (103, 28) will have an ID of 12.703*. This way its is easier for a fragment to be referenced, by only a single integer value. By comparing the current fragment's ID to a target ID or range, logic can be compartimentalized to blocks that only affect the values of fragments succeeding the ID comparison.

At the first frame of the application `iFrame==0`, a catholic value reset operation takes place and all fragments get set to zero. The next frame `iFrame==1`, the *init* function is called were the size of the board is calculated based on the level design (defined in common), the candidate dice with their index and number of occurances on the board and finally every dice is generated based on the above and allocates a random, unique position on the board. Also every generated dice at this step gets an opacity value assigned to them ranging from 0 to 2. That affects the ability/inability to move and color.

With the initialization proccess finished, for the next 149 frames the buffer retains its old values for all fragments, as it waits for the animation of the board settling to be completed.

The buffer reads itself (last frame) among other buffers it is related with and aquires the nessecary information for each task.

### Render buffer
The render buffer (or buffer C) configures the basis coordinate system (or space) that all render elements relate to, for positioning. It is responsible for constructing the shapes and colors of render elements as well as their  movement. All shapes are described with mathematical functions that determine if the current fragment is inside, outside or at the edge of the described function. Those functions are called signed distance fields or SDFs.

The buffer reads from the logic buffer.

### Overlay buffer
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

### Common buffer
The common buffer contains variables, functions and preprocessor directives that are commonly used from the majority of buffers and so they are required to be accesible everywhere. It essentially works as a global scope.

Shadertoy actually places the contents of the common buffer, before every buffer's code and prior to parsing and compilation.
