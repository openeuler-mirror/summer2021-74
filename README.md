# Summer2021-No.74 利用kprobe等工具实现快速定位网络丢包和时延问题的工具

#### 介绍
https://gitee.com/openeuler-competition/summer-2021/issues/I3ESBZ

本项目旨在实现一个快速定位网络丢包和时延问题的工具。目前工具可以准确定位UDP接收丢包和发送丢包在Linux内核函数的具体位置,也可以实现初步的时延检测，并给出时延时间。

#### 软件架构说明

本工具实现形式为shell脚本。软件共分为两部分，分别是进行内核函数丢包检测和内核函数时延检测。

#### 安装教程

这是一个脚本工具，可以直接执行。
```shell
dnf install -y git
git clone https://gitee.com/openeuler-competition/summer2021-74.git
```
#### 测试软件安装

安装iperf工具，用于发送和接收UDP数据包
```
wget https://iperf.fr/download/fedora/iperf-2.0.8-2.fc23.x86_64.rpm
rpm -ivh iperf-2.0.8-2.fc23.x86_64.rpm
```
在接收端开启UDP服务器
```
iperf -s -u
```
在发送端开启UDP客户端，假设接收端的IP地址为192.168.226.128（请自行将IP地址替换为自己的服务端IP地址）
```
iperf -c 192.168.226.128 -u
```
至此完成了基本的UDP发送和接收

#### 使用说明

在root用户下使用，虽然这是一个可以无需其他依赖的脚本工具，但目前仅在openEuler21.03操作系统下测试成功，Linux内核版本为“5.10.0-4.17.0.28.oe1.x86_64”，建议在Linux内核版本5.x下使用。  
```shell
./tool -h
```

#### 丢包检测

##### 丢包场景1-防火墙丢包

以openEuler21.03为例，该操作系统默认开启防火墙，并丢弃外部发来的UDP流量，或者使用如下命令开启防火墙
```
systemctl start firewalld
```
启动工具检测丢包
```
./tool -l
```

##### 丢包场景2-缓冲满丢包

接收端iperf命令保持不变
```
iperf -s -u
```
发送端iperf命令需要进行一些修改，以发送大量的UDP数据包
```
iperf -c 192.168.226.128 -u -b 10000M -P 4
```
启动工具检测丢包
```
./tool -l
```

##### 丢包场景3-反向路由

该过程相对复杂，请参考本仓库中的“reverse pathing filter.txt”文件

#### 时延检测

在test文件夹中，执行时延产生脚本，时延时间可以自行修改，默认时延100ms
```
./tc_delay.sh
```
启动工具检测时延
```
./tool.sh -t 10000 -d
```
    
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
