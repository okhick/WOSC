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
    
    
    //HEALTHKIT-----------------
    @IBOutlet private weak var label: WKInterfaceLabel!
    @IBOutlet private weak var deviceLabel : WKInterfaceLabel!
    @IBOutlet private weak var heart: WKInterfaceImage!
    @IBOutlet private weak var startStopButton : WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var workoutSession : HKWorkoutSession?
    //let heartRateUnit = HKUnit(from: "count/min")
    //var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    //END HEALTHKIT-------------
    
    
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
        
        
        //MORE HEALTHKIT
        guard HKHealthStore.isHealthDataAvailable() == true else {
            //label.setText("not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            //print("ERROR")
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                print("ERROR")
            }
        }
        //END MORE HEALTHKIT
 
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
    
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    

    //------------------BELOW IS HEALTHKIT WORKAROUND------------------
    //https://github.com/coolioxlr/watchOS-2-heartrate/blob/master/VimoHeartRate%20WatchKit%20App%20Extension/InterfaceController.swift
    
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        //switch toState {
        //case .running:
        //    workoutDidStart(date: date as NSDate)
        //case .ended:
        //    workoutDidEnd(date: date as NSDate)
        //default:
        //    print("Unexpected state \(toState)")
        //}
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        NSLog("Workout error: \(String(describing: error._userInfo))")
    }
    /*
    func workoutDidStart(date : NSDate) {
        if let query = createHeartRateStreamingQuery(workoutStartDate: date) {
            healthStore.execute(query)
        } else {
            label.setText("cannot start")
        }
    }
    
    func workoutDidEnd(date : NSDate) {
            label.setText("---")
         else {
            label.setText("cannot stop")
        }
    }
    */
    // MARK: - Actions
    @IBAction func startBtnTapped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            self.startStopButton.setTitle("Start")
            if let workout = self.workoutSession {
                healthStore.end(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            self.startStopButton.setTitle("Stop")
            startWorkout()
        }
        
    }
    
    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.walking, locationType: HKWorkoutSessionLocationType.indoor)
        self.workoutSession?.delegate = self
        healthStore.start(self.workoutSession!)
    }
    /*
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(samples: sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples: samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async() {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            self.label.setText(String(UInt16(value)))
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            self.updateDeviceName(deviceName: name)
            //self.animateHeart()
        }
    }
    
    func updateDeviceName(deviceName: String) {
        deviceLabel.setText(deviceName)
    }
*/
}

