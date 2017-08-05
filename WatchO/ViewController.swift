//
//  ViewController.swift
//  WatchO
//
//  Created by Oliver Hickman on 4/24/17.
//  Copyright © 2017 Oliver Hickman. All rights reserved.
//

import UIKit
import WatchConnectivity


class ViewController: UIViewController, WCSessionDelegate, UITextFieldDelegate, F53OSCPacketDestination {
    
    //----------DO NOT DELETE! NEEDED FOR F53OSCPacketDestination!----------//
    func take(_ message: F53OSCMessage!) {
    }
    //----------------------------------------------------------------------//
    
    let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    var oscServer: F53OSCServer!
    var oscClient: F53OSCClient!
    var messageString: String!
    var timer: Timer!
    var i: Int = 0
    
    @IBOutlet weak var ipAddress: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("App Launched")
        
//        print("Starting OSC Server")
//        oscServer = F53OSCServer.init()
//        oscServer.port = 3030
//        oscServer.delegate = self
//        
//        oscClient = F53OSCClient.init()
//        oscClient.host = "172.16.3.40"
//        oscClient.port = 3000
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        session?.delegate = self;
        session?.activate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        becomeFirstResponder()
    }
    
    @IBAction func startServer(sender: AnyObject) {
        print("Starting OSC Server")
        oscServer = F53OSCServer.init()
        oscServer.port = 3030
        oscServer.delegate = self
        
        oscClient = F53OSCClient.init()
        oscClient.host = ipAddress.text
        oscClient.port = 3000
        
        ipAddress.resignFirstResponder()
        
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    {
        print(activationState.rawValue)
        
    }
    
    var unwrappedWatchMessageX = [Double!]()
    var unwrappedWatchMessageY = [Double!]()
    var unwrappedWatchMessageZ = [Double!]()
    
    var unwrappedWatchMessageRoll = [Double!]()
    var unwrappedWatchMessagePitch = [Double!]()
    var unwrappedWatchMessageYaw = [Double!]()
    var temp: String = ""
    var watchMessage = Dictionary<String, Any>()
    
    
    // watch to phone communication
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) -> Void {
        watchMessage = message
        unwrap()
        print ("NEW MESSAGE!")
    }
    
    func unwrap() {
        
        if watchMessage.isEmpty {
            print("EMPTY")
        } else {
            unwrappedWatchMessageX = watchMessage["accX"] as! [Double?]
            unwrappedWatchMessageY = watchMessage ["accY"] as! [Double?]
            unwrappedWatchMessageZ = watchMessage ["accZ"] as! [Double?]
            
            unwrappedWatchMessagePitch = watchMessage ["gyroPitch"] as! [Double?]
            unwrappedWatchMessageRoll = watchMessage ["gyroRoll"] as! [Double?]
            unwrappedWatchMessageYaw = watchMessage ["gyroYaw"] as! [Double?]
            
            startTimer()
            i = 0
            //print(watchMessage)
            //print("index", i)
        }
        
    }
    
    func startTimer() {
        guard timer == nil else { return }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 0.0475, target: self, selector: #selector(self.formatAndSendOSC), userInfo: nil, repeats: true)
        }
        
    }
    
    func stopTimer() {
        guard timer != nil else { return }
        timer?.invalidate()
        timer = nil
    }
    
    
    func formatAndSendOSC () {
        //print("YOOOO")
        if unwrappedWatchMessageX.isEmpty != true && i <= 24 {
            
            let oscAccX = unwrappedWatchMessageX[i]
            let oscAccY = unwrappedWatchMessageY[i]
            let oscAccZ = unwrappedWatchMessageZ[i]

            let oscGyroRoll = unwrappedWatchMessageRoll[i]
            let oscGyroPitch = unwrappedWatchMessagePitch[i]
            let oscGyroYaw = unwrappedWatchMessageYaw[i]
            
            print(oscAccX!, oscAccY!, oscAccZ!, oscGyroRoll!, oscGyroPitch!, oscGyroYaw!)

            sendMessage(oscClient, addressPattern: "/acc", arguments: [oscAccX!, oscAccY!, oscAccZ!])

            sendMessage(oscClient, addressPattern: "/gyro", arguments: [oscGyroRoll!, oscGyroPitch!, oscGyroYaw!])
            
            i += 1
                   }
    }
    
    func sendMessage(_ client: F53OSCClient, addressPattern: String, arguments: [Double]) {
        let message = F53OSCMessage(addressPattern: addressPattern, arguments: arguments)
        client.send(message)
        
    }
    
    
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
}
