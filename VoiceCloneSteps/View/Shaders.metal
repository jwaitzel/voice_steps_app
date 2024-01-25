//
//  Shaders.metal
//  MetalShaderBoilerplateApp
//
//  Created by javi www on 6/10/23.
//

#include <metal_stdlib>
using namespace metal;

#include "definitions.h"

struct Fragment {
    vector_float4 position [[position]];
    vector_float4 color;
    vector_float2 texCoord;
};


typedef float2 vec2;
typedef float3 vec3;
typedef float4 vec4;

float sdCircle( vec2 p, float r ) {
    return length(p) - r;
}

//MARK: - Vertex Shader
vertex Fragment vertexShader(constant Vertex *vertexArray [[ buffer(0) ]], uint vid [[ vertex_id ]], constant FragmentUniforms &fragUniforms [[ buffer(1) ]]) {
    Vertex ver = vertexArray[vid];
    Fragment out;
    out.position = float4(ver.position, 0.0, 1.0);
    out.texCoord = (ver.position + 1.0) / 2.0 * fragUniforms.resolution;
    return out;
}

//MARK: - Fragment Shader
fragment float4 fragmentShader(Fragment input [[stage_in]], constant FragmentUniforms &fragUniforms [[ buffer(0) ]], constant ParticleAgent * partBuffer [[ buffer(1) ]], constant ParticleAgent * partFollowersBuffer [[ buffer(2) ]]) {
    
//    float iTime = fragUniforms.iTime;
    float2 iRes = fragUniforms.resolution;
    int particleCount = fragUniforms.particleCount;
    int particleFollowersCount = fragUniforms.particleFollowersCount;

    float2 uv = input.texCoord / iRes.x;
    float2 asp = vec2(1.0, iRes.y/iRes.x);
    float4 finalColor = vec4(0.0);
    float3 col = fragUniforms.color;
    vec4 clearC = vec4(0, 0, 0, 0);
    vec4 particleColor = vec4(col.x, col.y, col.z, 1);
    vec4 particleFollow = particleColor * 1.0; //vec4(1.0, 0.0, col.z, 1.0);
    
    /// - Particles Layer
    for(int i = 0; i < particleCount; i++) {
        
        float circleRadius = partBuffer[i].size / iRes.x;
        vec2 circleCenter = partBuffer[i].position / iRes;
        circleCenter *= asp;
        
        float distToCircle = sdCircle(uv - circleCenter, circleRadius);
        finalColor += distToCircle > 0.0 ? clearC : particleColor;
    }
    /// - Followers
    for(int i = 0; i < particleFollowersCount; i++) {
        float circleRadius = partFollowersBuffer[i].size / iRes.x;
        vec2 circleCenter = partFollowersBuffer[i].position / iRes;
        circleCenter *= asp;
        
        float distToCircle = sdCircle(uv - circleCenter, circleRadius);
        finalColor += distToCircle > 0.0 ? clearC : particleFollow;
    }
    

    float4 colorOut = finalColor;
    return colorOut;
}


