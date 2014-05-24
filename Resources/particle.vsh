
/**** Attributes ****/
// The position of the vertex being processed
attribute          vec4         inPosition;
// Texture coordinate
attribute          vec2         inTexCoord;

/**** Varying ****/
// Texture coordinate to the fragment shader
varying             vec2        varTexCoord;

/**** Uniforms ****/
// The projection matrix
//uniform             mat4        u_MVPMatrix;
uniform             mat4        u_VPMatrix;


/**** Program ****/
void main() {
    // Pass on the texture coordinate
    varTexCoord = inTexCoord;
    
    // Calculate the final position of the vertex using the projection matrix
    gl_Position = u_VPMatrix * inPosition;
    
}