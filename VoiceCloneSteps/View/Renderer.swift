//
//  Renderer.swift
//  MetalShaderBoilerplateApp
//
//  Created by javi www on 6/11/23.
//

import MetalKit
import SwiftUI


enum AnimationRenderStage {
    case still
    case loading
    case explode
    case finished
}

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: LoadingParticlesView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState
    let vertexBuffer: MTLBuffer
    let fragmentUniformsBuffer: MTLBuffer
    var lastRenderTime: CFTimeInterval? = nil
    var currentTime: Double = 0
    var drawAspectRatio: Float = 1.0
    
    var particles = [ParticleAgent]()
    let particlesBuffer: MTLBuffer
    
    var totalParticles: Int = 7
    
    var followersForEachParticle: Int = 7
    var particlesFollowers = [ParticleAgent]()
    let particlesFollowersBuffer: MTLBuffer
    
    var drawSize: CGSize = .zero
    
    var animationStage: AnimationRenderStage = .loading
    
    var isDarkMode = false
    
    let particlesMultiplers: [Float] = [0.7, 0.5, 0.3]
    
    func resetAnimationState() {
        currentTime = 0
        animationStage = .loading
        print("Resetting loading")

    }
    var animateExplosion: Bool = false {
        didSet {
            if animateExplosion {
                currentTime = 0
                animationStage = .explode
                print("aninte explosion set")
            }
        }
    }
    
    init(_ parent: LoadingParticlesView) {
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print(error)
            fatalError()
        }
        
        /// - Vertices for a square made of two triangles
        let vertices = [
            Vertex(position: [-1, -1], color: [1, 0, 0, 1]),
            Vertex(position: [1, -1], color: [0, 1, 0, 1]),
            Vertex(position: [1, 1], color: [0, 0, 1, 1]),
            Vertex(position: [1, 1], color: [0, 0, 1, 1]),
            Vertex(position: [-1, 1], color: [0, 1, 0, 1]),
            Vertex(position: [-1, -1], color: [1, 0, 0, 1])
        ]
        self.vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        
        let partAgent = ParticleAgent(position: .zero, velocity: .zero, acceleration: .zero, orientation: 0, size: 0.0, mass: 0.0)
        
        self.particles = Array(repeating: partAgent, count: Int(totalParticles))
        
        self.particlesBuffer = metalDevice.makeBuffer(bytes: particles, length: particles.count * MemoryLayout<ParticleAgent>.stride, options: [])!
        
        let followerParticle = ParticleAgent(position: .zero, velocity: .zero, acceleration: .zero, orientation: 0, size: 0.0, mass: 0.0)
        
        self.particlesFollowers = Array(repeating: followerParticle, count: Int(followersForEachParticle * totalParticles))
        
        self.particlesFollowersBuffer = metalDevice.makeBuffer(bytes: particlesFollowers, length: particlesFollowers.count * MemoryLayout<ParticleAgent>.stride, options: [])!
        
        
        var initialFragmentUniforms = FragmentUniforms(iTime: 0.0, resolution: .zero, particleCount: Int32(totalParticles), particleFollowersCount: Int32(followersForEachParticle * totalParticles), color: .zero)
        fragmentUniformsBuffer = metalDevice.makeBuffer(bytes: &initialFragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])!
        
        super.init()
    }
    
    func fragUniformData() -> FragmentUniforms {
        let res = SIMD2(x: Float(drawSize.width), y: Float(drawSize.width))
        let color = isDarkMode ? vector_float3(x: 1.0, y: 1.0, z: 1.0) : vector_float3(x: 0.0, y: 0.0, z: 0.0)
        let initialFragmentUniforms = FragmentUniforms(iTime: 0.0, resolution: res, particleCount: Int32(totalParticles), particleFollowersCount: Int32(followersForEachParticle * totalParticles), color: color)
        return initialFragmentUniforms
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawSize = view.frame.size
        drawAspectRatio = Float(size.height / size.width)
        print("update size drawSize \(drawSize)")
    }
    
    func updateParticles() {
        /// - Apply force
        /// - Update
        let pSize: Float = Float(drawSize.width) * 0.03
        let baseCircleMultiplier: Float = 0.25
        var useRelativeSize: Bool = false
        if animationStage == .still {
            for pIdx in 0..<particles.count {
                let posF = vector_float2(x: Float(drawSize.width / 2.0) , y: Float(drawSize.height / 2.0))
                particles[pIdx].size = pSize
                particles[pIdx].position = posF
            }
        } else if animationStage == .loading {
            
            let angleStep = (Float.pi * 2) / Float(particles.count)
            let circleRadius: Float = Float(drawSize.width) * baseCircleMultiplier  * 0.75 + Float(drawSize.width) * baseCircleMultiplier * ((cosf(Float(currentTime * 4.0)) + 1.0) / 2.0) * 0.65
            let centerCircle = vector_float2(x: Float(drawSize.width / 2.0) , y: Float(drawSize.height / 2.0))
            let initVelocity: Float = 0.8
            let rotSpeed: Float = -2.4
            for pIdx in 0..<particles.count {
                //                let p = particles[pIdx]
                let ang = angleStep * Float(pIdx) + Float(currentTime) * rotSpeed
                //+ cosf(Float(currentTime * 2.5))
                let xPos = cosf(ang) * circleRadius
                let yPos = sinf(ang) * circleRadius
                let newPos = centerCircle + vector_float2(x: xPos, y: yPos) //p.position +
                
                let angVel = angleStep * Float(pIdx) + Float(currentTime) * rotSpeed
                let xVel = cosf(angVel) * initVelocity
                let yVel = sinf(angVel) * initVelocity
                let newVel = vector_float2(x: xVel, y: yVel)
                particles[pIdx].velocity = newVel
                particles[pIdx].position = newPos
                particles[pIdx].size = pSize + pSize * cosf(Float(currentTime)) * 0.15
            }
            
            if currentTime == 0 {
                for pIdx in 0..<particlesFollowers.count {
                    let attIdx = Int(Float(pIdx) / Float(followersForEachParticle))
                    let atrtAgnt = particles[attIdx]
                    let rangeOff: Float = Float(drawSize.width) * 0.05
                    let randomOffset = vector_float2(x: Float.random(in: -rangeOff...rangeOff), y: Float.random(in: -rangeOff...rangeOff))
                    particlesFollowers[pIdx].position = atrtAgnt.position + randomOffset
                }
            }
        } else if animationStage == .explode {
            let animDuration: Float = 0.3
//            let translationRadius: Float = Float(drawSize.width) * 0.1
//            let baseCircle: Float = Float(drawSize.width) * baseCircleMultiplier
            let animT: Float = min(1.0 , Float(currentTime) / animDuration)
//            let circleRadius: Float = baseCircle + animT * translationRadius
//            let angleStep = (Float.pi * 2) / Float(particles.count)
            let pSize: Float = pSize - pSize * 1.0 * animT
            useRelativeSize = true
            for pIdx in 0..<particles.count {
                let p = particles[pIdx]
//                let ang = angleStep * Float(pIdx)
//                let x = cosf(ang) * circleRadius
//                let y = sinf(ang) * circleRadius
                let newVel = (p.velocity) * 0.95// + Drag velocity
                let newPos = p.position + newVel
                particles[pIdx].size = pSize
                particles[pIdx].velocity = newVel
                particles[pIdx].position = newPos
            }
        }
        
        /// Animate followers particles
        for pIdx in 0..<particlesFollowers.count {
            let attIdx = Int(Float(pIdx) / Float(followersForEachParticle))
            let atrtAgnt = particles[attIdx]
            let part = particlesFollowers[pIdx]
            let attDir = atrtAgnt.position - part.position
            let attMagSq = min(0.19, simd_distance_squared(atrtAgnt.position, part.position)) //min(0.1, )
            let normAttVec = simd_normalize(attDir)
            //            let attStrengthLog = max(-20, min(20, pow(0.9, attMagSq * 0.1)))
            let attVectorFinal = normAttVec * attMagSq //attStrengthLog
            //attStrengthLog \(attStrengthLog)
//            print("attMagSq \(attMagSq)")
            let vel = part.velocity + attVectorFinal
            let newPos = part.position + vel
            particlesFollowers[pIdx].velocity = vel
            particlesFollowers[pIdx].position = newPos
            particlesFollowers[pIdx].acceleration = .zero
            let idxMulti = min(pIdx % followersForEachParticle, particlesMultiplers.count-1)
//            print("idx multi \(pIdx)-\(idxMulti)")
            let particlesMultiplersForIdx = particlesMultiplers[idxMulti] //particlesMultiplers[idxMulti]
            particlesFollowers[pIdx].size = useRelativeSize ? atrtAgnt.size * particlesMultiplersForIdx : pSize * particlesMultiplersForIdx
        }
        
    }
    
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let systemTime = CACurrentMediaTime()
        let timeDifference = (lastRenderTime == nil) ? 0 : (systemTime - lastRenderTime!)
        
        let commandBuffer = metalCommandQueue.makeCommandBuffer()
        
        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        renderPassDescriptor?.colorAttachments[0].loadAction = .clear
        renderPassDescriptor?.colorAttachments[0].storeAction = .store
        guard let renderPassDescriptor else {
            return
        }
        
        updateParticles()
        
        // Save this system time
        lastRenderTime = systemTime
        currentTime += timeDifference
        
        /// Update agens buffer with particles array
        memcpy(particlesBuffer.contents(), particles, particles.count * MemoryLayout<ParticleAgent>.stride)
        
        memcpy(particlesFollowersBuffer.contents(), particlesFollowers, particlesFollowers.count * MemoryLayout<ParticleAgent>.stride)
        
        //        let res = SIMD2(x: Float(view.frame.size.width), y: Float(view.frame.size.height)) // to convert pixels to 0-1
        var fragmUniforms = fragUniformData()
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBytes(&fragmUniforms, length: MemoryLayout.size(ofValue: fragmUniforms), index: 1)
        
        renderEncoder?.setFragmentBytes(&fragmUniforms, length: MemoryLayout.size(ofValue: fragmUniforms), index: 0)
        renderEncoder?.setFragmentBuffer(particlesBuffer, offset: 0, index: 1)
        renderEncoder?.setFragmentBuffer(particlesFollowersBuffer, offset: 0, index: 2)
        
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 3, vertexCount: 6)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    @objc
    func onTapAction() {
        print("Tap action")
        if self.animationStage == .loading {
            self.animationStage = .explode
        } else if self.animationStage == .explode {
            self.animationStage = .still
        } else if self.animationStage == .still {
            self.animationStage = .loading
        }
        currentTime = 0.0 //Restart for animation
    }
}

