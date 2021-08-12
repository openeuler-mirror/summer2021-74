# Summer2021-No.74 利用kprobe等工具实现快速定位网络丢包和时延问题的工具

#### 介绍
https://gitee.com/openeuler-competition/summer-2021/issues/I3ESBZ
    本项目旨在实现一个快速定位网络丢包和时延问题的工具。目前工具可以准确定位UDP接收丢包和发送丢包在Linux内核函数的具体位置，并每隔0.1s输出检测结果。

#### 软件架构
软件架构说明
    本工具实现形式为shell脚本。软件共分为两部分，一部分是使用kprobe对一些可疑函数进行探测，另一部分对探测结果进行判断。

#### 安装教程

在OpenEuler21.03操作系统下安装
1.  yum install -y git
2.  git clone https://gitee.com/openeuler-competition/summer2021-74.git

#### 使用说明

目前在Linux内核版本“5.10.0-4.17.0.28.oe1.x86_64”下测试成功，建议在Linux内核版本5.x下使用  
1.  执行tool.sh，显示红色的提示“DETECTING...”表示工具正在检测丢包
2.  输出示例：“[2021-08-12T17:45:43+08:00]DROPPING DETECTED -----> __udp_queue_rcv_skb”，“[2021-08-12T17:45:43+08:00]”表示检测到丢包的时间，“__udp_queue_rcv_skb”表示定位到的内核丢包函数。
3.  目录下的test文件夹包含了一些测试文件，其中为了方便测试，用户可以自行执行“tc_dropping.sh”来人为构造出发送丢包场景。
4. “crtl+c”组合键中断程序，停止检测

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
