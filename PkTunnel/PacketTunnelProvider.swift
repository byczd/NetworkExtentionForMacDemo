//
//  PacketTunnelProvider.swift
//  PkTunnel
//
//  Created by 黄龙 on 2023/5/16.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {

    public var host: String = ""
    public var port: Int = 0
    public var name: String = ""
//    public var password: String = ""
    public var dns: String = ""
//    public var endtime: TimeInterval = 0
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Add code here to start the process of connecting the tunnel.
        guard let conf = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration else{
            NSLog("[错误]找不到协议配置")
            exit(EXIT_FAILURE)
        }
        
        self.host = conf["ss_host"] as! String
        self.port = conf["ss_port"] as! Int
        self.name = conf["ss_name"] as! String
//        self.password  = conf["ss_pwd"]  as! String
//        self.endtime   = conf["ss_time"] as! TimeInterval
        self.dns  = conf["ss_dns"]  as! String
        
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]//全部拦截
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: self.dns, subnetMask: "255.255.255.255")
        ] //不拦截哪些包的地址
        
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        networkSettings.ipv4Settings = ipv4Settings
        let DNSSettings = NEDNSSettings(servers: [self.dns])
        DNSSettings.matchDomains = [""]
        networkSettings.dnsSettings = DNSSettings
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: 8118)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: 8118)
        proxySettings.excludeSimpleHostnames = false
        proxySettings.matchDomains = [""]
        networkSettings.proxySettings = proxySettings
        
        setTunnelNetworkSettings(networkSettings) { error in
            guard error == nil else {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
        
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}
