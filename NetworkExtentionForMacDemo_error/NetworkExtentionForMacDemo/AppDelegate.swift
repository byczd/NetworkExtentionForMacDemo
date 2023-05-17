//
//  AppDelegate.swift
//  NetworkExtentionForMacDemo
//
//  Created by 黄龙 on 2023/5/10.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

//    @IBOutlet var window: NSWindow!
    private var mainWC: MainWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // Insert code here to initialize your application
        mainWC = MainWindowController.init("totoCloud")
//        MainWindowController(windowNibName: "MainWindowController")
        mainWC?.window?.center()
        mainWC?.window?.orderFront(nil)
        mainWC?.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

