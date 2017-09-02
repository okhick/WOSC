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
import HealthKit

class
InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, WCSessionDelegate { //HKWorkoutSessionDelegate
    
    
    @IBOutlet var workoutLabel: WKInterfaceButton!;
    
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
    
    //HEALTHKIT=========================
    let healthStore = HKHealthStore()
    var workoutSesh : HKWorkoutSession?
    var inMotion = false;
    //==================================
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        
        //MORE HEALTHKIT================
        guard HKHealthStore.isHealthDataAvailable() == true else { //err checking/handling
            return
        }

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        
        super.didDeactivate()
        
    }
    
    func fire () {
        
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(InterfaceController.getDeviceMotion), userInfo: nil, repeats: true)
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
            //print(index)
            
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
    
    //================BELOW IS HEALTHKIT WORKAROUND================
    //adapted from https://github.com/pubnub/swift-apple-watch-heart-rate-pubnub-eon/blob/master/README.md
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
            print("something")
        case .ended:
            workoutDidEnd(date)
            print("somethingElse")
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("ERROR!!!!!!!!!!")
    }
    
    func workoutDidStart(_ date : Date) {
        print("started")
    }
    
    func workoutDidEnd(_ date : Date) {
        print("stopped")
    }
    
    @IBAction func beginWorkout() {
        if (inMotion == false) {
            
//            ==========This is the current way of doing things as of August 2017. However it throwns a fatal error when ending the workout.============
//
//            let configuration = HKWorkoutConfiguration()
//                configuration.activityType = .walking
//                configuration.locationType = .unknown
//
//            do {
//                let workoutSesh = try HKWorkoutSession(configuration: configuration)
//
//                workoutSesh.delegate = self
//                healthStore.start(workoutSesh)
//            }
//            catch let error as NSError {
//                // Perform proper error handling here...
//                fatalError("*** Unable to create the workout session: \(error.localizedDescription) ***")
//            }

//          This is old but works
            self.workoutSesh = HKWorkoutSession(activityType: HKWorkoutActivityType.crossTraining,   locationType: HKWorkoutSessionLocationType.indoor)
            self.workoutSesh?.delegate = self
            healthStore.start(self.workoutSesh!)
            
            fire() //!!!!!
            
            inMotion = true;
            workoutLabel.setTitle("STOP")
        }
        else {
            healthStore.end(workoutSesh!);
            timer.invalidate();
            motionManager.stopDeviceMotionUpdates();
            inMotion = false;
            workoutLabel.setTitle("START");
        }
    }
    
    //=======================================
    
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    }

