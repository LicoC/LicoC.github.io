---
title: Objective-C封装std::priority_queue<>实现优先队列
date: 2016-12-05 17:40:25
tags: priority_queue
---

最近项目中需要用到优先队列，google了半天，发现Cocoa Foundation中竟然木有现成的好用的轮子可以拿来用。找了半天，也只有Core Foundation的CFBinaryHeap算是满足需求，但是CFBinaryHeap需要自己管理释放对象，而且不能实时更新heap中的值，再一看文档中提供的方法，辣么多回调列在那里，做为一个前C++开发者，我想我还不如用我熟悉一点的std::priority_queue来实现我的需求吧。

<!-- 阅读更多 -->

### 回忆下什么是优先队列 ###
讲到队列一般人都知道，先进先出嘛，就和排队买东西一样，先来的人排在前面，买完就从队列里出去了。那什么是优先队列呢，假设我们生活在一个特别尊老爱幼的社会，每次排队买东西的时候，都要按照年龄作为优先级比较的参照，年纪大的在最前面，年纪小的在其次，青壮年排在后面，老爷爷老奶奶买完了，才轮到小孩儿，小孩儿们正买着辣条呢呢，忽然又来了个老奶奶，大家于是很懂礼貌的让老奶奶排到了第一个，等老奶奶抢完了超市里的土鸡蛋离开队伍后，才轮到刚刚正准备买辣条的小孩子继续买。

### 用OC封装std::priority_queue ###
STL中的priority_queue是C++基于heap实现的优先队列模板类，其鲁棒性和性能已经经过了无数开发者的考验。所以我们放心大胆的用吧。

首先定义一下std::priority_queue<>的包装类:

```
----PriorityQueue.h----
@interface QueueIntNodeObject : NSObject

@property (nonatomic, assign) NSUInteger compareValue;

@end

@interface PriorityQueue : NSObject

@property (nonatomic, readonly) QueueIntNodeObject *topObject;

@property (nonatomic, readonly) NSUInteger count;

- (void)pushObject:(QueueNodeObject *)myObject;

- (void)popObject;

- (void)popAllObjects;

```
QueueIntNodeObject是优先队列中所要管理的对象的基类，目前先实现以NSUInteger做为比较优先级的类型，有需要的可以扩展其他的基类出来。
PriorityQueue是用来包装std::priority_queue的wrapper。定义几个常用的属性和方法。

```
----PriorityQueue.mm----
#import "PriorityQueue.h"
#include <queue>

class QueueCompare {
public:
    bool operator()(QueueIntNodeObject *l, QueueIntNodeObject *r) const {
        if (l.compareValue < r.compareValue) {
            return true;
        }else {
            return false;
        }
    }
};

typedef std::priority_queue<QueueIntNodeObject *, std::vector<QueueIntNodeObject *>, QueueCompare> Queue;

#pragma mark - QueueIntNodeObject
@implementation QueueIntNodeObject
@end

#pragma mark - PriorityQueue
@interface PriorityQueue ()
@property (nonatomic) Queue *priority_queue;
@end

@implementation PriorityQueue
- (instancetype)init {
      self = [super init];
      if (self) {
          _priority_queue = new Queue();
      }
      return self;
}

- (void)dealloc {
      delete _priority_queue;
      _priority_queue = NULL;
}

- (QueueIntNodeObject *)topObject {
       return !self.priority_queue->empty() ? self.priority_queue->top() : nil;
}

- (NSUInteger)count {
       return (NSUInteger)self.priority_queue->size();
}

- (void)popObject {
       if (!self.priority_queue->empty()) {
            self.priority_queue->pop();
        }
}

- (void)pushObject:(QueueIntNodeObject *)myObject {
        self.priority_queue->push(myObject);
}

- (void)popAllObjects {
        if (!self.priority_queue->empty()) {
              delete _priority_queue;
              _priority_queue = new Queue();
        }
}
@end
```

QueueCompare定义一个C++类，用来重载()运算符，实现两个QueueIntNodeObject对象的比较。

```
typedef std::priority_queue<QueueIntNodeObject *, std::vector<QueueIntNodeObject *>, QueueCompare> Queue;
```
给priority_queue另外定义个名字，这个实在太长了。
下面就是实现PriorityQueue的几个方法，每个方法对应的即是操作std::priority_queue的方法。当然别忘了再不使用std::priority_queue的时候delete掉，否则会有内存泄漏。

我们再来看段实例代码，以前面举的排队的例子，先定义一个排队的人的对象，对象有两个属性，名称和年纪：

```
@interface Person : QueueIntNodeObject

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithName:(NSString *)name age:(NSUInteger)age;

@end
@implementation SeatInfo
- (instancetype)initWithName:(NSString *)name age:(NSUInteger)age {
        if (self = [super init]) {
            self.name = name;
            self.compareValue = age;
        }
        return self;
}
@end
```

然后再创建几个Person对象，放到队列管理去。

```
Person *s1 = [[Person alloc] initWithName:@"贾母" age:70];
NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)s1));
Person *s2 = [[Person alloc] initWithName:@"宝玉" age:16];
Person *s3 = [[Person alloc] initWithName:@"黛玉" age:15];
Person *s4 = [[Person alloc] initWithName:@"宝钗" age:17];
Person *s5 = [[Person alloc] initWithName:@"妙玉" age:18];
Person *s6 = [[Person alloc] initWithName:@"贾政" age:40];
Person *s7 = [[Person alloc] initWithName:@"凤姐儿" age:20];
Person *s8 = [[Person alloc] initWithName:@"平儿" age:19];

PriorityQueue *queue = [[PriorityQueue alloc] init];
[queue pushObject:s1];
[queue pushObject:s2];
[queue pushObject:s3];
[queue pushObject:s4];
[queue pushObject:s5];
[queue pushObject:s6];
[queue pushObject:s7];
[queue pushObject:s8];
NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)s1));

while (queue.count) {
      Person *person = (Person *)[queue topObject];
      NSLog(@"%@", person.name);
      [queue popObject];
}
NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)s1));
```
这段代码执行后，会按年龄从大到小输出person对象，达到了我们想要的按照年纪作为优先级参照输出的效果。
并且，我在其中加入了输出person对象引用计数的log,运行后发现，priority_queue在ARC下也很好的管理了计数，person对象在被push到queue中后，queue对其持强引用，引用计数加1，从queue中pop出来后，引用计数减1。所以我们依旧不用担心如何在ARC中管理内存。

如果想实现更复杂的优先级的控制，只需要实现一个类似于QueueIntNodeObject的类和一个用于比较优先级的类即可。
是不是很简单啦啦啦~~~

文中代码都提交到 github 啦：https://github.com/LicoC/PriorityQueue ， 欢迎star 😝