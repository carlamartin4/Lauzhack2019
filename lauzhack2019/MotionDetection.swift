//
//  MotionDetection.swift
//  Lauzhack
//
//  Created by carla martin on 16/11/2019.
//  Copyright © 2019 carla martin. All rights reserved.
//

import Foundation
import CoreMotion

class MotionDetection {
    let requester = Requester()
    let motion = CMMotionManager()
    var timer: Timer?
    public var previousx: Double
    public var previousy: Double
    public var previousz: Double
    public var x: Double
    public var y: Double
    public var z: Double
    public var status: String
    public var logged = false
    let threshold: Double = Double.pi / 6
    var thresholdz = 1.0
    init() {
        previousx = 0
        previousy = 0
        previousz = 0
        x = 0
        y = 0
        z = 0
        status =  "nn"
    }
    
    func login() {
        self.requester.login()
    }
    
    func logout() {
        self.requester.logout()
    }
    
    func startDeviceMotion() {
        if motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 1.5
            self.motion.showsDeviceMovementDisplay = true
            self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
            
            // Configure a timer to fetch the motion data.
            self.timer = Timer(fire: Date(), interval: 1.5, repeats: true,
                               block: { (timer) in
                                if let data = self.motion.deviceMotion {
                                    // Get the attitude relative to the magnetic north reference frame.
                                    
                                    if self.logged {
                                        self.previousx = Double(self.x)
                                        self.previousy = Double(self.y)
                                        self.previousz = Double(self.z)
                                        self.x = data.attitude.pitch
                                        self.y = data.attitude.roll
                                        self.z = data.attitude.yaw+3.14
                                        
                                        if(self.previousz == 0)
                                        {
                                            self.thresholdz = self.z + self.threshold
                                        }
                                        
                                        let isMobileUp = ((self.x - self.previousx) >= self.threshold) && (self.x >= self.threshold)
                                        let isMobileDown = ((self.x - self.previousx) <= -self.threshold) && (self.x <= -self.threshold)
                                        let isMobileRight = ((self.y - self.previousy) >= self.threshold) && (self.y >= self.threshold)
                                        let isMobileLeft = ((self.y - self.previousy) <= -self.threshold) && (self.y <= -self.threshold)
                                        let isMobileYawRight = ((self.z - self.previousz >= self.threshold))
                                        let isMobileYawLeft = ((self.z - self.previousz <= -self.threshold))
                                        
                                        if isMobileUp && isMobileRight
                                        {
                                            self.status = "fix waste"
                                            self.requester.fix()
                                        }
                                        else if isMobileUp && isMobileLeft
                                        {
                                            self.status = "reset"
                                            self.requester.reset()
                                        }
                                        else if isMobileDown && isMobileRight
                                        {
                                            self.status = "speed up"
                                            self.requester.speedup()
                                        }
                                        else if isMobileDown && isMobileLeft
                                        {
                                            self.status = "speed down"
                                            self.requester.speeddown()
                                        }
                                        else if isMobileUp
                                        {
                                            self.status = "feed feeder"
                                            self.requester.feedfeeder()
                                        }
                                        else if isMobileDown
                                        {
                                            self.status = "empty delivery"
                                            self.requester.emptyDelivery()
                                        }
                                        else if isMobileLeft
                                        {
                                            self.status = "stop feeder"
                                            self.requester.stopfeeder()
                                        }
                                        else if isMobileRight
                                        {
                                            self.status = "start feeder"
                                            self.requester.startfeeder()
                                        }
                                        /*if (self.z.sign != self.previousz.sign)
                                        {
                                            if(self.z.sign == FloatingPointSign.minus)
                                            {
                                                self.z = self.z + 2*Double.pi
                                                if isMobileYawRight
                                                {
                                                    self.status = "service 2"
                                                }
                                                
                                            }
                                            else
                                            {
                                                self.previousz = self.previousz + 2*Double.pi
                                                if isMobileYawRight
                                                {
                                                    self.status = "service 2"
                                                }
                                            }*/
                                        else if isMobileYawRight
                                        {
                                            self.status = "Service Ejector"
                                            self.requester.fixejector()
                                        }
                                        else if isMobileYawLeft
                                        {
                                            self.status = "Service Cutter"
                                            self.requester.fixcutter()
                                        }
                                        else {
                                            self.status = "No movement"
                                        }
                                    }
                                    else {
                                        self.status = "Login first"
                                    }
                                }
            })
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
        }
    }
}
