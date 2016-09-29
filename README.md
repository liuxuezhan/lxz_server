## 链接 ##

| 名字 | 链接  |
|----|:---:|
| 我的代码库  | [github](https://liuxuezhan@github.com/liuxuezhan/skynet.git)   [开源中国](https://liuxuezhan@github.com/liuxuezhan/skynet.git)    [csdn](https://liuxuezhan@github.com/liuxuezhan/skynet.git) [coding](https://liuxuezhan@github.com/liuxuezhan/skynet.git)  |
| 本地管理 |  [mongo](http://192.168.1.100/rockmongo/index.php?action=admin.index)    [个人主页](http://192.168.1.100/wordpress/wp-admin/update-core.php)   [印象笔记](https://app.yinxiang.com/Home.action#n=c22c8e69-b47d-47b9-9cc1-30850cf5b9b4&ses=4&sh=2&sds=5&)   | 
| mongo |  [rockmongo](https://github.com/iwind/rockmongo.git)  [php_mongo](http://pecl.php.net/package/mongo) [中文社区](http://www.mongoing.com/) | 
| skynet参考 | [skynet研究](http://skynetdoc.com/)  [skynet源码](https://github.com/cloudwu/skynet )   | 
|  python |   [资源大全](https://github.com/jobbole/awesome-python-cn) | 
| vim配置 |   [vim](https://github.com/humiaozuzu/dot-vimrc.git) | 
|  lua | [库](http://luaforge.net/tags/) [应用库](http://lua-users.org/wiki/LuaDirectory)  [zlib](https://github.com/brimworks/lua-zlib)  [5.3手册](http://cloudwu.github.io/lua53doc/manual.html#lua_getmetatable) | 
| nginx |   [淘宝翻译](http://tengine.taobao.org/book/index.html) | 
|  OpenResty |   [官网](http://openresty.org/cn/) [源码](https://github.com/sumory/openresty-china) [学习资源](https://github.com/TeamStuQ/skill-map/issues/29) [语法](https://moonbingbing.gitbooks.io/openresty-best-practices/content/openresty/install.html)  | 
| json |   [不同语言API](http://www.json.org/) | 
| mysql |   [csdn知识库](http://lib.csdn.net/base/14) | 
| 前端 |   [博客](http://qiankanglai.me/) | 
| vim配置 |   [vim](https://github.com/humiaozuzu/dot-vimrc.git) | 
| 机器人算法 |   [facebook](https://github.com/torch/torch7) | 
| bootstrap |   [布局](http://www.ibootstrap.cn/v2/) | 
| ansible |  [模块](http://blog.csdn.net/modoo_junko/article/category/3084431) [应用](https://galaxy.ansible.com/explore#/) | 
| 图表 | [百度图表](https://github.com/ecomfe/echarts)   [淘宝图表](http://www.oschina.net/p/G2) [淘宝图片裁剪](https://github.com/exinnet/tclip) | 
| 其他 | [网易公开课](http://open.163.com/)  [开源黄页](http://www.oschina.net/company) [IT牛人博客](http://www.udpwork.com/)  [编程书籍](http://siberiawolf.com/free_programming/index.html) | 

## ansible ##
```
ansible-playbook site.yml -vv --skip-tags="ali"
```

## 总结 ##

| 名字 | 信息  |
|----|:---:| 
| wordpress | dQgjoGK5()TRNkjkpP  | 
| Shadowsocks | ssserver -p 443 -k password -m rc4-md5  | 


## syslog ##
* `$emplate myformat, "%$NOW% %TIMESTAMP:8:$% %hostname% %syslogtag% %msg%\n" `>>/etc/rsyslog.conf
* ` local0.info   /var/log/local0.log;myformat `>>/etc/rsyslog.conf

## vim ##
### 配置 ###
:BundleInstall    
.bashrc增加export TERM="screen-256color"
```
[Solarized Dark]
text=839496
cyan(bold)=93a1a1
text(bold)=839496
magenta=dd3682
green=859900
green(bold)=586e75
background=042028
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
