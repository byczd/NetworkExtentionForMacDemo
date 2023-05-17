//
//  PacketTunnelProvider.m
//  VPNTunnel
//
//  Created by 黄龙 on 2023/5/12.
//

#import "PacketTunnelProvider.h"


#define TunnelMTU 1600

@implementation PacketTunnelProvider{
    void (^_pendingStartCompletion)(NSError *);
}

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    // Add code here to start the process of connecting the tunnel.
    NSLog(@"startTunnelWithOptions");
    [self startPacketForwarders];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code here to start the process of stopping the tunnel.
    completionHandler();
    NSLog(@"stopTunnelWithReason");
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    // Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    // Add code here to get ready to sleep.
    completionHandler();
}

- (void)wake {
    // Add code here to wake up.
}

#pragma mark - VPNConfig
- (void)startPacketForwarders {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTun2SocksFinished) name:kTun2SocksStoppedNotification object:nil];
    
    __weak typeof(self) weakSelf = self;
    [self applyTunnelSettings:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (error == nil) {
// NEProvider 中存在属性public var defaultPath: NWPath? { get } 表明当前系统的网络请求路径
// 故可以addObserver添加对defaultPath属性的监听，来得到例如发生 WiFi->4G 切换时的网络变化
// 在observeValueForKeyPath里处理监听到的状态改变
            [weakSelf addObserver:weakSelf forKeyPath:@"defaultPath" options:NSKeyValueObservingOptionInitial context:nil];
        }
        if (strongSelf->_pendingStartCompletion) {
            strongSelf->_pendingStartCompletion(error);
            strongSelf->_pendingStartCompletion = nil;//至此VPN创建成功OVER
        }
    }];
}

- (void) applyTunnelSettings:(void (^)(NSError *error))completionHandler {
//  这里是真正设置vpn tunnel 网络参数的地方，主控制器中设置的仅为系统vpn设置中的展示名称
//  首先新建一个NEPacketTunnelNetworkSettings对象，此对象是用来设置并建立vpn tunnel初始化对象
//  提供的RemoteAddress即为我们要建立连接的远程服务器的地址
    
//从配置中读取DNS
//    NSString *generalConfContent = [NSString stringWithContentsOfURL:[AppProfile sharedGeneralConfUrl] encoding:NSUTF8StringEncoding error:nil];
//    NSDictionary *generalConf = [generalConfContent jsonDictionary];
//    NSString *dns = generalConf[@"dns"];

//分配给TUN接口的IPv4地址(198.19.0.1为虚拟ip)和网络掩码
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
//@"192.0.2.1",对应VPN-Detail中显示的 “地址”, 可以随便填写"198.19.0.1"、"172.19.0.1"

//  includedRoutes：指定哪些IPv4网络流量的路由将被路由到TUN接口，即vpn tunnel需要拦截包的地址,如需全部拦截则设置[NEIPv4Route defaultRoute]
//  excludeRoute ： 设置不拦截哪些包的地址，不路由到tun，而是直接发给设备。
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]]; //全部拦截
// NEPacketTunnelNetworkSettings包含IP层隧道的IP网络设置
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"127.0.0.1"];
//@"192.0.2.2",对应VPN-Detail中显示的 “服务器地址” 198.19.0.2
    settings.IPv4Settings = ipv4Settings;
    settings.MTU = @(TunnelMTU); //MTU:最大传输单元,即每个packet最大的容量为1600,超出则会分包
    NEProxySettings* proxySettings = [[NEProxySettings alloc] init];
    NSInteger proxyServerPort = 8118;//8118端口通常用于Privoxy web代理软件
    NSString *proxyServerName = @"localhost";
    NSAssert(proxyServerPort > 0, @"proxyServerPort > 0");

    proxySettings.HTTPEnabled = YES;
    proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
    
    proxySettings.HTTPSEnabled = YES;
    proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:proxyServerPort];
    
    proxySettings.excludeSimpleHostnames = YES;
    settings.proxySettings = proxySettings;
    
    NSArray *dnsServers=@[@"8.8.8.8"];//简单点直接写死 //getSystemDnsServers(取系统设置的DNS)
    NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];

    dnsSettings.matchDomains = @[@""];// 包含域字符串的字符串数组。如果此属性为非nil，则DNS设置将仅用于解析指定域中的主机名。
// if blank don't use this DNS, use system; if "" then use this(  //如果空白不使用此DNS，请使用system；如果""，则使用此)

    settings.DNSSettings = dnsSettings;
    
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);//completionHandler(nil) 完成建立VPN连接
//  在设置网络参数成功后必须显式调用completionHandler(nil)才能正常建立连接(官方API要求)
        }
    }];
}

@end
