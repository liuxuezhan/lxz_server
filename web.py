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
define("port", default=9010, help="输入端口号", type=int)
define("name", default="robot", help="输入机器人名字", type=str)
define("path", default="", help="路径", type=str)


gHandle = 0
class main(tornado.web.RequestHandler):
    def get(self):
#  import pygal
#        line_chart = pygal.Line()
##        line_chart.title = 'Browser usage evolution (in %)'
##        line_chart.x_labels = ['2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009', '2010', '2011', '2012']
#        line_chart.add('Firefox', [1, 2, 0, 16.6,   25,   31, 36.4, 45.5, 46.3, 42.8, 37.1])
#        line_chart.add('Chrome',  [3, 2, 5, 77, 43, 22,    0,  3.9, 10.8, 23.8, 35.3])
#        line_chart.add('IE',      [85.8, 84.6, 84.7, 74.5,   66, 58.6, 54.7, 44.8, 36.2, 26.6, 20.1])
#        line_chart.add('Others',  [14.2, 15.4, 15.3,  8.9,    9, 10.4,  8.9,  5.8,  6.7,  6.8,  7.5])
#        self.write(line_chart.render())
        self.render('index.html')
        #os.chdir("/script/robot")


class Start_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle

        cmd = '/usr/bin/killall -9 robot'
        a = subprocess.Popen(cmd, shell=True)
        a.wait()

        cmd = 'cp game robot'
        path = '%s/bin'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        a.wait()

        cmd = '%s/bin/robot 0 robot robot/robot.lua'%(options.path)
        path = '%s/bin'%(options.path)
        sub = subprocess.Popen(cmd, cwd=path, shell=True)
        gHandle = sub
        self.write( "done" )


class Stop_robot(tornado.web.RequestHandler):
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


class GetLog_robot(tornado.web.RequestHandler):
    def get(self):
        num = self.get_argument("num")
        if num == '0':
            self.write( "begin<br/>" )
            self.finsh()
            cmd = 'tail -f  /var/log/localA.log | grep %s' %(options.name)
            import time
            while True:
                a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
                logs = a.stdout.read()
                a.wait()
                for log in logs.split("\n"):
                    self.write( "%s<br/>"%log )
                    self.flush() 
                time.sleep(1)
        else:
            cmd = 'grep %s /var/log/localA.log | tail -n %s'%(options.name,num)
            a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
            logs = a.stdout.read()
            a.wait()
            for log in logs.split("\n"):
                self.write( "%s<br/>"%log )

class UploadFileHandler(tornado.web.RequestHandler):
    def post(self):
        #文件的暂存路径
        #提取表单中‘name’为‘file’的文件元数据
        file_metas=self.request.files['file']    
        for meta in file_metas:
            #filename=meta['filename']
            filename="conf.lua"
            filepath=os.path.join(options.path,filename)
            #有些文件需要已二进制的形式存储，实际中可以更改
            with open(filepath,'wb') as up:      
                up.write(meta['body'])
        self.write( "done" )

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

class down(tornado.web.RequestHandler):
    def get(self):
        filename = "conf.lua"
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

class MyFile(tornado.web.StaticFileHandler):  
    def set_extra_headers(self, path):  
        self.set_header("Cache-control", "no-cache")  
if __name__ == "__main__":
    tornado.options.parse_command_line()
    app = tornado.web.Application([
        (r"/",main),
        (r"/Start_robot", Start_robot),
        (r"/Stop_robot", Stop_robot),
        (r"/GetLog_robot", GetLog_robot),
        (r'/file',UploadFileHandler),
        (r"/down", down),  
        (r"/new", new),  
        (r"/(.*)", MyFile, {"path":"./"}),  
        ],
        template_path = os.path.join(os.path.dirname(__file__),"html"),
        static_path =os.path.join(os.path.dirname(__file__), "html/bootstrap"),
      debug = True
    )   
    http_server = tornado.httpserver.HTTPServer(app)
    http_server.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()
