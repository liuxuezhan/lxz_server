<<<<<<< HEAD
## 链接 ##

| 名字 | 链接  |
|----|:---:|
| 我的代码库  | [github](https://liuxuezhan@github.com/liuxuezhan/skynet.git)   [开源中国](https://liuxuezhan@github.com/liuxuezhan/skynet.git)    [csdn](https://liuxuezhan@github.com/liuxuezhan/skynet.git) [coding](https://liuxuezhan@github.com/liuxuezhan/skynet.git)  |
| 本地管理 |  [mongo](http://192.168.1.100/rockmongo/index.php?action=admin.index)    [个人主页](http://192.168.1.100/wordpress/wp-admin/update-core.php)   [印象笔记](https://app.yinxiang.com/Home.action#n=c22c8e69-b47d-47b9-9cc1-30850cf5b9b4&ses=4&sh=2&sds=5&)   | 
| mongo |  [rockmongo](https://github.com/iwind/rockmongo.git)  [php_mongo](http://pecl.php.net/package/mongo) [中文社区](http://www.mongoing.com/) | 
|  python |   [资源大全](https://github.com/jobbole/awesome-python-cn) | 
| vim配置 |   [vim](https://github.com/humiaozuzu/dot-vimrc.git) | 
|  lua | [库](http://luaforge.net/tags/) [应用库](http://lua-users.org/wiki/LuaDirectory)  [zlib](https://github.com/brimworks/lua-zlib)  [5.3手册](http://cloudwu.github.io/lua53doc/manual.html#lua_getmetatable) | 
| nginx |   [淘宝翻译](http://tengine.taobao.org/book/index.html) | 
|  OpenResty |   [官网](http://openresty.org/cn/) [源码](https://github.com/sumory/openresty-china) [学习资源](https://github.com/TeamStuQ/skill-map/issues/29) [语法](https://moonbingbing.gitbooks.io/openresty-best-practices/content/openresty/install.html)  | 
| json |   [不同语言API](http://www.json.org/) | 
| mysql |   [csdn知识库](http://lib.csdn.net/base/14) | 
| 前端 |   [博客](http://qiankanglai.me/) | 
| 机器人算法 |   [facebook](https://github.com/torch/torch7) | 
| bootstrap |   [布局](http://www.ibootstrap.cn/v2/) | 
| ansible |  [模块](http://blog.csdn.net/modoo_junko/article/category/3084431) [应用](https://galaxy.ansible.com/explore#/) | 
| 图表 | [百度图表](https://github.com/ecomfe/echarts)   [淘宝图表](http://www.oschina.net/p/G2) [淘宝图片裁剪](https://github.com/exinnet/tclip) | 
| 其他 | [网易公开课](http://open.163.com/)  [开源黄页](http://www.oschina.net/company) [IT牛人博客](http://www.udpwork.com/)  [编程书籍](http://siberiawolf.com/free_programming/index.html) | 


## skynet ##
目录
```
[lualib]==>[lualib-src]==>[skynet-src]
```
注解版本:
https://github.com/liuxuezhan/skynet_with_note
https://github.com/peimin/skynet_with_comment

启动流程
skynet_main.c  main函数:            加载配置文件
skynet_start.c skynet_start函数:    初始化模块,启动4个主线程 
skynet_server.c 创建skynet服务和call通信 
skynet_env.c 设置和获得lua的环境变量
skynet_module.c 简单的用一个数组，然后通è查询服务模块是否在数组中。
skynet_handle.c 服务编号管理
skynet_harbor.c 启动节点服务，以及注册和发消息给远程节点。
skynet_monitor.c 监视服务
skynet_mq.c 消息队列

skynet_timer.c
定时器(HashedWheelTimer时间轮算法,插入和删除的时间复杂度都是O(1))
skynet_timer_init函数--修改推时间 + lua从数据库加载定时器

skynet_socket.c 网络接口
server
listen(socket-bind-listen-向epoll管道发送监听命令) 
start(epoll绑定fd)
accept

client(socket -- connect)


网络模块
socket_server.h
socket_server.c
socket_poll.h
socket_epoll.h
socket_kqueue.h

service_master.c主服务，负责管理harbor节点
service_harbor.c节点服务，与其他节点互通。
service_gate.c网关服务，管理Socket。
service_logger.c日志服务

加载lua编写的服务。核心服务。
Service_lua.h
service_snlua.c

databffer.h数据缓冲
hashid.h散列

lua-skynet.c  核心库，skynet.core
lua-seri.c 序列化
lua-profile.c 监控 

lua-netpack.c 网络封包，协议使用。
lua-socket.c 封装了socket-skiperver给lua使用
lua-clientsocket.c 客户端socket封装
lua-memory.c分配内存

rwlock.h  读写锁
skynet_error.c 错误处理

内存分配，默认使用jemalloc
malloc_hook.h
malloc_hookhook.c 
skynet_malloc.h

## ansible ##
```
ansible-playbook site.yml -vv --skip-tags="ali"
```

## 总结 ##

| 名字 | 信息  |
|----|:---:| 
| wordpress | dQgjoGK5()TRNkjkpP  | 
| Shadowsocks | ssserver -p 443 -k password -m rc4-md5  | 
| skynet | skynet的mongo驱动同一连接只能有一次，在服务器端不能有mongo集群处理，只能在域名上切换  | 
| lua | 协程中协程不要用  | 


## syslog ##
* `$emplate myformat, "%$NOW% %TIMESTAMP:8:$% %hostname% %syslogtag% %msg%\n" `>>/etc/rsyslog.conf
* ` local0.info   /var/log/local0.log;myformat `>>/etc/rsyslog.conf

## vim ##
### 配置 ###
[Solarized Dark]
text=839496
cyan(bold)=93a1a1
text(bold)=586e75
magenta=dd3682
green=859900
green(bold)=586e75
background=fdf6e3
cyan=2aa198
red(bold)=cb4b16
yellow=b58900
magenta(bold)=6c71c4
yellow(bold)=657b83
red=dc322f
white=eee8d5
blue(bold)=839496
white(bold)=fdf6e3
black=002b36
blue=268bd2
black(bold)=073642
[Names]
name0=Solarized Dark
count=1
```
### 技巧 ###
* 缩进：v模式 + `<>` 
* 分窗：`ctrl+W`+`v` 或`s` 
* 切换窗口：`Esc`+`1~9`
* 搜索：`F7`
* 注释：`leader`+`cc`
* 取消注释：`leader`+`cu`
* vimrc支持tmux
```
if exists('$TMUX')
  set term=screen-256color
endif
```

##openresty##
```
yum install php php-fpm
echo "user = www">>/etc/php.ini
echo "group = www">>/etc/php.ini
chkconfig php-fpm on
service php-fpm start
php
yum install pcre-devel openssl-devel
git clone https://liuxuezhan@git.oschina.net/liuxuezhan/my_tool.git  
cd my_tool/ngx_openresty-1.9.7.1/bundle/LuaJIT-2.1-20151219
make
make install
./configure --prefix=/www --with-luajit
```
配置nginx.conf
```
server {
    listen 6699 default so_keepalive=2s:2s:8;
    server_name foo.com;
 
    root /www/nginx/html;
    index index.html index.htm index.php;
 
    location / {
        try_files $uri $uri/ /index.php;
    }
 
    location ~ \.php$ {
        try_files $uri =404;
 
        include fastcgi.conf;
        fastcgi_pass 127.0.0.1:9000;
    }

    location /1.0/websocket {

  lua_socket_log_errors off;

  lua_check_client_abort on;

  content_by_lua '

    local server = require "resty.websocket.server"

    local wb, err = server:new{

    timeout = 5000,  -- in milliseconds

    max_payload_len = 65535,

    }

    if not wb then

      ngx.log(ngx.ERR, "failed to new websocket: ", err)

      return ngx.exit(444)

    end

    while true do

      local data, typ, err = wb:recv_frame()

      if wb.fatal then

        ngx.log(ngx.ERR, "failed to receive frame: ", err)

        return ngx.exit(444)

      end

      if not data then

        local bytes, err = wb:send_ping()

        if not bytes then

          ngx.log(ngx.ERR, "failed to send ping: ", err)

          return ngx.exit(444)

        end

      elseif typ == "close" then break

      elseif typ == "ping" then

        local bytes, err = wb:send_pong()

        if not bytes then

          ngx.log(ngx.ERR, "failed to send pong: ", err)

          return ngx.exit(444)

        end

      elseif typ == "pong" then

        ngx.log(ngx.INFO, "client ponged")

      elseif typ == "text" then

        local bytes, err = wb:send_text(data)

        if not bytes then

          ngx.log(ngx.ERR, "failed to send text: ", err)

          return ngx.exit(444)

        end

      end

    end

    wb:send_close()

  ';

}
}

```
* 映射6699到到宿主80端口
* 关闭selinux

```
chown -R www:www /www
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config 
```
* 重启查看sestatus
```
/www/nginx/sbin/nginx -p /www/nginx -c conf/nginx.conf
```
* 开机启动 创建 
```
#!/bin/sh
(
cat <<EOF
[Unit]  
Description=nginx  
After=network.target  
   
[Service]  
Type=forking  
ExecStart=/www/nginx/sbin/nginx -p /www/nginx -c conf/nginx.conf  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target 
EOF
) >/usr/lib/systemd/system/nginx.service

ln -s /usr/lib/systemd/system/nginx.service /etc/systemd/system/multi-user.target.wants/
systemctl daemon-reload
chkconfig nginx on
service nginx start
```

## mongo ##

```
#!/bin/sh
(
cat <<EOF
[mongodb-org-3.0]
name=MongoDB Repository
baseurl=http://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=1
EOF
) >/etc/yum.repos.d/mongodb-org-3.0.repo 

yum install mongodb-org
echo "security:">>/etc/mongod.conf
echo "authorization: abled">>/etc/mongod.conf
mongod -f /etc/mongod.conf
ln -s /usr/lib/systemd/system/mongod.service /etc/systemd/system/multi-user.target.wants/
systemctl daemon-reload
chkconfig mongod on
service mongod start

```
* 查看mongod的错误日志：/var/log/mongodb/mongod.log
* 映射27017到到宿主27017端口

### rockmongo ###
```
git clone https://github.com/iwind/rockmongo.git
yum install php-devel
wget http://pecl.php.net/get/mongo-1.6.13.tgz
tar -xzvf mongo-1.4.5.tgz
cd mongo-1.4.5
phpize
./configure
make
make install
echo "extension=mongo.so">>/etc/php.ini
cp rockmongo /www/nginx/html/rockmongo
```
* config.php 配置 `host`
* config.php 配置 `auth false`
* http://192.168.1.100/rockmongo/index.php?action=admin.index
=======
## Skynet

Skynet is a lightweight online game framework, and it can be used in many other fields.

## Build

For Linux, install autoconf first for jemalloc:

```
git clone https://github.com/cloudwu/skynet.git
cd skynet
make 'PLATFORM'  # PLATFORM can be linux, macosx, freebsd now
```

Or you can:

```
export PLAT=linux
make
```

For FreeBSD , use gmake instead of make.

## Test

Run these in different consoles:

```
./skynet examples/config	# Launch first skynet node  (Gate server) and a skynet-master (see config for standalone option)
./3rd/lua/lua examples/client.lua 	# Launch a client, and try to input hello.
```

## About Lua version

Skynet now uses a modified version of lua 5.3.3 ( https://github.com/ejoy/lua/tree/skynet ) for multiple lua states.

You can also use official Lua versions, just edit the Makefile by yourself.

## How To Use (Sorry, Only in Chinese now)

* Read Wiki for documents https://github.com/cloudwu/skynet/wiki
* The FAQ in wiki https://github.com/cloudwu/skynet/wiki/FAQ
>>>>>>> upstream/master
