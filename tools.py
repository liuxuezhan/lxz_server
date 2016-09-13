import tornado.ioloop
import tornado.web
import subprocess
import datetime
import time
from datetime import *

gHandle = 0


class Start(tornado.web.RequestHandler):
    def get(self):
        global gHandle
        #sub = subprocess.Popen("game 3", cwd="/home/loon/code/yuxiang/script", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True,bufsize=4096)
        #sub = subprocess.Popen("game 3", cwd="/home/loon/code/yuxiang/script", shell=True)

        a = subprocess.Popen("/usr/bin/killall -9 robot", shell=True)
        a.wait()

        sub = subprocess.Popen("/home/loon/code/yuxiang/script/game 10", cwd="/home/loon/code/yuxiang/script", shell=True)
        gHandle = sub
        self.write( "done" )


class Stop(tornado.web.RequestHandler):
    def get(self):
        global gHandle
        if gHandle != 0:
            gHandle.terminate()
            gHandle.wait()
            gHandle = 0

        a = subprocess.Popen("killall -9 robot", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True, bufsize=4096)
        a.wait()
        self.write( "done" )

class SetTime(tornado.web.RequestHandler):
    def get(self):
        stime = self.get_argument("time")
        sdate = self.get_argument("date")
        cmd = '/usr/bin/date -s "%s %s"'%(sdate, stime)

        a = subprocess.Popen(cmd, cwd="/home/loon/code/yuxiang/script", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        cur = a.stdout.readline()
        a.wait()

        a = subprocess.Popen("/usr/bin/date", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        cur = a.stdout.readline()
        a.wait()
        self.write( cur )

        a = subprocess.Popen("systemctl restart rsyslog.service", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        cur = a.stdout.readline()
        a.wait()



class GetLog(tornado.web.RequestHandler):
    def get(self):
        a = subprocess.Popen("grep map_10 /var/log/localA.log | tail -n 200", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        logs = a.stdout.read()
        a.wait()
        for log in logs.split("\n"):
            self.write( "%s<br/>"%log )


class ResetTime(tornado.web.RequestHandler):
    def get(self):
        a = subprocess.Popen("/usr/sbin/ntpdate asia.pool.ntp.org", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        cur = a.stdout.readline()
        a.wait()

        a = subprocess.Popen("/usr/bin/date", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        cur = a.stdout.readline()
        a.wait()
        self.write( cur )

class Start_robot(tornado.web.RequestHandler):
    def get(self):
        global gHandle
        a = subprocess.Popen("/usr/bin/killall -9 robot", shell=True)
        a.wait()

        cmd = '%s/bin/robot 0 robot robot/robot.lua'%(self.get_argument("path"))
        path = '%s/bin/robot'%(self.get_argument("path"))

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

        a = subprocess.Popen("killall -9 robot", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True, bufsize=4096)
        a.wait()
        self.write( "done" )

class Set_robot(tornado.web.RequestHandler):
    def get(self):
        num = self.get_argument("num")
        mid = self.get_argument("mid")

        cmd = 'sed -i "s#gMap.*#gMap = %s #g" preload.lua'%(mid)
        path = '%s/script/robot'%(self.get_argument("path"))
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'sed -i "s#gTotalCount.*#gTotalCount = %s #g" preload.lua'%(num)
        path = '%s/script/robot'%(self.get_argument("path"))
        a = subprocess.Popen(cmd, cwd=path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        cmd = 'sh createrobot.sh robot 1 %s'%(num)
        path = '%s/plscripts'%(self.get_argument("path"))
        a = subprocess.Popen(cmd, cwd="/home/liuxuezhan/slg/plscripts", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        ret = a.stdout.read()
        a.wait()
        self.write( "%s<br/>"%ret )

        self.write( "done" )

class GetLog_robot(tornado.web.RequestHandler):
    def get(self):
        a = subprocess.Popen("grep robot /var/log/localA.log | tail -n 200", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        logs = a.stdout.read()
        a.wait()
        for log in logs.split("\n"):
            self.write( "%s<br/>"%log )

class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("<a href=/Start>Start</a></br>")
        self.write("<a href=/Stop>Stop</a></br>")
        #self.write("<a href=/ResetTime>ResetTime</a></br>")
        self.write("<a href=/GetLog>GetLog</a></br>")


        cur = datetime.now()
        sdate = cur.strftime( '%Y-%m-%d' )
        stime = cur.strftime( '%H:%M:%S' )

        sdate = 'Date:<input type="text" name="date" value="%s">'%(sdate)
        stime = 'Time:<input type="text" name="time" value="%s">'%(stime)

        self.write('<form action="/SetTime" method="get">')
        self.write( sdate )
        self.write( stime )
        self.write('<input type="submit" value="SetTime">')
        self.write('</form>')


        self.write("<a href=/Start_robot>Start_robot</a></br>")
        self.write("<a href=/Stop_robot>Stop_robot</a></br>")
        self.write("<a href=/GetLog_robot>GetLog_robot</a></br>")

        path = 'path:<input type="text" name="path" value="/home/liuxuezhan/slg">'
        mid = 'MapId:<input type="text" name="mid" value="10">'
        num = 'Num:<input type="text" name="num" value="10">'

        self.write('<form action="/Set_robot" method="get">')
        self.write( path )
        self.write( mid )
        self.write( num )
        self.write('<input type="submit" value="Set_robot">')
        self.write('</form>')


settings={"debug":True}
application = tornado.web.Application([
    (r"/Start", Start),
    (r"/Stop", Stop),
    (r"/SetTime", SetTime),
    (r"/ResetTime", ResetTime),
    (r"/GetLog", GetLog),
    (r"/Start_robot", Start_robot),
    (r"/Stop_robot", Stop_robot),
    (r"/Set_robot", Set_robot),
    (r"/GetLog_robot", GetLog_robot),
    (r"/", MainHandler),
],**settings)


if __name__ == "__main__":
    application.listen(9000)
    tornado.ioloop.IOLoop.instance().start()
