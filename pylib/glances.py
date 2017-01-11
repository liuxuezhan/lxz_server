#!/usr/bin/python
# -*- coding: utf-8 -*-
import psutil;
import sys;
 
def tryPsutil():
    pidList = psutil.get_pid_list();
    print "pidList=",pidList;
     
    processToTest = "vim";
     
    for eachPid in pidList:
        try:
            p = psutil.Process(eachPid);
            processName = p.name();
            if(processName.lower() == sys.argv[1].lower()):
                print "Found process";
                print "processName=",processName;
                processExe = p.exe();
                print "processExe=",processExe;
                processGetcwd = p.getcwd();
                print "processGetcwd=",processGetcwd;
                processCmdline = p.cmdline();
                print "processCmdline=",processCmdline;
                processStatus = p.status();
                print "processStatus=",processStatus;
                processUsername = p.username();
                print "processUsername=",processUsername;
                processCreateTime = p.create_time();
                print "processCreateTime=",processCreateTime;
                print "mem=",p.memory_info();
                print "cpu=",p.cpu_percent(interval=1);
                print "cpu=",p.cpu_percent(interval=1);
                print "Now will terminate this process !";
                #p.terminate();
                #p.wait(timeout=3);
                #print "psutil.test()=",psutil.test();
                 
        except psutil.NoSuchProcess,pid:
            print "no process found with pid=%s"%(pid);
 
if __name__ == "__main__":
    tryPsutil();
