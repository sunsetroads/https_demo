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

