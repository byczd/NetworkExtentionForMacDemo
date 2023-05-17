//
//  MainWC.swift
//  macNEDemo
//
//  Created by 黄龙 on 2023/5/16.
//

import Cocoa

class MainWC: NSWindowController {
    
    let mainVC = MainVC()
    
    convenience init(_ title:String){
        self.init(windowNibName: "MainWC")
        self.window?.title = title
        self.window?.windowController = self
        self.window?.isRestorable = false//窗口不可拉伸
        self.window?.titlebarAppearsTransparent = true
//        self.window?.titleVisibility = .hidden
        self.window?.isMovableByWindowBackground = true//可移动背景
        self.window?.styleMask = [.titled,.miniaturizable,.fullSizeContentView]//.titled,.closable,.resizable,  .miniaturizable,
        //.titled有这个窗口为带阴影效果的圆角窗口，没有则为无阴影方形窗口(此时系统最小化、关闭等按钮也不会显示)
        //.miniaturizable需得有这个，不然不能通过代码最小化窗口
        self.window?.standardWindowButton(.closeButton)?.isHidden = true //不需要
        self.window?.standardWindowButton(.zoomButton)?.isHidden = true //不需要
        self.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //不需要，隐藏，改由自定义按钮来实现最小化
        self.window?.minSize = NSMakeSize(480, 320)
        self.contentViewController = mainVC
        mainVC.windowController = self
    }
    
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        
        
    }
    
}
