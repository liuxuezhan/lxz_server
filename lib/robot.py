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


gHandle = 0
class LoginHandler(tornado.web.RequestHandler):
    def get(self):
        self.render('login.html')

class Start_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle

        name = self.get_argument("name")
        #sub = subprocess.Popen("/home/liuxuezhan/slg/bin/robot 0 robot robot/robot.lua", cwd="/home/liuxuezhan/slg/bin", shell=True)
        cmd = '/usr/bin/killall -9 %s'%(name)
        a = subprocess.Popen(cmd, shell=True)
        a.wait()

        path = '%s/bin'%(self.get_argument("path"))
        cmd = '%s/%s 0 robot robot/robot.lua'%(path,name)
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

        name = self.get_argument("name")
        cmd = '/usr/bin/killall -9 %s'%(name)
        a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True, bufsize=4096)
        a.wait()
        self.write( "done" )

class Set_robot(tornado.web.RequestHandler):
    def get(self):
        num = self.get_argument("num")
        mid = self.get_argument("mid")
        name = self.get_argument("name")
        time = self.get_argument("time")

        cmd = 'sed -i "s#gName.*#gName =\\"%s\\" #g" preload.lua'%(name)
        path = '%s/script/robot'%(self.get_argument("path"))
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

        cmd = 'sh createrobot.sh %s 1 %s'%(name,num)
        path = '%s/plscripts'%(self.get_argument("path"))
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'cp game %s'%(name)
        path = '%s/bin'%(self.get_argument("path"))
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        self.write( "done" )

class GetLog_robot(tornado.web.RequestHandler):
    def get(self):
        name = self.get_argument("name")
        num = self.get_argument("num")
        if num == '0':
            self.write( "begin<br/>" )
            self.finsh()
            cmd = 'tail -f  /var/log/localA.log | grep %s' %(name)
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
            cmd = 'grep %s /var/log/localA.log | tail -n %s'%(name,num)
            a = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
            logs = a.stdout.read()
            a.wait()
            for log in logs.split("\n"):
                self.write( "%s<br/>"%log )

if __name__ == "__main__":
    tornado.options.parse_command_line()
    app = tornado.web.Application([
        (r"/",LoginHandler),
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
