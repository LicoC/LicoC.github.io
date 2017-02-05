---
title: UILabel+AFNetworking 显示下载百分比
date: 2017-02-04 17:55:22
tags:
	- kvo
	- AFNetworking
---


### 用处: 
利用AFNetworking做下载操作的时候，利用UILabel动态显示下载百分比，显示格式如下：百分比%。

### 如何实现：###
我们调用AFNetworking做下载的时候，一般会创建一个NSURLSessionDownloadTask对象，调用AFURLSessionManager的方法：

<!-- 阅读更多 -->

```
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
progress:(NSProgress * __autoreleasing *)progress
destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler;
```
NSURLSessionDownloadTask继承于NSURLSessionTask，我们向捕获下载进度，实际就是监听NSURLSessionTask上的countOfBytesReceived和state属性，实时改变UILabel的显示文案即可。

### 源码：###
UILabel+AFNetworking.h

```
#import <UIKit/UIKit.h>

@interface UILabel (AFNetworking)

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task;

- (void)removeProgressOfTaskInfo:(NSURLSessionDownloadTask *)task;

@end

```

UILabel+AFNetworking.m

```
#import "UILabel+AFNetworking.h"

static void * AFTaskCountOfBytesReceivedContext = &AFTaskCountOfBytesReceivedContext;

@implementation UILabel (AFNetworking)

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task
{
[task addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptions)0 context:AFTaskCountOfBytesReceivedContext];
[task addObserver:self forKeyPath:@"countOfBytesReceived" options:(NSKeyValueObservingOptions)0 context:AFTaskCountOfBytesReceivedContext];
}

- (void)removeProgressOfTaskInfo:(NSURLSessionDownloadTask *)task {
if (task) {
@try {
[task removeObserver:self forKeyPath:@"state"];
[task removeObserver:self forKeyPath:@"countOfBytesReceived"];
} @catch (NSException *exception) {

}
}
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
ofObject:(id)object
change:(__unused NSDictionary *)change
context:(void *)context
{
if (context == AFTaskCountOfBytesReceivedContext) {
if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
if ([object countOfBytesExpectedToReceive] > 0) {
dispatch_async(dispatch_get_main_queue(), ^{
CGFloat progressValue = (CGFloat)[object countOfBytesReceived] / (CGFloat)[object countOfBytesExpectedToReceive] * 100.0;

NSString *progress = [NSString stringWithFormat:@"%lld%%", (int64_t)progressValue];
self.text = progress;
});
}
}

if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
if ([(NSURLSessionTask *)object state] == NSURLSessionTaskStateCompleted) {
@try {
[object removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];

if (context == AFTaskCountOfBytesReceivedContext) {
[object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))];
}
}
@catch (NSException * __unused exception) {}
}
}
}
}
@end

```

### 用法：###

```
[yourLabel setProgressWithDownloadProgressOfTask:yourDownloadTask];
```
监听到下载完成，会自动移除掉obersver，如果想在下载到一半的时候移除监听，调用：

```
[yourLabel removeProgressOfTaskInfo:yourDownloadTask];
```

项目需要，所以写了这样的一个Category，其实相应的还可以做上传的动态监测，AFNetworkging自己也有一个UIKit+AFNetworking的group下实现了很多UIKit下控件关于AFNetworking的Category，大家可以去看下啦~~
