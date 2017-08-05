//
//  InterfaceController.swift
//  WatchO WatchKit Extension
//
//  Created by Oliver Hickman on 4/24/17.
//  Copyright © 2017 Oliver Hickman. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    
    var counter = 0.0
    var timer: Timer!
    var session : WCSession!
    let motionManager = CMMotionManager ()
    var deviceMotion: CMDeviceMotion?
    
    var index = 0
    var data = Double()
    var chunkX = Array(repeating: 0.0, count: 25)
    var chunkY = Array(repeating: 0.0, count: 25)
    var chunkZ = Array(repeating: 0.0, count: 25)
    
    var chunkYaw = Array(repeating: 0.0, count: 25)
    var chunkPitch = Array(repeating: 0.0, count: 25)
    var chunkRoll = Array(repeating: 0.0, count: 25)
    
    var chunkData = [String : Array<Any>] ()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(InterfaceController.getDeviceMotion), userInfo: nil, repeats: true)
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        
        timer.invalidate()
        motionManager.stopDeviceMotionUpdates()
        
        super.didDeactivate()
        
    }
    
    
    func getDeviceMotion () {
        
        if let currentMotion = motionManager.deviceMotion {
            
            if index <= 24 {
                chunkY[index] = currentMotion.userAcceleration.y
                chunkX[index] = currentMotion.userAcceleration.x
                chunkZ[index] = currentMotion.userAcceleration.z
                
                chunkYaw[index] = currentMotion.attitude.yaw
                chunkPitch[index] = currentMotion.attitude.pitch
                chunkRoll[index] = currentMotion.attitude.roll

            }
            
            index += 1
            print(index)
            
            if index == 25 {
                prepareData()
                index = 0
            }
        }
    }
    func prepareData () {
        
        chunkData["accX"] = chunkX
        chunkData["accY"] = chunkY
        chunkData["accZ"] = chunkZ
        chunkData["gyroRoll"] = chunkRoll
        chunkData["gyroPitch"] = chunkPitch
        chunkData["gyroYaw"] = chunkYaw
        
        print(chunkData)
        sendTheData()
        
    }
    
    func sendTheData() {
        
        session.sendMessage(chunkData, replyHandler:  nil, errorHandler: { (error) -> Void in
            print("ERROR!!!!!!!!!!!")
        })
    }
    
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
}

