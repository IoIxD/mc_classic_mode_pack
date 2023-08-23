#version 150

#moj_import <config.glsl>

#if HORISONTAL == 0
    #define FLIPX 1
#else
    #define FLIPX -1
#endif

#define PI 3.1415926

in vec3 Position;
in vec2 UV0;

uniform sampler2D Sampler0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec2 ScreenSize;

out vec2 texCoord0;
out vec2 helpCoord;
out float xp;

void main() {
    texCoord0 = UV0;
    helpCoord = vec2(0);
    xp = 0;

    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
	
    ivec2 texSize = textureSize(Sampler0, 0);
    vec2 uv = floor(UV0 * 256);

    if (!(texelFetch(Sampler0, ivec2(0, 228 / 256.0 * texSize.y), 0) == vec4(1))) //Stop shader, if it isn't icon texture
        return;

    //Base parameters
    const vec2[4] corners = vec2[4](vec2(0, 0), vec2(0, 1), vec2(1, 1), vec2(1, 0));
    vec3 Pos = Position;
    int id = (gl_VertexID) % 4;

    if (uv.x >= 16 && uv.x <= 196 && (uv.y - corners[id].y * 9 == 0 || uv.y - corners[id].y * 9 == 45)) //Hearts
    {
		
        Pos.y += 7;
    }
    else if (uv.x >= 16 && uv.x <= 142 && uv.y - corners[id].y * 9 == 27) //Food
    {
        Pos.x = 0;
		Pos.y = 0;
    }
    else if (uv.x >= 16 && uv.x - corners[id].x * 9 <= 43 && uv.y - corners[id].y * 9 == 9) //Armor
    {
		Pos.x += 101;
        Pos.y += 17;
    }
    else if (uv.x >= 16 && uv.x - corners[id].x * 9 >= 43 && uv.y - corners[id].y * 9 == 9) //Horse hearts
    {
	
        Pos.y -= 3;
    }
    else if (uv.x >= 16 && uv.x - 9 + corners[id].x * 9 <= 52 && uv.y - corners[id].y * 9 == 18) //Air
    {
        Pos.x -= 101;
        Pos.y += 7;
    }
    else if (uv.x <= 182 && ((uv.y >= 64 && uv.y <= 74) || (uv.y >= 84 && uv.y <= 94))) //Xp and horse's jump Bars
    {
        Pos.x = 0;
        Pos.y = 0;
    }

    texCoord0 = uv / 256;
    gl_Position = ProjMat * ModelViewMat * vec4(Pos, 1.0);
}
