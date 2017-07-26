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
    var objectsArrayFiles: [String] = [ "art.scnassets/pumpkin.scn", "art.scnassets/golden-mushroom.scn", "art.scnassets/money_stack.scn"]
    var objectsArrayNames: [String] = ["pumpkin", "Poly", "money_stack"]
    var planes = [String: SCNNode]()
    
    var isNegative = false
    var hasPlane = false
    
    let objectCategory:Int = 1 << 0
    let planeCategory:Int = 1 << 1
    let bottomCategory:Int = 1 << 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Make It Rain"
        
        // Set the view's delegate
        sceneView.delegate = self
        
        label = UILabel(frame: CGRect(x: 0, y: 0, width: 375, height: 72))
        label!.center = CGPoint(x: view.frame.size.width/2, y: 450)
        label!.textAlignment = .center
        label?.numberOfLines = 2
        label?.adjustsFontSizeToFitWidth = true
        label!.text = "Scan your surroundings to find a plane\n then tap the screen to make it rain"
        label?.textColor = UIColor.blue
        label?.font = UIFont(name: "SFText-Regular.otf", size: 18)
        
        label?.backgroundColor = UIColor(white: 1, alpha: 0.7)
        self.view.addSubview(label!)
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        //sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Cloud_3.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.scene.physicsWorld.gravity = SCNVector3Make(0.0, -4, 0.0)
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
        let subScene = SCNScene(named: objectsArrayFiles[itemNum])!
        objectNode = subScene.rootNode.childNode(withName: objectsArrayNames[itemNum], recursively: true)!
        if itemNum == 0 {
            objectNode.scale.x = 0.01
            objectNode.scale.y = 0.01
            objectNode.scale.z = 0.01
        }
        else if itemNum == 1 {
            objectNode.scale.x = 0.025
            objectNode.scale.y = 0.025
            objectNode.scale.z = 0.025
        }
        else {
            objectNode.scale.x = 1.3
            objectNode.scale.y = 1.3
            objectNode.scale.z = 1.3
        }
        
        if itemNum == 2{
            let moneyShape =  SCNBox(width: 0.2, height: 0.1, length: 0.02, chamferRadius: 0)
            let moneyPhysicsShape = SCNPhysicsShape(geometry: moneyShape, options: nil)
            objectNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: moneyPhysicsShape)
        }
        else{
            objectNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        }
        
        objectNode.physicsBody?.categoryBitMask = objectCategory
        objectNode.physicsBody!.collisionBitMask = planeCategory | objectCategory
        objectNode.physicsBody!.contactTestBitMask = planeCategory
        
        let bottomPlane = SCNBox(width: 1000, height: 0.05, length: 1000, chamferRadius: 0)
        
        // Use a clear material so the body is not visible
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [material]
        
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: -3, z: 0)
        
        let physicsBody = SCNPhysicsBody.static()
        physicsBody.categoryBitMask = bottomCategory
        physicsBody.contactTestBitMask = objectCategory
        bottomNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
        
        self.selectedNode = objectNode
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "art.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
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
                                         1,
                                         hitTransform.m43)
        
        spawnRainCloud(hitPosition: hitPosition)
    }
    
    func spawnRainCloud(hitPosition: SCNVector3){
        if cloudNode != nil {
            cloudNode?.removeFromParentNode()
        }
        let subScene = SCNScene(named: "art.scnassets/Cloud_3.scn")!
        cloudNode = subScene.rootNode.childNode(withName: "Cloud_3", recursively: true)
        cloudNode?.position = hitPosition
        cloudNode?.scale.x = 0.2
        cloudNode?.scale.y = 0.2
        cloudNode?.scale.z = 0.2
        
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
        
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x), height: 0.01, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0)
        
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
                let newShape = SCNBox(width: CGFloat(planeAnchor.extent.x)+0.25, height: 0.01, length: CGFloat(planeAnchor.extent.z)+0.25, chamferRadius: 0)
                existingPlane.physicsBody?.physicsShape = SCNPhysicsShape(geometry: newShape, options: nil)
            }
            existingPlane.position = SCNVector3Make(planeAnchor.center.x, -0.005, planeAnchor.center.z)
        }
    }
    
    /*
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
    */
    
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
                    //nodeClone.orientation = SCNQuaternion(1, 1, 1, Double(Float.pi)-drand48())
                    nodeClone.eulerAngles = SCNVector3Make(Float.pi-Float(drand48()), Float.pi-Float(drand48()), Float.pi-Float(drand48()))
                    self.sceneView.scene.rootNode.addChildNode(nodeClone)
                    self.spawnTime = time + TimeInterval(0.1)
                }
                
            }
        }
        
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
}
