//
//  ARManager.swift
//  Myanmar Lens
//
//  Created by Aung Ko Min on 8/1/20.
//  Copyright © 2020 Aung Ko Min. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class ARManager: NSObject, ObservableObject {
    
    let sceneView = ARSCNView(frame: UIScreen.main.bounds)
     let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    override init() {
        super.init()
        sceneView.delegate = self
        sceneView.showsStatistics = true
    
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func start() {
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = Set([ARReferenceImage(UIImage(systemName: "circle.fill")!.cgImage!, orientation: .up, physicalWidth: 100)])
        configuration.maximumNumberOfTrackedImages = 1
        sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
    }
}

extension ARManager: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        updateQueue.async {
            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            mainPlane.firstMaterial?.colorBufferWriteMask = .alpha
            
            // Create a SceneKit root node with the plane geometry to attach to the scene graph
            // This node will hold the virtual UI in place
            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.eulerAngles.x = -.pi / 2
            mainNode.renderingOrder = -1
            mainNode.opacity = 1
            
            // Add the plane visualization to the scene
            node.addChildNode(mainNode)
            
            // Perform a quick animation to visualize the plane on which the image was detected.
            // We want to let our users know that the app is responding to the tracked image.
            self.highlightDetection(on: mainNode, width: physicalWidth, height: physicalHeight, completionHandler: {
                
                // Introduce virtual content
                self.displayDetailView(on: mainNode, xOffset: physicalWidth)
                
                // Animate the WebView to the right
//                self.displayWebView(on: mainNode, xOffset: physicalWidth)
                
            })
        }
    }
    func displayDetailView(on rootNode: SCNNode, xOffset: CGFloat) {
        let detailPlane = SCNPlane(width: xOffset, height: xOffset * 1.4)
        detailPlane.cornerRadius = 0.25
        
        let detailNode = SCNNode(geometry: detailPlane)
        detailNode.geometry?.firstMaterial?.diffuse.contents = SKScene(fileNamed: "DetailScene")
        
        // Due to the origin of the iOS coordinate system, SCNMaterial's content appears upside down, so flip the y-axis.
        detailNode.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        detailNode.position.z -= 0.5
        detailNode.opacity = 0
        
        rootNode.addChildNode(detailNode)
        detailNode.runAction(.sequence([
            .wait(duration: 1.0),
            .fadeOpacity(to: 1.0, duration: 1.5),
            .moveBy(x: xOffset * -1.1, y: 0, z: -0.05, duration: 1.5),
            .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
            ])
        )
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    func highlightDetection(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
           let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
           planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
           planeNode.position.z += 0.1
           planeNode.opacity = 0
           
           rootNode.addChildNode(planeNode)
           planeNode.runAction(self.imageHighlightAction) {
               block()
           }
       }
       
       var imageHighlightAction: SCNAction {
           return .sequence([
               .wait(duration: 0.25),
               .fadeOpacity(to: 0.85, duration: 0.25),
               .fadeOpacity(to: 0.15, duration: 0.25),
               .fadeOpacity(to: 0.85, duration: 0.25),
               .fadeOut(duration: 0.5),
               .removeFromParentNode()
               ])
       }
}
