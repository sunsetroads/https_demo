### 使用自签名证书完成https认证

#### 1. https
简单来说，HTTPS就是HTTP协议上再加一层加密处理的SSL/TLS协议。相比HTTP，HTTPS可以保证内容在传输过程中不会被第三方查看、及时发现被第三方篡改的传输内容、防止身份冒充，从而更有效的保证网络数据的安全。

HTTPS客户端与服务器交互的基本流程：
1. 客户端第一次请求时，服务器会返回一个包含公钥的数字证书给客户端；
2. 客户端生成对称加密密钥并用其得到的公钥对其加密后返回给服务器；
3. 服务器使用自己私钥对收到的加密数据解密，得到对称加密密钥并保存；
4. 然后双方通过对称加密的数据进行传输。
#### 2. 数字签名
在HTTPS客户端与服务器第一次交互时，服务端返回给客户端的数字证书是让客户端验证这个数字证书是不是服务端的，证书所有者是不是该服务器，确保数据由正确的服务端发来，没有被第三方篡改。数字证书可以保证数字证书里的公钥确实是这个证书的所有者(Subject)的，或者证书可以用来确认对方身份。证书由公钥、证书主题(Subject)、数字签名(digital signature)等内容组成。其中数字签名就是证书的防伪标签，目前使用最广泛的SHA-RSA加密。

证书一般分为两种：
一种是向权威认证机构购买的证书，服务端使用该种证书时，因为苹果系统内置了其受信任的签名根证书，所以客户端不需额外的配置。为了证书安全，在证书发布机构公布证书时，证书的指纹算法都会加密后再和证书放到一起公布以防止他人伪造数字证书。而证书机构使用自己的私钥对其指纹算法加密，可以用内置在操作系统里的机构签名根证书来解密，以此保证证书的安全。
另一种是自己制作的证书，即自签名证书。好处是不需要花钱购买，但使用这种证书是不会受信任的，**客户端需要在代码中将该证书配置为信任证书**。
#### 3. 生成证书
使用openssl生成证书
```
# 1.生成私钥
$ openssl genrsa -out private.key 2048

# 2.生成 CSR (Certificate Signing Request)
$ openssl req -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=xlcw/OU=xlcw Software" -new -key server.key -out ca.csr

# 3.生成自签名证书
$ openssl x509 -req -days 3650 -in server.csr -signkey server.key -out ca.cer
```
#### 4. 服务端配置
引入系统的https模块即可（其它语言类似），也可以通过Nginx配置实现。以node.js为例：
```
const express = require('express')
const path = require('path')
const app = express()

//使用nodejs自带的http、https模块
var https = require('https');
var http = require('http');
var fs = require('fs');

//根据项目的路径导入生成的证书文件
var privateKey  = fs.readFileSync(path.join(__dirname, './certificate/private.pem'), 'utf8');
var certificate = fs.readFileSync(path.join(__dirname, './certificate/ca.cer'), 'utf8');
var credentials = {key: privateKey, cert: certificate};

//创建http与HTTPS服务器
var httpServer = http.createServer(app);
var httpsServer = https.createServer(credentials, app);

//分别设置http、https的访问端口号, https默认端口443，这样设置可以让接口同时支持http和https。
//不使用默认端口时可以通过nginx反向代理实现
var PORT = 80;
var SSLPORT = 443;

//创建http服务器
httpServer.listen(PORT, function() {
    console.log('HTTP Server is running on: http://localhost:%s', PORT);
});

//创建https服务器
httpsServer.listen(SSLPORT, function() {
    console.log('HTTPS Server is running on: https://localhost:%s', SSLPORT);
});
  
//根据请求判断是http还是https
app.get('/', function (req, res) {
    if(req.protocol === 'https') {
        res.status(200).send({
            message: 'This is https visit!',
        });
    }
    else {
        res.status(200).send({
            message: 'This is http visit!',
        });
    }
});
```
#### 5. 客户端配置
客户端需要将证书放在客户端内，与请求下来的服务端证书比对，防止类似于Charles类的软件抓包。
这里iOS 使用AFNetworking来发起请求，下面是配置信任自签名证书的过程
```
NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ca" ofType:@"cer"];
NSData* caCert = [NSData dataWithContentsOfFile:cerPath];
NSSet * certSet = [[NSSet alloc]initWithObjects:certData, nil];

/*
    *AFSecurityPolicy分三种验证模式：
    *AFSSLPinningModeNone:只是验证证书是否在信任列表中
    *AFSSLPinningModeCertificate：该模式会验证证书是否在信任列表中，然后再对比服务端证书和客户端证书是否一致
    *AFSSLPinningModePublicKey：只验证服务端证书与客户端证书的公钥是否一致
    */
AFSecurityPolicy *security = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
security.allowInvalidCertificates = YES;
security.validatesDomainName = NO;

NSURL *url = [NSURL URLWithString:@"https://127.0.0.1"];
AFHTTPSessionManager *manager = [[AFHTTPSessionManager manager] initWithBaseURL:url];
if ([url.scheme isEqualToString: @"https"]) {
    manager.securityPolicy = security;
}

[manager GET:@"/" parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    
} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
    NSLog(@"\n*********\n请求成功___%@\n************\n",responseObject);
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    
    NSLog(@"\n*********\n请求失败___%@\n************\n",error.localizedDescription);
}];
```
