#!/usr/bin/python
#coding=utf-8
import os
import tornado.httpserver
import tornado.ioloop
import tornado.options
import tornado.web
import subprocess
import datetime
import time
import sys
from datetime import *

from tornado.options import define, options
define("port", default=80, help="输入端口号", type=int)
define("name", default="robot", help="输入机器人名字", type=str)
define("path", default=sys.argv[1], help="路径", type=str)
conf="conf.lua"


gHandle = 0
class main(tornado.web.RequestHandler):
    def get(self):
        os.chdir(options.path+"/script/robot/html")
        self.render('my_index.html')

class start_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle

        cmd = '/usr/bin/killall -9 robot'
        a = subprocess.Popen(cmd, shell=True)
        a.wait()

        cmd = 'cp game robot'
        path = '%s/bin'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        a.wait()

        cmd = '%s/bin/robot %s'%(options.path,conf)
        path = '%s/bin'%(options.path)
        sub = subprocess.Popen(cmd, cwd=path, shell=True)
        gHandle = sub
        self.write( "done" )


class stop_robot(tornado.web.RequestHandler):
    def get(self):
        self.write(os.getcwd())
        global gHandle
        if gHandle != 0:
            gHandle.terminate()
            gHandle.wait()
            gHandle = 0

        cmd = '/usr/bin/killall -9 robot'
        a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True, bufsize=4096)
        a.wait()
        self.write( "done" )


class log_robot(tornado.web.RequestHandler):
    def get(self):
        cmd = 'grep %s /var/log/localA.log | tail -n 100'%(options.name)
        a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        logs = a.stdout.read()
        a.wait()
        for log in logs.split("\n"):
            self.write( "%s<br/>"%log )

class UploadFileHandler(tornado.web.RequestHandler):
    def post(self):
        select = int(self.get_argument("select"))
        if select == 1 :
            file_metas=self.request.files['files']    
            for meta in file_metas:
                conf=meta['filename']
                filepath=os.path.join(options.path+"/bin",conf)
            #有些文件需要已二进制的形式存储，实际中可以更改
                with open(filepath,'wb') as up:      
                    up.write(meta['body'])
            self.write( "done" )
        elif select == 2 :
            #filename = "conf.lua"
            filename=os.path.join(options.path+"/script/robot","conf.lua")
            #Content-Type这里我写的时候是固定的了，也可以根据实际情况传值进来
            self.set_header ('Content-Type', 'application/octet-stream')
            self.set_header ('Content-Disposition', 'attachment; filename='+filename)
            #读取的模式需要根据实际情况进行修改
            with open(filename, 'rb') as f:
                while True:
                    data = f.read(4096)
                    if not data:
                        break
                    self.write(data)
            #记得有finish哦
            self.finish()

class new(tornado.web.RequestHandler):
    def get(self):
        num1 = int(self.get_argument("num1"))
        num2 = int(self.get_argument("num2"))


        cmd = 'sed -i "s#gName.*#gName =\\"%s\\" #g" conf.lua'%(options.name)
        path = '%s/script/robot'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        a.wait()

        cmd = 'sh createrobot.sh %s %d %d'%(options.name,num1,num2)
        path = '%s/plscripts'%(options.path)
        self.write( "%s<br/>"%path )

        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )
        self.write( "done !" )

class MyFile(tornado.web.StaticFileHandler):  
    def set_extra_headers(self, path):  
        self.set_header("Cache-control", "no-cache")  
if __name__ == "__main__":
    tornado.options.parse_command_line()
    app = tornado.web.Application([
        (r"/",main),
        (r"/start_robot", start_robot),
        (r"/stop_robot", stop_robot),
        (r"/log_robot", log_robot),
        (r"/file",UploadFileHandler),
        (r"/new", new),  
        (r"/(.*)", MyFile, {"path":"./"}),  
        ],
       #template_path = os.path.join(os.path.dirname(__file__),"html"),
       #static_path =os.path.join(os.path.dirname(__file__), "html/assets"),
      debug = True
    )   
    http_server = tornado.httpserver.HTTPServer(app)
    http_server.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()
