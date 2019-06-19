//
//  ViewController.m
//  iOSDemo
//
//  Created by zhangning on 2019/6/19.
//  Copyright © 2019 zhangning. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking/AFNetworking.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self httpsTest];
    // Do any additional setup after loading the view.
}


- (void)httpsTest
{
    /*
     *这种方式获取证书内容，AFN中SecCertificateCreateWithData函数有可能返回为nil引起crash
     *因为证书是已经用base64编码过的，这里需要解码后的data
     */
//    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"ca" ofType:@"cer"];
//    NSData* caCert = [NSData dataWithContentsOfFile:cerPath];
    

    //这里直接把证书内容复制过来
    NSString *httpskey = @"MIICOTCCAaICCQCtsd3SMUF5vTANBgkqhkiG9w0BAQUFADBhMQswCQYDVQQGEwJDTjESMBAGA1UECAwJR3VhbmdEb25nMREwDwYDVQQHDAhTaGVuWmhlbjENMAsGA1UECgwEeGxjdzENMAsGA1UECwwEeGxjdzENMAsGA1UEAwwEeGxjdzAeFw0xOTA2MTgwMjQ2MDhaFw0yMDA2MTcwMjQ2MDhaMGExCzAJBgNVBAYTAkNOMRIwEAYDVQQIDAlHdWFuZ0RvbmcxETAPBgNVBAcMCFNoZW5aaGVuMQ0wCwYDVQQKDAR4bGN3MQ0wCwYDVQQLDAR4bGN3MQ0wCwYDVQQDDAR4bGN3MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCyyDaN1ERc8i8tzF+kZ6/vMNV+slMe9S8N1s9kAvT3bUHibjUgSFBS/3qgx8SdP6fWg8Mmh1CVKzdzHFG1W1EHwyjEwifcwirbGeHfjS3H2YbMCYIPdOQ1mnzparB0dH5mKi6KDaubnkI5nbiK8RaC7tU+KeXMKYLJ/yHfuQeASwIDAQABMA0GCSqGSIb3DQEBBQUAA4GBAH8Rar0ZXFu4R0sb9L9H5e7m0YXBdrCzB/KsiHpRHK8I7FIZ6uAeXJNjN+Ifm+jLUJa+Nh3VpMCSLhir/qiimfpE4vBXVeJaCNDJjz6Cm7t7oEEKTcgjFTQ8X+TEW029Kr7LrSMKlxwG3nCG4PdJd94vc6pwS2Ans10yJMpkbCo2";
    
    //该字符串是已经base64编码过的，获取编码前的data
    NSData *certData = [[NSData alloc] initWithBase64EncodedString:httpskey options:0];
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
}
@end
