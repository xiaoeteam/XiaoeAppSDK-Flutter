//
//  XEWebViewController.m
//  Pods-Runner
//
//  Created by page on 2019/12/16.
//

#import "XEWebViewController.h"
#import <XEShopSDK/XEShopSDK.h>


@interface XEWebViewController ()<XEWebViewDelegate, XEWebViewNoticeDelegate>

@property(nonatomic, strong) XEWebView *webView;

@property(nonatomic, strong) UIButton *backBtn;
@property(nonatomic, strong) UIButton *closeBtn;
@property(nonatomic, strong) UIButton *shareBtn;

@end

@implementation XEWebViewController

- (void)dealloc
{
    NSLog(@"XEWebViewController dealloc");
    _webView.noticeDelegate = nil;
    _webView.delegate = nil;
    _webView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUp];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareAction) name:@"webView_share" object:nil];
}


- (void)setUp {
    
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat navHeight = 64;
    if ([UIScreen mainScreen].bounds.size.height >= 812
        && [UIScreen mainScreen].bounds.size.height < 1024) {
        navHeight = 88;
    }
    
    CGFloat statusHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    
    // nav view
    _navView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, navHeight)];
    _navView.backgroundColor = _navViewColor;
    [self.view addSubview:_navView];
    
    
    NSBundle *bundle = [NSBundle bundleForClass:[XEWebViewController class]];
    NSString *bundlePath = [bundle pathForResource:@"xe_shop_sdk" ofType:@"bundle"];
    NSBundle *myBundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *imagePath = [myBundle pathForResource: [self getImageName:@"nav_icon_back"] ofType:@"png"];
    NSString *shareImagePath = [myBundle pathForResource:[self getImageName:@"nav_icon_share"] ofType:@"png"];
    NSString *closeImagePath = [myBundle pathForResource:[self getImageName:@"close"] ofType:@"png"];
    
    UIImage *backImage = [UIImage imageWithContentsOfFile:imagePath];
    UIImage *shareImage = [UIImage imageWithContentsOfFile:shareImagePath];
    UIImage *closeImage = [UIImage imageWithContentsOfFile:closeImagePath];
    
    // 读取 MainBundle 图片
    if (_backImageName.length > 0) {
        backImage = [UIImage imageNamed:_backImageName];
    }
    
    if (_shareImageName.length > 0) {
        shareImage = [UIImage imageNamed:_shareImageName];
    }
    
    if (_closeImageName.length > 0) {
        closeImage = [UIImage imageNamed:_closeImageName];
    }
    
    // back button
    _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, statusHeight, 44, 44)];
    _backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_backBtn setImage:backImage forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(backBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_navView addSubview:_backBtn];
    
    _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(15 + 44, statusHeight, 44, 44)];
    _closeBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_closeBtn setImage:closeImage forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(closeBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_navView addSubview:_closeBtn];
    
    // share button
    _shareBtn = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 15 - 44,  statusHeight, 44, 44)];
    _shareBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_shareBtn setImage:shareImage forState:UIControlStateNormal];
    [_shareBtn addTarget:self action:@selector(shareBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_navView addSubview:_shareBtn];
    
    // title
    UILabel *title = [[UILabel alloc] init];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = self.navTitle;
    title.textColor = _titleColor;
    title.frame = CGRectMake(80, statusHeight, [[UIScreen mainScreen] bounds].size.width - 160, 44);
    [_navView addSubview:title];
    
    CGRect webFrame = CGRectMake(0, navHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - navHeight);
    UIView *contentView = [[UIView alloc] initWithFrame:webFrame];
    [self.view addSubview:contentView];
    
    _webView = [[XEWebView alloc] initWithFrame:contentView.bounds webViewType:XEWebViewTypeWKWebView];
    _webView.delegate = self;
    _webView.noticeDelegate = self;
    [contentView addSubview:_webView];
    
    NSURL *requestUrl = [NSURL URLWithString:_url];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl];
    [_webView loadRequest:request];
}

-(NSString *)getImageName:(NSString *)imageName {
    
    NSString *name = imageName;
    if (UIScreen.mainScreen.scale == 2.0) {
        name = [[NSString alloc] initWithFormat:@"%@@2x", imageName];
    } else if (UIScreen.mainScreen.scale == 3.0) {
        name = [[NSString alloc] initWithFormat:@"%@@3x", imageName];
    }
    
    return name;
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (void)shareAction {
    [_webView share];
}

- (void) backBtnAction {
     if (_webView.canGoBack) {
         [_webView goBack];
     } else {
         [self dismissViewControllerAnimated:YES completion:nil];
     }
}

- (void) closeBtnAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

 - (void) shareBtnAction {
     [_webView share];
 }

 -(void) messagePost:(NSDictionary *)dict{
     
     __weak __typeof__(self) weakSelf = self;
     dispatch_async(dispatch_get_main_queue(), ^{
         [weakSelf.channel invokeMethod:@"ios" arguments:dict];
     });
 }

 #pragma mark - XEWebViewNotice Delegate

 - (void)webView:(id<XEWebView>)webView didReceiveNotice:(XENotice *)notice
 {
     
     switch (notice.type) {
         case XENoticeTypeLogin:
         {
             // 登录通知
             NSMutableDictionary *dict = [NSMutableDictionary dictionary];
             [dict setObject:[NSNumber numberWithInt:501] forKey:@"code"];
             [dict setObject:@"登录通知" forKey:@"message"];
             [dict setObject:@"" forKey:@"data"];
             
             [self messagePost:dict];
             
         }
             break;
         case XENoticeTypeShare:
         {
             // 接收到分享请求的结果回调
             NSMutableDictionary *dict = [NSMutableDictionary dictionary];
             NSDictionary *response = (NSDictionary *)notice.response;
             [dict setObject:[NSNumber numberWithInt:503] forKey:@"code"];
             [dict setObject:@"分享通知" forKey:@"message"];
             [dict setObject:response forKey:@"data"];
             [self messagePost:dict];
         }
             break;
         default:
             break;
     }
 }


 #pragma mark - XEWebViewDelegate Delegate (可选)

 - (BOOL)webView:(id<XEWebView>)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
 {
     return YES;
 }

 - (void)webViewDidStartLoad:(id<XEWebView>)webView
 {
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setObject:[NSNumber numberWithInt:401] forKey:@"code"];
     [dict setObject:@"开始加载" forKey:@"message"];
     [dict setObject:@"success" forKey:@"data"];
     
     [self messagePost:dict];
 }

 - (void)webViewDidFinishLoad:(id<XEWebView>)webView
 {
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setObject:[NSNumber numberWithInt:402] forKey:@"code"];
     [dict setObject:@"加载完成" forKey:@"message"];
     [dict setObject:@"success" forKey:@"data"];
     
     [self messagePost:dict];
 }

 - (void)webView:(id<XEWebView>)webView didFailLoadWithError:(NSError *)error
 {
     NSMutableDictionary *dict = [NSMutableDictionary dictionary];
     [dict setObject:[NSNumber numberWithInt:403] forKey:@"code"];
     [dict setObject:@"加载出错" forKey:@"message"];
     [dict setObject:@"error" forKey:@"data"];
     
     [self messagePost:dict];
 }


@end