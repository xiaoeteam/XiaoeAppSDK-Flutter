import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xe_shop_sdk/xe_shop_sdk.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'dart:convert' show json;

class Example extends StatefulWidget {
  @override
  ExampleState createState() => ExampleState();
}

class ExampleState extends State<Example> {

  final GlobalKey globalKey = GlobalKey();

  //要显示的页面内容
  Widget childWidget;
  //加载Html的View
  XEWebView webView;
  //原生 发送给 Flutter 的消息
  String message = "--";

  // 页面
  String htmlUrl = "https://app38itOR341547.sdk.xiaoe-tech.com/";
  String clientId = "883pzzGyzynE72G";
  String appId = "app38itOR341547";

  @override
  void initState() {
    super.initState();
    XESDK.initConfig(clientId, appId);
  }

  void back() {
    webView.goBack();
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                back();
              },
              icon: Icon(Icons.arrow_back_ios),
            ),
            actions: <Widget>[
              IconButton(icon: new Icon(Icons.share), onPressed: (){
                webView.share();
              }),
              IconButton(icon: new Icon(Icons.refresh), onPressed: (){
                webView.reLoad();
              }),
            ],
            title: Text('Flutter Demo')
        ),
        body: Stack(
          children: <Widget>[
            Container(
              child: webView = XEWebView(
                url: htmlUrl,
                height: size.height - 100,
                //webview 加载信息回调
                callback: callBack,
              ),
            ),
          ],
        ),
      );
  }

  void callBack(data, type) {
    setState(() {
      if(type == XEWebViewType.Share){
        Fluttertoast.showToast(msg: data);
      } else if(type == XEWebViewType.Login){
        showLoginDialog();
      } else if (type == XEWebViewType.CanNotGoBack) {
        Navigator.pop(context);
      }
    });
  }

  //登录对话框
  void showLoginDialog(){
    TextEditingController _userNameController = new TextEditingController();
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text('登录'),
            content: TextField(
                controller: _userNameController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '请输入账号')),
            actions: <Widget>[
              FlatButton(
                child: Text('取消'),
                onPressed: (){
                  Navigator.of(context).pop();
                  webView.cancelLogin();
                },
              ),
              FlatButton(
                child: Text('登录'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if(_userNameController.text.toString().isEmpty){
                    Fluttertoast.showToast(msg: "请输入用户名！");
                    return;
                  }
                  BaseOptions options = new BaseOptions(
                      connectTimeout: 1000 * 10,
                      receiveTimeout: 1000 * 5,
                      responseType: ResponseType.plain
                  );
                  Response repsonse;
                  Dio dio = new Dio(options);

                  repsonse = await dio.get("http://api.xiaoe-tech.com/token",
                      queryParameters: {"app_id": "app38itOR341547",
                        "secret_key": "ak5JMM6Tt7ktzzPPeNvpCn0EI022HSvJ",
                        "grant_type": "client_credential"});
                  Map resultMap = json.decode(repsonse.data.toString());
                  String accessToken = resultMap["data"]["access_token"];

                  Response tokenResponse;
                  tokenResponse = await dio.post("http://api.xiaoe-tech.com/xe.sdk.account.login/1.0.0",
                      data: {"app_user_id": _userNameController.text.toString(), "access_token": accessToken, "sdk_app_id": "883pzzGyzynE72G"});
                  Map tokenMap = json.decode(tokenResponse.data.toString());
                  XESDK.synchronizeToken(tokenMap['data']['token_key'], tokenMap['data']['token_value']);
                },
              )
            ],
          );
        });
  }
}