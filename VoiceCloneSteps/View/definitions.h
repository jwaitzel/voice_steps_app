//
//  definitions.h
//  MetalShaderBoilerplateApp
//
//  Created by javi www on 6/10/23.
//

#ifndef definitions_h
#define definitions_h

#include <simd/simd.h>

struct Vertex {
    vector_float2 position;
    vector_float4 color;
};

struct FragmentUniforms {
    float iTime;
    vector_float2 resolution;
    int particleCount;
    int particleFollowersCount;
    vector_float3 color;
};

struct ParticleAgent {
    vector_float2 position;
    vector_float2 velocity;
    vector_float2 acceleration;
    float orientation;
    float size;
    float mass;
};

#endif /* definitions_h */
