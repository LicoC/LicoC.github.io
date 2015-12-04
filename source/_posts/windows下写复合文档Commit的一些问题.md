title: COM读写复合文档
date: 2015-11-16 17:27:16
categories: Windows
tags: Windows, COM
---

### 复合文档的结构
Windows下的复合文档是一种把文件内容按照类似文件系统的结构存储的文件，也叫做结构化文档。最常见的复合文档格式莫过于Microsoft Office存储的* .xls, * .doc, * .ppt三种格式了。
复合文档的结构大概是这样的：
-RootStorage
-----   subStream1
-----   subStream2
-----   subStream3
由一个根Storage下挂着一些子Stream组成，看起来还是很清楚明了的哈。
然而东西依然是以二进制格式去存储，但是不是顺序存储的，文件一开头并不是RootStorage。
复合文档有自己的存储结构，简要说一下：
1. 复合文档头。
	存储在文件的0~512个字节内，文档头存储了复合文档的一些基本信息，如复合文档标识，文件版本号，字节顺序规则标识，复合文档中扇区的各种信息，而扇区则和各个Storage以及Stream息息相关。

2. 目录入口。
	这里才记录着真正的RootStorage存储的起始位置， 以及各个Stream的位置，数据结构的话对应的就是一颗红黑树，查找下一个子目录时就是依靠这棵树的。

复合文档结构说起来还是蛮复杂的，推荐一篇文章吧，讲的比较细：
[复合文档文件格式研究（二进制）](http://club.excelhome.net/thread-227502-1-1.html)
	
### 对复合文档的操作
复合文档终归还是文件啊，操作也就无非就是Open(),Seek(),Write(),Read(),Commit()等。还是就着代码来说吧~上代码~

**只读文件:**
```
//filename  文件名
//pRootStorage 总目录
::StgOpenStorage(
	filename, 
	NULL, 
	STGM_READ | STGM_SHARE_EXCLUSIVE, 
	0，
	0，
	&pRootStorage);

//streamName 子stream的名称
//pSubStream 子stream
pRootStorage->OpenStream(
	streamName, 
	NULL, 
	STGM_READ | STGM_SHARE_EXCLUSIVE,
	0,
	&pSubStream);

//pBuff 读取后存放数据的缓存
//cbRead 想要读取的字节数
//cbReaded 实际读取的字节数
pSubStream->Read(pBuff, cbRead, &cbReaded);
```
**只写文件:**
```
//注意第三个参数和上面的不同
::StgOpenStorage(
	filename, 
	NULL, 
	STGM_WRITE | STGM_SHARE_EXCLUSIVE, 
	0，
	0，
	&pRootStorage);

pRootStorage->OpenStream(
	streamName, 
	NULL, 
	STGM_WRITE | STGM_SHARE_EXCLUSIVE,
	0,
	&pSubStream);

//pBuff 写入文件的数据缓冲区
//cbWrite 打算写的数据大小
//cbWritten 实际写进流的数据大小
pSubStream->Write(p Buff, cbWrite, &cbWritten);
```
**边读边写文件:**
```
//注意第三个参数
::StgOpenStorage(
	filename, 
	NULL, 
	STGM_READWRITE | STGM_SHARE_EXCLUSIVE| STGM_TRANSACTED, 
	0，
	0，
	&pRootStorage);

pRootStorage->OpenStream(
	streamName, 
	NULL, 
	STGM_READWRITE | STGM_SHARE_EXCLUSIVE,
	0,
	&pSubStream);

pSubStream->Read(pBuffRead, cbRead, &cbReaded);

//pos 要写的位置
//STREAM_SEEK_SET 第一个参数pos的相对位置，是从pSubStream指向的流的开始位置，还是当前位置开始，还是文件末尾位置，STREAM_SEEK_SET是流开始位置
pSubStream->Seek(pos, STREAM_SEEK_SET, NULL);

pSubStream->Write(pBuffWrite, cbWrite, &cbWiritten);

//grfCommitFlags 将Write中修改的数据提交到文件中
//注意这里和只写文件时不一样，只写文件的时候，是没有调Commit的
pSubStream->Commit(grfCommitFlags);
pRootStorage->Commit(grfCommitFlags);
```

**1. ::StgOpenStorage() **
```
HRESULT StgOpenStorage(
  _In_  const WCHAR    *pwcsName,
  _In_        IStorage *pstgPriority,
  _In_        DWORD    grfMode,
  _In_        SNB      snbExclude,
  _In_        DWORD    reserved,
  _Out_       IStorage **ppstgOpen
);
```
这个函数用来打开文件系统中的存在的根目录，第一个参数一般就是你要打开的复合文档的文件名，如果第一个参数指定了是复合文档的文件名，第二个参数为NULL。第三个参数用来指定打开根目录的方式，如STGM_READ，STGM_WRITE等。第四个参数 如果不为NULL，则是一个块独占的存储区域的指针，没啥特殊需要就给NULL值了。第五个参数保留必须为0。第六个参数是打开后拿到的根目录的指针。

grfMode的值有以下这些：
STGM_READ 只读模式
STGM_WRITE 只写模式
STGM_READWRITE 读写模式
STGM_SHARE_DENY_NONE 共享存取模式
STGM_SHARE_DENY_READ 禁止共享的读模式
STGM_SHARE_DENY_WRITE 禁止共享的写模式
STGM_SHARE_EXCLUSIVE 独占的存取模式
STGM_DIRECT 对复合文档的所有修改立即生效
STGM_TRANSACTED 提交时所有修改才被保存到复合文档中
STGM_FAILIFTHERE 若已存在一个流或存储，则创建复合文档失败
STGM_CREATE 若已存在一个流或存储，则它将被覆盖，否则将创建一个新的流或存储
STGM_DELETEONRELEASE 当这个复合文档中的流或存储被释放时，它也会自动被释放

这些值可以组合使用。

**2. IStorage::OpenStream()**
```
HRESULT OpenStream(
  [in]  const WCHAR   *pwcsName,
  [in]        void    *reserved1,
  [in]        DWORD   grfMode,
  [in]        DWORD   reserved2,
  [out]       IStream **ppstm
);
```
用指定的模式打开指定根目录下的子流。第一个目录是子流的名称。第二个和第四个参数保留置空。第三个目录是打开流的模式，参考上面列出的值。第五个参数是存储打开的子流的指针。

Read()，Write()，Seek()，这三个函数代码的注释中基本都解释了，这里不再赘述。

**3. Commit()方法与写模式和边读边写模式的差别**

我们注意到以STGM_WRITE | STGM_SHARE_EXCLUSIVE模式和STGM_READWRITE | STGM_SHARE_EXCLUSIVE模式打开根目录和子流，并进行写操作的时候，处理方式是不一样的。
STGM_WRITE 模式，一般可以理解为直接模式打开这个复合文档，此时，对复合文档的写操作，会将修改的数据马上自动刷新到复合文档中去。
而STGM_READWRITE 模式，一般理解为交易模式，此时，必须手动调用Commit方法才能将修改的数据刷新到复合文档中去。

看一下Commit的参数：
```
HRESULT Commit(
DWORD grfCommitFlags 
//指定修改的数据提交的方式，下面是这个参数的取值意义
/*typedef enum tagSTGC 
{ 
STGC_DEFAULT = 0, 
STGC_OVERWRITE = 1, 
STGC_ONLYIFCURRENT = 2, 
STGC_DANGEROUSLYCOMMITMERELYTODISKCACHE = 4 
} STGC;*/
); 
```
主要说一下STGC_DEFAULT和STGC_OVERWRITE两个值。首先要了解Commit到底做了些什么。当调用Commit方法时，会先在文档中申请一块新的空间，把新的数据写入这块空间。并将这块空间的入口地址记录到复合文档的索引中去，这样完成新的数据替代旧的数据。当指定以STGC_DEFAULT模式提交时，旧的数据还会存在于文件当中，等到下次修改数据并提交时才会被覆盖掉。而当指定STGC_OVERWRITE模式时，旧的数据将不会保留。
