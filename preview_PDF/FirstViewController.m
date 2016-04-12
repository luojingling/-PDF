//
//  FirstViewController.m
//  preview_PDF
//
//  Created by 罗精灵 on 16/1/22.
//  Copyright © 2016年 luojingling. All rights reserved.
//

#import "FirstViewController.h"
#import "SecondViewController.h"
#import "DirectoryWatcher.h"
#import "ThreeViewController.h"
@interface FirstViewController ()<QLPreviewControllerDataSource,QLPreviewControllerDelegate,UIDocumentInteractionControllerDelegate,DirectoryWatcherDelegate,NSURLSessionDownloadDelegate>
{
    UIImageView *_imageView;
    UIProgressView *_myPregress;
    UILabel *_pgLabel;
    
}

@property (nonatomic,strong) DirectoryWatcher *docWatcher;
@property (nonatomic,strong) NSArray *documents;
@property (nonatomic,strong) UIDocumentInteractionController *docInteractionController;

//下载任务
@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;
//记录下载位置
@property (nonatomic,strong) NSData *resumeData;
//session
@property (nonatomic,strong) NSURLSession *session;
//下载文件的本地路径
//@property (nonatomic,strong) NSString * localFilePath;
@property (nonatomic,strong) NSString * downloadedLocalFilePath;
@property (nonatomic,assign) int currentButtonTag;
//@property (nonatomic,strong) NSString *pdfFilePath;

@end

@implementation FirstViewController

//session的懒加载
- (NSURLSession *)session {
    if (nil == _session) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    return _session;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"主页";
    _documents = [NSArray arrayWithObjects:@"http://192.168.1.152/test.ppt",@"http://192.168.1.152/Reader.pdf", nil];
    NSLog(@"sandbox:%@",NSHomeDirectory());

    NSURL *url = [NSURL URLWithString:@"https://picjumbo.imgix.net/HNCK8461.jpg?q=40&w=1650&sharp=30"];
   
    _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    _imageView.backgroundColor = [UIColor orangeColor];
    _imageView.userInteractionEnabled = YES;
    [self.view addSubview:_imageView];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(100,230, _imageView.bounds.size.width + 150, 40)];
    button.backgroundColor = [UIColor grayColor];
    button.tag = 0;
    [button setTitle:@"点击下载后可复制粘贴" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageTapAction:)];
    [_imageView addGestureRecognizer:tap];
    
    [self downloadImageWithUrl:url];
    
    
    
    _myPregress = [[UIProgressView alloc]initWithFrame:CGRectMake(100, 215, 100, 5)];
    _myPregress.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:_myPregress];
    
    _pgLabel = [[UILabel alloc]initWithFrame:CGRectMake(210,200, 200, 30)];
    _pgLabel.backgroundColor = [UIColor clearColor];
    _pgLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:_pgLabel];
    
    
    UIImageView *pdfImageView = [[UIImageView alloc]initWithFrame:CGRectMake(100, 350, 100, 100)];
    pdfImageView.backgroundColor = [UIColor cyanColor];
    pdfImageView.userInteractionEnabled = YES;
    [self.view addSubview:pdfImageView];
    NSString *pdfImageStr = @"http://192.168.1.137:81/upload/projects/0/3/logo.3.1.jpg";
    NSData *pdfImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:pdfImageStr]];
    UIImage *pdfImage = [UIImage imageWithData:pdfImageData];
    pdfImageView.image = pdfImage;
    
    UIButton *pdfButton = [UIButton buttonWithType:UIButtonTypeCustom];
    pdfButton.frame = CGRectMake(100,460, _imageView.bounds.size.width + 150, 40);
    pdfButton.backgroundColor = [UIColor grayColor];
    pdfButton.tag = 1;
    [pdfButton setTitle:@"点击下载后可复制粘贴" forState:UIControlStateNormal];
    [pdfButton addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pdfButton];
    
    UITapGestureRecognizer *pdfTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(pdfTapAction:)];
    [pdfImageView addGestureRecognizer:pdfTap];
    
    
    self.docWatcher = [DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] delegate:self];
    [self directoryDidChange:self.docWatcher];
    // Do any additional setup after loading the view.
}

- (void)pdfTapAction:(UIGestureRecognizer *)tap {

    
    NSURL *fileURL;
    _currentButtonTag = 1;

    if ([self isFileExisit]) {
        fileURL = [NSURL URLWithString:_downloadedLocalFilePath];
    }
    
    [self setupDocumentControllerWithURL:fileURL];

    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    previewController.delegate = self;
    
   
    [[self navigationController] pushViewController:previewController animated:YES];
}

- (void)viewDidUnload
{
    self.docWatcher = nil;
}

- (void)gotoCopy:(NSURL *)fileURL {
        
    [self setupDocumentControllerWithURL:fileURL];
    
    //显示拷贝
    self.docInteractionController.URL = fileURL;
    
    [self.docInteractionController presentOptionsMenuFromRect:self.view.bounds
                                                       inView:self.view
                                                     animated:YES];
    
    
   

}

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    //checks if docInteractionController has been initialized with the URL
    if (self.docInteractionController == nil)
    {
        
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
    
}


- (void)btnClicked:(UIButton *)sender {
    _currentButtonTag = [[NSString stringWithFormat:@"%ld",(long)sender.tag] intValue];
    
        BOOL isExisit = [self isFileExisit];
        if (isExisit) {
            NSLog(@"该文件已存在！");
            
            NSURL *url = [NSURL URLWithString:_downloadedLocalFilePath];
            [ self gotoCopy:url];
            //移除沙盒存在的PDF文件
            //        NSFileManager *fileManage = [[NSFileManager alloc]init];
            //        [fileManage removeItemAtPath:_path error:nil];
        } else {
            NSLog(@"不存在该文件！");
            sender.selected = !sender.isSelected;
            if (nil == self.downloadTask) {
                if (self.resumeData) {
                    [self resume];
                } else {
                    [self startDownload];
                }
            } else {
                [self pause];
            }
        }
    

    
}

- (BOOL)isFileExisit{
    NSArray *arr3=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSLog(@"========%@",[arr3 objectAtIndex:0]);
    
    NSArray *arr1 = [_documents[_currentButtonTag] componentsSeparatedByString:@"//"];
    NSString *str = [NSString stringWithFormat:@"%@",arr1[1]];
    NSArray *arr2 = [str componentsSeparatedByString:@"/"];
    NSString *suffixPathFile = [NSString stringWithFormat:@"%@",arr2[1]];
    //缓存文件的路径
    NSString *Fpath = [NSString stringWithFormat:@"%@%@",@"Library/Caches/",suffixPathFile];
    _downloadedLocalFilePath = [NSHomeDirectory() stringByAppendingPathComponent:Fpath];
    NSLog(@"path == %@",_downloadedLocalFilePath);
    
    
    BOOL isExisit = [[NSFileManager defaultManager] fileExistsAtPath:_downloadedLocalFilePath isDirectory:nil];
    if (isExisit) {
        _downloadedLocalFilePath = [NSString stringWithFormat:@"file://%@",_downloadedLocalFilePath];
        NSLog(@"该文件已存在！");
        return YES;
        //移除沙盒存在的PDF文件
        //        NSFileManager *fileManage = [[NSFileManager alloc]init];
        //        [fileManage removeItemAtPath:_path error:nil];
    } else {
        NSLog(@"不存在该文件！");
        return NO;
    }
}

//恢复下载
- (void)resume {
    self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    [self.downloadTask resume];
    self.resumeData = nil;
}

//开始下载
- (void)startDownload {
    NSURL *url = [NSURL URLWithString:_documents[_currentButtonTag]];
    self.downloadTask = [self.session downloadTaskWithURL:url];
    [self.downloadTask resume];
}

//暂停
- (void)pause {
    __weak typeof(self) selfVC = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        selfVC.resumeData = resumeData;
        selfVC.downloadTask = nil;
    }];
}

- (void)downloadImageWithUrl:(NSURL *)url{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        //刷新UI回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            _imageView.image = [UIImage imageWithData:data];
        });
    });
}

- (void)imageTapAction:(UIGestureRecognizer *)tap {
    SecondViewController *secondVC = [[SecondViewController alloc]init];
    secondVC.fileStr = _documents[0];
    [self.navigationController pushViewController:secondVC animated:YES];
    
}
#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}
#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    
    NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
    
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath
                                                                                              error:NULL];
    
    for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
    {
        NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        
    }
    
}


#pragma mark - NSURLSessionDownloadDelegate

//下载完毕会调用
// @param location     文件临时地址
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {

    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    // response.suggestedFilename ： 建议使用的文件名，一般跟服务器端的文件名一致
    NSString *file = [caches stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    // 将临时文件剪切或者复制Caches文件夹
    NSFileManager *mgr = [NSFileManager defaultManager];
    // AtPath : 剪切前的文件路径
    // ToPath : 剪切后的文件路径
    [mgr moveItemAtPath:location.path toPath:file error:nil];
    NSLog(@"下载完成");
    NSLog(@"location.path = %@",location.path);
    BOOL isExisit = [self isFileExisit];
    if (isExisit == YES) {
        NSURL *url = [NSURL URLWithString:_downloadedLocalFilePath];
        [ self gotoCopy:url];
        
    } else {
    
    }
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成" message:downloadTask.response.suggestedFilename  delegate:self cancelButtonTitle:@"知道了" otherButtonTitles: nil];
//    [alertView show];
}

/**
 *  每次写入沙盒完毕调用
 *  在这里面监听下载进度，totalBytesWritten/totalBytesExpectedToWrite
 *
 *  @param bytesWritten              这次写入的大小
 *  @param totalBytesWritten         已经写入沙盒的大小
 *  @param totalBytesExpectedToWrite 文件总大小
 */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    _myPregress.progress =  (double)totalBytesWritten/totalBytesExpectedToWrite;
    _pgLabel.text = [NSString stringWithFormat:@"下载进度%f",(double)totalBytesWritten/totalBytesExpectedToWrite];
}

//恢复下载后调用
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {

}

#pragma mark - QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    NSInteger numToPreview = 0;
    
    return 1;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    NSURL *fileURL = nil;
    
    fileURL = [NSURL URLWithString:_downloadedLocalFilePath];
    return fileURL;
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
