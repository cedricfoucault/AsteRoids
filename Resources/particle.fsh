// Set the precision we need when using GL_ES
#ifdef GL_ES
precision lowp float;
#endif

// Texture coordinate from the vertex shader
varying     vec2        varTexCoord;

// Texture to be sampled
uniform     sampler2D   u_texture;

void main()
{
    gl_FragColor = texture2D(u_texture, varTexCoord);
//    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}