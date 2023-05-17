//
//  TotoVpnManager.swift
//  NetworkExtentionForMacDemo
//
//  Created by 黄龙 on 2023/5/10.
//


import Cocoa
//import MMWormhole
import NetworkExtension


public enum VPNStatus {
    case off
    case connecting
    case on
    case disconnecting
}

public enum ManagerError: Error {
    case invalidProvider
    case vpnStartFail
}

public let kProxyServiceVPNStatusNotification = "kProxyServiceVPNStatusNotification"

class TotoVpnManager{
    public var host: String = ""
    public var port: Int = 0
    public var name: String = ""
    public var password: String = ""
    public var dns: String = ""
    public var endtime: TimeInterval = 0
    
    public static let sharedManager = TotoVpnManager()
    
//vpn状态变量
    open fileprivate(set) var vpnStatus = VPNStatus.off {
        didSet {
//每次设置该变量值时进行通知
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
        }
    }
    var observerAdded: Bool = false //vpnstate观察是否添加
    
//MMWormhole 是 iOS 扩展与宿主应用的通讯框架,在 iOS扩展与其包含的应用程序之间建立了桥梁。用于在两个位置之间来回传递数据或命令。
//   public let wormhole = MMWormhole(applicationGroupIdentifier: "group.adong.mac.TotoCloud", optionalDirectory: "wormhole")

    fileprivate init() {
        loadProviderManager { (manager) -> Void in
            if let manager = manager {
                self.updateVPNStatus(manager)
            }
        }
        addVPNStatusObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addVPNStatusObserver() {
        guard !observerAdded else{
            return
        }
        loadProviderManager { [unowned self] (manager) -> Void in
            if let manager = manager {
                self.observerAdded = true
//  可以通过NEVPNStatusDidChangeNotification通知来获取当前VPN的状态。
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main, using: { [unowned self] (notification) -> Void in
                    NSLog("NEVPNStatusDidChange[\(manager.connection.status.rawValue)]")
                    //invalid=0,Disconnected=1,connecting=2,connected=3,disconnecting=5
                    self.updateVPNStatus(manager)
                })
            }
        }
    }
    
    func updateVPNStatus(_ manager: NEVPNManager) {
        switch manager.connection.status {
        case .connected:
            self.vpnStatus = .on
        case .connecting, .reasserting:
            self.vpnStatus = .connecting
        case .disconnecting:
            self.vpnStatus = .disconnecting
        case .disconnected:
            self.vpnStatus = .off
        default: //.invalid
            self.vpnStatus = .off
        }
    }
    
    open func switchVPN(_ completion: ((NETunnelProviderManager?, Error?) -> Void)? = nil) {
        loadProviderManager { [unowned self] (manager) in
            if let manager = manager {
                self.updateVPNStatus(manager)
            }
            let current = self.vpnStatus
            guard current != .connecting && current != .disconnecting else {
                return
            } //只要不是off都关闭会怎么样
            if current == .off {
                self.host = "42.157.195.235" //
                self.port = 12127 //12127
                self.name = "1308977:2b4tcU" //1308977:2b4tcU
                self.dns = "8.8.8.8"
                self.password = "68xdgu9eyif" //68xdgu9eyif
                self.endtime  = 1687090004
                self.startVPN([:]) { (manager, error) -> Void in
                    completion?(manager, error)
                }
            }else {
                self.stopVPN()
                completion?(nil, nil)
            }
        }
    }
    
}


extension TotoVpnManager {
    public func stopVPN() {
        // Stop provider
        loadProviderManager { (manager) -> Void in
            guard let manager = manager else {
                return
            }
//stopVPNTunnel关闭VPN通道
            manager.connection.stopVPNTunnel()
        }
    }
    
    public func startVPN(_ options: [String : NSObject]?, complete: ((NETunnelProviderManager?, Error?) -> Void)? = nil) {
        // Load provider
        loadAndCreateProviderManager { (manager, error) -> Void in
            if let error = error {
                complete?(nil, error)
            }else{
                guard let manager = manager else {
                    complete?(nil, ManagerError.invalidProvider)
                    return
                }
                self.addVPNStatusObserver()
                
                if manager.connection.status == .disconnected || manager.connection.status == .invalid {
                    do {
//要拦截流量，需要主App启动Network Extension进程，
//即通过调用NETunnelProviderManager对象tunnel的tunnel.connection.startVPNTunnel()方法。开启VPN通道
                        try manager.connection.startVPNTunnel(options: options)
                        complete?(manager, nil)
                    }catch {
                        complete?(nil, error)
                    }
                }else{
                    self.addVPNStatusObserver()
                    complete?(manager, nil)
                }
            }
        }
    }
    
    
    fileprivate func createProviderManager() -> NETunnelProviderManager {
//        let manager = NETunnelProviderManager()
//        let tunnelProtocol = NETunnelProviderProtocol()
//        tunnelProtocol.username = "NEMacDemo"
//        tunnelProtocol.serverAddress = "127.0.0.1"
//        tunnelProtocol.providerBundleIdentifier = "com.adong.iOS.swift.NetworkExtentionForMacDemo.VPNTunnel"
        // bundle id of the network extension target
//        var configData:Data = Data.init()
//        tunnelProtocol.providerConfiguration = ["ovpn": configData]
//        manager.protocolConfiguration =  tunnelProtocol
//        manager.protocolConfiguration = NETunnelProviderProtocol()
//        return manager
        
        let manager = NETunnelProviderManager()
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.serverAddress = "127.0.0.1"
        tunnelProtocol.providerBundleIdentifier = "com.adong.iOS.swift.NetworkExtentionForMacDemo.VPNTunnel"
        manager.protocolConfiguration = tunnelProtocol
        manager.localizedDescription = "我爱一条柴"
        return manager
        
    }
    
    
    public func loadProviderManager(_ complete: @escaping (NETunnelProviderManager?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) -> Void in
            if let managers = managers {//最终VPN能否开启成功
                if managers.count > 0 {
                    let manager = managers[0]
                    complete(manager)
                    return
                }
            }
            complete(nil)
        }
    }
    
    fileprivate func loadAndCreateProviderManager(_ complete: @escaping (NETunnelProviderManager?, Error?) -> Void ) {
        NETunnelProviderManager.loadAllFromPreferences { [unowned self] (managers, error) -> Void in
// NETunnelProviderManager.loadAllFromPreferences,读取manager配置，
// saveToPreferences如果调用多次，会出现VPN 1 VPN 2等多个描述文件，故苹果要求，在创建前应读取当前的managers。
// 而loadAllFromPreferences获取，第一次肯定是nil，
            
            if let managers = managers {
                let manager: NETunnelProviderManager
                if managers.count > 0 {
                    manager = managers[0]
                    self.delDupConfig(managers)
                }else{
                    manager = self.createProviderManager()
                }
                manager.isEnabled = true
                self.setRulerConfig(manager)
                
//                manager.localizedDescription = "我爱一条柴" //
                // 对应系统设置项：VPN应用程序，可以写成如： "我爱一条柴"
//                manager.protocolConfiguration?.serverAddress = "127.0.0.1" //AppEnv.appName
                // 对应系统设置项：服务器地址，可以写成如："上山打老虎"
//                manager.protocolConfiguration?.username = "NEMacDemo"
                //对应系统设置项：账户名称
//                let tunnelPro = manager.protocolConfiguration as! NETunnelProviderProtocol
//                tunnelPro.providerBundleIdentifier = "com.adong.iOS.swift.NetworkExtentionForMacDemo.VPNTunnel"
//                //用于macOS，需要配置bundleIdentifier(没加之前是2>1, 加此后5>1)
                
//                if #available(macOS 10.15, *) {
//                    manager.protocolConfiguration?.excludeLocalNetworks = true
//                } else {
//                    // Fallback on earlier versions
//                }
                
//Thank you so much, saving twice working for me!
//I had problem only on the first app start.
//Bun when i try to saveToPreferencesWithCompletionHandler twice VPN start connecting!
//twice for me not effective,fuck!
                
                manager.saveToPreferences(completionHandler: { (error) -> Void in
// saveToPreferences将manager保存至系统中, 如果saveToPreferences方法调用多次，会出现VPN 1 VPN 2等多个描述文件
                    if let error = error {
                        complete(nil, error)
                    }else{
                        manager.loadFromPreferences(completionHandler: { (error) -> Void in
                            if let error = error {
                                print(error.localizedDescription.debugDescription)
                                complete(nil, error)
                            }else{
                                complete(manager, nil)
                            }
                        })
                    }
                })
                
            }else{
                complete(nil, error)
            }
        }
    }
    
    func delDupConfig(_ arrays:[NETunnelProviderManager]){
        if (arrays.count)>1{
            for i in 0 ..< arrays.count{
                arrays[i].removeFromPreferences(completionHandler: { (error) in
                    if(error != nil){print(error.debugDescription)}
                })
            }
        }
    }
    
    
}

extension TotoVpnManager{
    
    fileprivate func setRulerConfig(_ manager:NETunnelProviderManager){
        
        var conf = [String:AnyObject]()
        conf["ss_host"] = host as AnyObject?
        conf["ss_port"] = port as AnyObject?
        conf["ss_name"] = name as AnyObject?
        conf["ss_dns"]  = dns  as AnyObject?
        conf["ss_time"] = endtime as AnyObject?
        conf["ss_pwd"]  = password as AnyObject?
        let orignConf = manager.protocolConfiguration as! NETunnelProviderProtocol
        orignConf.providerConfiguration = conf
        manager.protocolConfiguration = orignConf
    }
}
