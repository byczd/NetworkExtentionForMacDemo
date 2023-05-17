//
//  NodesInfoVC.swift
//  NetworkExtentionForMacDemo
//
//  Created by 黄龙 on 2023/5/10.
//

import Cocoa

class NodesInfoVC: NSViewController {
    open var windowController: NSWindowController?
    
    override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
        //only-one: view的大小才是真正的初始后的window大小
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        let startBtn = NSButton(title: "启动VPN", target: self, action: #selector(onTapButton(sender:)))
        view.addSubview(startBtn)
        startBtn.frame = CGRect(x: 100, y: 320 - 100, width: 100, height: 45)
        startBtn.tag = 1000
        startBtn.isBordered = false
        startBtn.contentTintColor = NSColor.green
        startBtn.font = NSFont.systemFont(ofSize: 16)
        startBtn.wantsLayer = true
        startBtn.layer?.cornerRadius = 10
        startBtn.layer?.borderWidth = 1
        startBtn.layer?.borderColor = NSColor.green.cgColor
    }
    
    @objc func onTapButton(sender:NSButton){
//启动VPN
        TotoVpnManager.sharedManager.switchVPN { (manager, error) in
            NSLog("\(error)")
        }
    }
    
    
    
}
