//
//  WatchSessionManager.swift
//  WCApplicationContextDemo
//
//  Created by Natasha Murashev on 9/22/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity

public class WatchSessionManager: NSObject, WCSessionDelegate, SessionManagerType {
    @objc public static let sharedManager = WatchSessionManager()
    
    /// The store that the session manager should interact with.
    public var store: SiteStoreType?
    
    @objc let session: WCSession = WCSession.default
    
    private override init() {
        super.init()
    }
    
    deinit {
        stopSearching()
    }
    
    @objc public func startSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            
            #if DEBUG
                print("WCSession.isSupported: \(WCSession.isSupported()), Paired Phone Reachable: \(session.reachable)")
            #endif
            
            startSearching()
        }
    }
    
    private func startSearching() {
        if !WCSession.default.receivedApplicationContext.isEmpty {
            processApplicationContext(context: WCSession.default.receivedApplicationContext)
        }
    }
    
    @objc public func stopSearching() {
        session.delegate = nil
    }
    
    @available(watchOSApplicationExtension 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print(">>> Entering \(#function) <<<")
        print(session)
        print(activationState)
        print(error ?? "No error")
        
        if activationState == .activated {
            requestCompanionAppUpdate()
        }
    }
    
    @objc public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        print(">>> Entering \(#function) <<<")
        //print(": \(userInfo)")
        
        DispatchQueue.main.async {
            self.processApplicationContext(context: userInfo)
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(">>> Entering \(#function) <<<")
        //print("didReceiveApplicationContext: \(applicationContext)")
        DispatchQueue.main.async {
            self.processApplicationContext(context: applicationContext)
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(">>> Entering \(#function) <<<")
        DispatchQueue.main.async {
            let success =  self.processApplicationContext(context: message)
            replyHandler(["response" : "The message was procssed correctly: \(success)", "success": success])
        }
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        fatalError()
    }
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        fatalError()
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        fatalError()
    }
}

extension WatchSessionManager {
    // Sender
    @objc public func updateApplicationContext(_ applicationContext: [String : Any]) throws {
        #if DEBUG
            print(">>> Entering \(#function)<<")
        #endif
        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            throw error
        }
    }
}

extension WatchSessionManager {
    @objc @discardableResult
    func processApplicationContext(context: [String : Any]) -> Bool {
        print(">>> Entering \(#function) <<<")
        
        print("Did receive payload")
        
        guard let store = store else {
            print("No Store")
            return false
        }
        
        store.handleApplicationContextPayload(context)
        
               
        return true
    }
    
}

extension WatchSessionManager {
    @objc public func requestCompanionAppUpdate() {
        print(">>> Entering \(#function) <<<")
        
        let messageToSend = DefaultKey.payloadPhoneUpdate
        
        session.sendMessage(messageToSend, replyHandler: { (context:[String : Any]) in
            print("recievedMessageReply from iPhone")
            DispatchQueue.main.async {
                print("WatchSession success...")
                let success = self.processApplicationContext(context: context)
                print(success)
            }
            
        }) { (error) in
            print("WatchSession Transfer Error: \(error)")
            
            //self.processApplicationContext(context: DefaultKey.payloadPhoneUpdateError)
            
        }
    }
}
