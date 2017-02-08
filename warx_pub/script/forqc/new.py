import requests
import hashlib
import sys
import os

ret = "_pids = {}\n"
appid = "10000"
mac = "aos"
name = sys.argv[1]
cur = sys.argv[2]

m1 = hashlib.md5()
m1.update(appid + name + mac)
s = m1.hexdigest()
m2 = hashlib.md5()
m2.update(s + "Os3NpXfDJeURCC1W" )
s = m2.hexdigest()

data = {'device_id':name,"signature":s,"login_type":1,'appid':appid, "platform_type":1,"os":mac}
r = requests.post("http://common.tapenjoy.com/index.php/LoginClass/login", data=data)
d = r.json()
ret = ret + '_pids["%s"] = { pid={},open_id="%s",token="%s",signature="%s",time=%d }\n'%(name,d["open_id"],d["token"],d["signature"],int(d["time"]))

m1 = hashlib.md5()
m1.update(appid + d["open_id"] + d["token"])
s = m1.hexdigest()
m2 = hashlib.md5()
m2.update(s + "Os3NpXfDJeURCC1W" )
s = m2.hexdigest()

data = {'open_id':d["open_id"],"signature":s,'appid':appid,"token":d["token"]}
r = requests.post("http://common.tapenjoy.com/index.php/LoginClass/getuserserverlist", data=data)
d2 = r.json()["server_info"]
for k in d2:
    ret = ret + '_pids["%s"].pid[%d] = { map=%d,culture=%d,tm=%d}\n'%(name,int(k["pid"]),int(k["logic"]),int(k["custom"]),int(k["time"]))
print ret
os.system("cp /tmp/new.lua /tmp/new_%s.lua "%(cur))
open("/tmp/new_%s.lua"%(cur),'w').write(ret)
