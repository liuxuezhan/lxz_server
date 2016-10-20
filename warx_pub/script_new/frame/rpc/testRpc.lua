module("ProtoclImp", package.seeall)


function hello( id, pid, text )
    print("####Hello", id, pid, text) 
end

function onLogin( pid, name )
    print("onLogin", pid, name)
end

