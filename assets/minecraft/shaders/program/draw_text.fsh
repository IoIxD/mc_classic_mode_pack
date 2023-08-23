#version 150
in vec2 texCoord;          // screen texCoordition <-1,+1>
uniform sampler2D DiffuseSampler;
uniform sampler2D NumberSampler;
uniform sampler2D FontSampler;  // ASCII 32x8 characters font texture unit
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;


#define NUM_LAYERS 6

vec4 color_layers[NUM_LAYERS];
float depth_layers[NUM_LAYERS];
int active_layers = 0;

out vec4 fragColor;

void try_insert( vec4 color, float depth ) {
    if ( color.a == 0.0 ) {
        return;
    }

    color_layers[active_layers] = color;
    depth_layers[active_layers] = depth;

    int jj = active_layers++;
    int ii = jj - 1;
    while ( jj > 0 && depth_layers[jj] > depth_layers[ii] ) {
        float depthTemp = depth_layers[ii];
        depth_layers[ii] = depth_layers[jj];
        depth_layers[jj] = depthTemp;

        vec4 colorTemp = color_layers[ii];
        color_layers[ii] = color_layers[jj];
        color_layers[jj] = colorTemp;

        jj = ii--;
    }
}

vec3 blend( vec3 dst, vec4 src ) {
    return ( dst * ( 1.0 - src.a ) ) + src.rgb;
}

vec4 other_main() {
    color_layers[0] = vec4( texture( DiffuseSampler, texCoord ).rgb, 1.0 );
    depth_layers[0] = texture( DiffuseDepthSampler, texCoord ).r;
    active_layers = 1;

    try_insert( texture( TranslucentSampler, texCoord ), texture( TranslucentDepthSampler, texCoord ).r );
    try_insert( texture( ItemEntitySampler, texCoord ), texture( ItemEntityDepthSampler, texCoord ).r );
    try_insert( texture( ParticlesSampler, texCoord ), texture( ParticlesDepthSampler, texCoord ).r );
    try_insert( texture( WeatherSampler, texCoord ), texture( WeatherDepthSampler, texCoord ).r );
    //try_insert( texture( CloudsSampler, texCoord ), texture( CloudsDepthSampler, texCoord ).r );

    vec3 texelAccum = color_layers[0].rgb;
    for ( int ii = 1; ii < active_layers; ++ii ) {
        texelAccum = blend( texelAccum, color_layers[ii] );
    }
    
	return vec4(texelAccum.rgb,1.0);
}


uniform mat4 ProjMat;

vec2 guiPixel(mat4 ProjMat) {
	return vec2(ProjMat[0][0], ProjMat[1][1]) / 2.0;
}

float FXS = guiPixel(ProjMat).x * 16.0;         // font/screen resolution ratio
float FYS = guiPixel(ProjMat).y * 8.0;         // font/screen resolution ratio

const int TEXT_BUFFER_LENGTH = 16;
int text[TEXT_BUFFER_LENGTH];
float lengths[TEXT_BUFFER_LENGTH];
int textIndex;
vec4 text_colour;                    // color interface for printTextAt()

void floatToDigits(float x) {
    float y, a;
	const float base = 16.0;
    
    // Handle sign
    if (x < 0.0) { 
		text[textIndex] = 45; textIndex++; x = -x; 
	} else { 
		text[textIndex] = 43; textIndex++; 
	}

    // Get integer (x) and fractional (y) part of number
    y = x; 
    x = floor(x); 
    y -= x;

    // Handle integer part
    int i = textIndex;  // Start of integer part
    while (textIndex < TEXT_BUFFER_LENGTH) {
		// Get last digit, scale x down by 10 (or other base)
        a = x;
        x = floor(x / base);
        a -= base * x;
		// Add last digit to text array (results in reverse order)
        text[textIndex] = int(a) + 48; textIndex++;
        if (x <= 0.0) break;
    }
    int j = textIndex - 1;  // End of integer part

	// In-place reverse integer digits
    while (i < j) {
        int chr = text[i]; 
		text[i] = text[j];
		text[j] = chr;
		i++; j--;
    }

	text[textIndex] = 46; textIndex++;

    // Handle fractional part
    while (textIndex < TEXT_BUFFER_LENGTH) {
		// Get first digit, scale y up by 10 (or other base)
        y *= base;
        a = floor(y);
        y -= a;
		// Add first digit to text array
		if (a <= 0.0) break;
        text[textIndex] = int(a) + 48; textIndex++;
        if (y <= 0.0) break;
    }

	// Terminante string
    text[textIndex] = 0;
}

void characterrender(int char, float x0, float y0, float offset) {
    // Fragment position **in char-units**, relative to x0, y0
    float x = texCoord.x/FXS; x -= x0;
    float y = 0.5*(1.0 - texCoord.y)/FYS; y -= y0; 

    // Stop if not inside bbox
    if ((x < 0.0) || (x > 1.0) || (y < 0.0) || (y > 1.0)) {
		return;
	}
    
    int i = int(x); // Char index of this fragment in text
    x -= float(i); // Fraction into this char

	// Grab pixel from correct char texture
    i = char;
    x += float(int(i - ((i/16)*16)));
    y += float(int(i/16));
    x /= 16.0; y /= 16.0; // Divide by character-sheet size (in chars)

	vec4 fontPixel = texture2D(FontSampler, vec2(x,y));
	
	if(fontPixel.a >= 1.0) {
		text_colour = vec4(1.0-offset,1.0-offset,1.0-offset, 1.0);
	} 
    
}

void c(int char, float x0, float y0) {
	float position_offset = 0.1;
	float color_offset = 0.8;
	float x1 = x0+position_offset;
	float y1 = y0+position_offset;
	
	characterrender(char,x1,y1,color_offset);
	characterrender(char,x0,y0,0.0);
	
	
}

float starting = 0.2;

float charlen(float i) {
	float j = starting + ((i/2) * 0.8);
	starting += 0.8;
	return j;
}

void clearTextBuffer() {
    for (int i = 0; i < TEXT_BUFFER_LENGTH; i++) {
        text[i] = 0;
    }
    textIndex = 0;
}

const float starting_x = 0.25;
const float starting_y = 0.25;

void main() {
	vec4 numToPrint = texture2D(NumberSampler, vec2(0.5, 0.5));

	text_colour = texture2D(DiffuseSampler, texCoord);
	
	text_colour = other_main();

	// Define text to draw
    clearTextBuffer();
    c(77, 	starting_x,		starting_y); 	// M
	c(105, 	charlen(2.0),	starting_y); 	// i
	c(110, 	charlen(0.6),	starting_y); 	// n
	c(101, 	charlen(0.55),		starting_y); 	// e
	c(99, 	charlen(0.45),		starting_y); 	// c
	c(114, 	charlen(0.3),		starting_y); 	// r
	c(97, 	charlen(0.2),		starting_y); 	// a
	c(102, 	charlen(0.05),		starting_y); 	// f
	c(116, 	charlen(-0.38),	starting_y); 	// t
	c(32, 	charlen(0),		starting_y); 	//  
	c(49, 	charlen(-2),	starting_y); 	// 1
	c(46, 	charlen(-2),	starting_y); 	// .
	c(50, 	charlen(-3.5),	starting_y); 	// 2
	c(48, 	charlen(-3.5),	starting_y); 	// 0
	c(46, 	charlen(-3.75),	starting_y); 	// .
	c(49, 	charlen(-5),	starting_y); 	// 1
	c(32, 	charlen(-4.5),	starting_y); 	// 1
	
	gl_FragColor = text_colour;
}
