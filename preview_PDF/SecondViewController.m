//
//  SecondViewController.m
//  preview_PDF
//
//  Created by 罗精灵 on 16/1/22.
//  Copyright © 2016年 luojingling. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()
{
    UIWebView *_webview;
}
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webview = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0,self.view.frame.size.width, self.view.frame.size.height)];
    _webview.delegate = self;
    _webview.scalesPageToFit = YES;
    _webview.detectsPhoneNumbers = YES;
//    webview.paginationBreakingMode = UIWebPaginationModeLeftToRight;
//    webview.pageLength = 1000;
    _webview.gapBetweenPages = 100;
    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.fileStr]]];
    [self.view addSubview:_webview];
    // Do any additional setup after loading the view.
}


#pragma mark -UIWebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
   
    NSLog(@"----%ld",(long)navigationType);
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"123 = %lu",(unsigned long)webView.pageCount);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"error = %@",error);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
