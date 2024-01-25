//
//  MetalRenderView.swift
//  ExplosionSquare
//
//  Created by javi www on 1/19/24.
//

import SwiftUI
import MetalKit

struct LoadingParticlesView: UIViewRepresentable {
    
    @Binding var animateExplosion: Bool
    @Environment(\.colorScheme) var colorScheme

    @State  var didExplode = false
    
    func makeCoordinator() -> Renderer { Renderer(self) }
    
    func makeUIView(context: Context) -> MTKView  {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.drawableSize = mtkView.frame.size
        mtkView.backgroundColor = UIColor.clear
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Renderer.onTapAction))
        mtkView.addGestureRecognizer(tapGesture)
//        print("Mtk size \(mtkView.frame.size)") // Size 0
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.animateExplosion = animateExplosion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !didExplode && animateExplosion { // if didnt explore and will explore - set did
                self.didExplode = true
            }
        }
        
        context.coordinator.isDarkMode = colorScheme == .dark
        if didExplode && !animateExplosion {
            context.coordinator.resetAnimationState()
        }

//        context.coordinator.drawSize = CGSize(width: uiView.frame.width / 3, height: uiView.frame.height / 3)
//        print("Updated \(animateExplosion)")
    }

}

#Preview {
    LoadingParticlesView(animateExplosion: .constant(false))
        .frame(width: 54, height: 54)
        .preferredColorScheme(.dark)
}
