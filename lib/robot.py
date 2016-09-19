#!/usr/bin/python
#coding=utf-8
import os.path

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
define("port", default=int(sys.argv[1]), help="输入端口号", type=int)
define("name", default=sys.argv[2], help="输入机器人名字", type=str)
define("path", default=sys.argv[3], help="路径", type=str)


gHandle = 0
class main(tornado.web.RequestHandler):
    def get(self):
        self.render('robot.html')

class Start_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle

        #sub = subprocess.Popen("/home/liuxuezhan/slg/bin/robot 0 robot robot/robot.lua", cwd="/home/liuxuezhan/slg/bin", shell=True)
        cmd = '/usr/bin/killall -9 %s'%(options.name)
        a = subprocess.Popen(cmd, shell=True)
        a.wait()

        cmd = '%s/bin/%s 0 robot robot/robot.lua'%(options.path,options.name)
        path = '%s/bin'%(options.path)
        sub = subprocess.Popen(cmd, cwd=path, shell=True)
        gHandle = sub
        self.write( "done" )


class Stop_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle
        if gHandle != 0:
            gHandle.terminate()
            gHandle.wait()
            gHandle = 0

        cmd = '/usr/bin/killall -9 %s'%(options.name)
        a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True, bufsize=4096)
        a.wait()
        self.write( "done" )

class Set_robot(tornado.web.RequestHandler):
    def get(self):
        num = self.get_argument("num")
        mid = self.get_argument("mid")
        time = self.get_argument("time")

        cmd = 'sed -i "s#gName.*#gName =\\"%s\\" #g" preload.lua'%(options.name)
        path = '%s/script/robot'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        self.write( "%s<br/>"%ret )
        cmd = 'sed -i "s#gMap.*#gMap = %s #g" preload.lua'%(mid)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'sed -i "s#gTotalCount.*#gTotalCount = %s #g" preload.lua'%(num)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'sed -i "s#gTotalTime.*#gTotalTime = %s #g" preload.lua'%(time)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'sh createrobot.sh %s 1 %s'%(options.name,num)
        path = '%s/plscripts'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'cp game %s'%(options.name)
        path = '%s/bin'%(options.path)
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

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

if __name__ == "__main__":
    tornado.options.parse_command_line()
    app = tornado.web.Application([
        (r"/",main),
        (r"/Start_robot", Start_robot),
        (r"/Stop_robot", Stop_robot),
        (r"/Set_robot", Set_robot),
        (r"/GetLog_robot", GetLog_robot),
        ],
        template_path = os.path.join(os.path.dirname(__file__),"html"),
        static_path =os.path.join(os.path.dirname(__file__), "html/bootstrap"),
      debug = True                                     
          )   
    http_server = tornado.httpserver.HTTPServer(app)
    http_server.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()
