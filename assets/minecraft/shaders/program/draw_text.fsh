#version 150
in vec2 texCoord;          // screen texCoordition <-1,+1>

uniform sampler2D NumberSampler;
uniform sampler2D FontSampler;  // ASCII 32x8 characters font texture unit

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
    float x = texCoord.x/FXS; 
	x -= x0;
    float y = 0.5*(1.0 - texCoord.y)/(FYS); 
	y -= y0;

    int i = int(x); // Char index of this fragment in text
    x -= float(i); // Fraction into this char

    // Stop if not inside bbox
    if ((x < 0.0) || (x > 1.0) || (y < 0.0) || (y > 1.0))
	{
		return;
	} else {
		// Grab pixel from correct char texture
		i = char;
		x += float(int(i - ((i/16)*16)));
		y += float(int(i/16));
		x /= 16.0; y /= 16.0; // Divide by character-sheet size (in chars)

		vec4 fontPixel = texture2D(FontSampler, vec2(x,y));
		
		if(fontPixel.a >= 1.0) {
			text_colour = vec4(1.0-offset,1.0-offset,1.0-offset,1.0);
		} else {
			text_colour = vec4(0.0,0.0,0.0,1.0);
			return;
		}
	}
}


void c(int char, float x0, float y0) {
	float position_offset = 0.1;
	float color_offset = 0.8;
	float x1 = x0-position_offset;
	float y1 = y0-position_offset;
	characterrender(char,x0,y0,color_offset);
	characterrender(char,x1,y1,0.0);
	
}

float starting = 1.0;

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

void main() {

	text_colour = texture2D(NumberSampler, texCoord);

	// Define text to draw
    clearTextBuffer();
    c(77, 	1.0,			1.0); 	// M
	c(105, 	charlen(2.2),	1.0); 	// i
	c(110, 	charlen(1),		1.0); 	// n
	c(101, 	charlen(1),		1.0); 	// e
	c(99, 	charlen(1),		1.0); 	// c
	c(114, 	charlen(1),		1.0); 	// r
	c(97, 	charlen(1),		1.0); 	// a
	c(102, 	charlen(1),		1.0); 	// f
	c(116, 	charlen(0.7),	1.0); 	// t
	c(32, 	charlen(0),		1.0); 	//  
	c(49, 	charlen(-0.5),	1.0); 	// 1
	c(46, 	charlen(-0.5),	1.0); 	// .
	c(50, 	charlen(-1.75),	1.0); 	// 2
	c(48, 	charlen(-1.75),	1.0); 	// 0
	c(46, 	charlen(-1.75),	1.0); 	// .
	c(49, 	charlen(-3.0),	1.0); 	// 1
	c(32, 	charlen(-3.0),	1.0); 	// 1
	gl_FragColor = text_colour;
}
