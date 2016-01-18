/** upload_file.php
 *
 *
 *
 *
 <?php
 if ((($_FILES["file"]["type"] == "image/png")
 || ($_FILES["file"]["type"] == "image/jpeg")
 || ($_FILES["file"]["type"] == "image/pjpeg")))
 {
 if ($_FILES["file"]["error"] > 0)
 {
 echo "{\"msg\":\"error123\"}";
 }
 else
 {
 if (file_exists("upload/" . $_FILES["file"]["name"]))
 {
 echo "{\"msg\":\"success1\"}";
 }
 else
 {
 move_uploaded_file($_FILES["file"]["tmp_name"],"upload/" . $_FILES["file"]["name"]);
 echo "{\"msg\":\"success2\"}";
 }
 }
 }
 else
 {
 echo "{\"errorMsg\":\"Invalid file\"}";
 }
 ?>
 *
 *
 *
 *    崩溃的可能原因：
 *    1.注意服务器的upload权限没有有写权限；
 *    2.上传的data为nil；
 *    3.php代码错误，上面的php是精简版，粘贴即可；
 *
 *
 */
#import "ViewController.h"
#import <AFNetworking.h>
#import <UIImageView+WebCache.h>

@interface ViewController ()
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, strong) AFURLSessionManager *mgr;
@property (nonatomic, strong) NSProgress *progress;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self upload1];
}

/**
 *  AFHTTPRequestOperationManager
 *
 *  Method: POST
 *
 *  没有进度条
 */
-(void)upload1{
    // image 不能为nil，否则报错
    UIImage * image = [UIImage imageNamed:@"1.png"];
    NSParameterAssert(image);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSData *imageData = UIImagePNGRepresentation(image);
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *str = [formatter stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@.png", str];
    NSDictionary *parameters = @{@"filename":fileName};
    
    //申明请求的数据是json类型
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    //如果报接受类型不一致请替换一致text/html或别的
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    [manager POST:@"http://localhost/upload_file.php" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // 上传图片，以文件流的格式
        // 注意此处name必须为file，因为php接收时时使用$_FILES["file"]
        [formData appendPartWithFileData:imageData name:@"file" fileName:fileName mimeType:@"image/png"];
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@",responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
}

/**
 *
 *  NSURLSessionUploadTask
 *
 *  带进度
 *
 */
- (void)upload2 {
    NSString *urlStr = @"http://localhost/upload_file.php";
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"big.png"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSParameterAssert(data);
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:@"file" fileName:@"filename1.png" mimeType:@"image/png"];
    } error:nil];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *mgr = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSProgress *progress = nil;
    NSURLSessionUploadTask *uploadTask = [mgr uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"%@", responseObject);
        }
    }];
    self.progress = progress;
    [progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
    [uploadTask resume];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        double curr = [change[NSKeyValueChangeNewKey] doubleValue];
        NSLog(@"%f",curr);
    }
}

- (void)dealloc {
    [self.progress removeObserver:self forKeyPath:@"fractionCompleted"];
}

@end



