WebRequestComponent
===================

license for BSD

http类库

1．	使用ＧＣＤ线程管理，使用异步请求方式（暂不支持同步请求）。2．	支持SSL,proxy(http,socket5),cookie。3．	支持http断点续传（下载），支持上传、下载进度回调。4．	支持队列请求，并发请求，组请求。5．	支持常见http请求,(POST,GET,DELETE,PUT)6．	支持重定向。7．	支持ＧＺＩＰ请求。类库为非ＡＲＣ模式。类库支持环境：ＩＯＳ：	  Xcode 4.6以上。Mac 10.8.5  xcode5.0以上。只支持64位编译，32位机的没有做适配。所以低版本的ＸＣ编译会有问题。类库依赖：依赖:    ios : UIKit.framework,mobileCoreServices.framework    mac : systemConfiguration.framework,cocoa.framework,appkit.frameworksdk依赖(ios,mac共同依赖):CFNewwork.framework,libz.dylib,Foundation.framework