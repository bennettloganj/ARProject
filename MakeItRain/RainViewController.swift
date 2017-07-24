//
//  RainViewController.swift
//  MakeItRain
//
//  Created by LunarLincoln on 7/21/17.
//  Copyright © 2017 LunarLincoln. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class RainViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var itemNum = 0
    var selectedNode: SCNNode?
    var cloudNode: SCNNode?
    var label: UILabel?
    var spawnTime: TimeInterval = 0
    var objectsArrayFiles: [String] = [ "art.scnassets/pumpkin.scn", "art.scnassets/golden-mushroom.scn", "art.scnassets/Lowpoly_tree_sample.scn"]
    var objectsArrayNames: [String] = ["pumpkin", "Poly", "Tree_lp_11"]
    var planes = [String: SCNNode]()
    
    var isNegative = false
    var hasPlane = false
    
    let objectCategory:Int = 1 << 0
    let planeCategory:Int = 1 << 1
    let bottomCategory:Int = 1 << 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 310, height: 75))
        label!.center = CGPoint(x: 160, y: 285)
        label!.textAlignment = .center
        label?.numberOfLines = 2
        label?.adjustsFontSizeToFitWidth = true
        label!.text = "Move around until you have located a plane.\nOnce you have a plane, tap on it to bring the rain!"
        
        label?.backgroundColor = UIColor(white: 1, alpha: 0.25)
        self.view.addSubview(label!)
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: objectsArrayFiles[itemNum])!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.scene.physicsWorld.gravity = SCNVector3Make(0.0, -9.81, 0.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        var objectNode = SCNNode()
        objectNode = sceneView.scene.rootNode.childNode(withName: objectsArrayNames[itemNum], recursively: true)!
        if itemNum == 0 {
            objectNode.scale.x = 0.01
            objectNode.scale.y = 0.01
            objectNode.scale.z = 0.01
        }
        else if itemNum == 1 {
            objectNode.scale.x = 0.0075
            objectNode.scale.y = 0.0075
            objectNode.scale.z = 0.0075
        }
        else {
            objectNode.scale.x = 0.05
            objectNode.scale.y = 0.05
            objectNode.scale.z = 0.05
        }
        objectNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        
        objectNode.physicsBody?.categoryBitMask = objectCategory
        objectNode.physicsBody!.collisionBitMask = planeCategory | objectCategory
        objectNode.physicsBody!.contactTestBitMask = planeCategory
        
        let bottomPlane = SCNBox(width: 1000, height: 0.005, length: 1000, chamferRadius: 0)
        
        // Use a clear material so the body is not visible
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [material]
        
        // Position 10 meters below the floor
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: -1, z: 0)
        
        // Apply kinematic physics, and collide with shape categories
        let physicsBody = SCNPhysicsBody.static()
        physicsBody.categoryBitMask = bottomCategory
        physicsBody.contactTestBitMask = objectCategory
        bottomNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
        
        self.selectedNode = objectNode
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        if (contact.nodeA.physicsBody?.categoryBitMask)! == bottomCategory || (contact.nodeA.physicsBody?.categoryBitMask)! == objectCategory{
            if (contact.nodeB.physicsBody?.categoryBitMask)! == bottomCategory || (contact.nodeB.physicsBody?.categoryBitMask)! == objectCategory {
                if contact.nodeB.physicsBody!.categoryBitMask == objectCategory {
                    contact.nodeB.removeFromParentNode()
                } else {
                    contact.nodeA.removeFromParentNode()
                }
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlaneUsingExtent])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,
                                         2,
                                         hitTransform.m43)
        
        spawnRainCloud(hitPosition: hitPosition)
    }
    
    func spawnRainCloud(hitPosition: SCNVector3){
        if cloudNode != nil {
            cloudNode?.removeFromParentNode()
        }
        let subScene = SCNScene(named: "art.scnassets/ship.scn")!
        cloudNode = subScene.rootNode.childNode(withName: "shipMesh", recursively: true)
        cloudNode?.position = hitPosition
        
        sceneView.scene.rootNode.addChildNode(cloudNode!)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This visualization covers only detected planes.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        DispatchQueue.main.async {
            self.label?.isHidden = true
        }
        
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x), height: 0.005, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0)
        
        let color = SCNMaterial()
        color.diffuse.contents = UIColor(red: 0, green: 0, blue: 1, alpha: 0.2)
        plane.materials = [color]
        
        // Create a SceneKit plane to visualize the node using its position and extent.
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        //planeNode?.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        //physics
        let planeBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: plane, options: nil))
        planeBody.restitution = 0.0
        planeBody.friction = 1.0
        planeNode.physicsBody = planeBody
        planeNode.physicsBody!.categoryBitMask = planeCategory
        planeNode.physicsBody!.collisionBitMask = objectCategory
        planeNode.physicsBody!.contactTestBitMask = objectCategory
        
        
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        //sceneView.scene.rootNode.addChildNode(planeNode!)
        node.addChildNode(planeNode)
        
        let key = planeAnchor.identifier.uuidString
        self.planes[key] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            if let geometry = existingPlane.geometry as? SCNBox {
                geometry.width = CGFloat(planeAnchor.extent.x)
                geometry.length = CGFloat(planeAnchor.extent.z)
                let newShape = SCNBox(width: CGFloat(planeAnchor.extent.x)+1, height: 0.001, length: CGFloat(planeAnchor.extent.z)+1, chamferRadius: 0)
                existingPlane.physicsBody?.physicsShape = SCNPhysicsShape(geometry: newShape, options: nil)
            }
            existingPlane.position = SCNVector3Make(planeAnchor.center.x, -0.005, planeAnchor.center.z)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if cloudNode != nil {
            var spawnPoint: SCNVector3?
            
            if !isNegative{
                //let spawnPoint = SCNVector3Make((cloudNode?.position.x)! + Float(drand48()), (cloudNode?.position.y)!, cloudNode?.position.z + Float(drand48()))
                spawnPoint = SCNVector3Make((cloudNode?.position.x)!+(Float(drand48())-0.4), (cloudNode?.position.y)!, (cloudNode?.position.z)!+(Float(drand48())-0.4))
                isNegative = true
            }
            else{
                spawnPoint = SCNVector3Make((cloudNode?.position.x)!-(Float(drand48())-0.4), (cloudNode?.position.y)!, (cloudNode?.position.z)!-(Float(drand48())-0.4))
                isNegative = false
            }
            
            if time > spawnTime {
                DispatchQueue.main.async {
                    let nodeClone = self.selectedNode!.clone()
                    nodeClone.position = spawnPoint!
                    self.sceneView.scene.rootNode.addChildNode(nodeClone)
                    self.spawnTime = time + TimeInterval(0.35)
                }
                
            }
        }
    }
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
