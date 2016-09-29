#-*- coding: utf-8 -*-
#!/usr/bin/python 

import paramiko
import threading
import signal

def ssh2(ip,username,passwd):
    print "%s 开始......"%ip
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,username,passwd,timeout=10)
        cmd = "y"
        for m in open("conf.sh"): 
            print m 
            if "echo" in m:
                cmd = raw_input('%s执行:'%(m))
            if "n" in cmd:
                continue
            cmd = "y"
            stdin, stdout, stderr = ssh.exec_command(m)
            stdin.write("Y")   #简单交互，输入 ‘Y’ 
            out = stdout.readlines()
            #屏幕输出
            for o in out:
                print o,
        print '%s\t完成\n'%(ip)
        ssh.close()
    except :
        print '%s\tError\n'%(ip)

def sig_handler(sig, frame):
    try:
        for k in thr: 
            thr[k].stop()
            thr[k].join()
    except Exception, ex:
        exit(0)

if __name__=='__main__':

    username = "root"  #用户名
    passwd = "aktlakfh!@34"    #密码
    thr = {}   #多线程
    signal.signal(signal.SIGTERM, sig_handler)
    signal.signal(signal.SIGINT, sig_handler)
    for i in range(9,10):
        ip = '175.124.123.'+str(i)
        a=threading.Thread(target=ssh2,args=(ip,username,passwd))
        #a.setDaemon('True')
        thr[ip] = a  
        a.start()

