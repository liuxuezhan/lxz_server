module("socket", package.seeall)

function open(host, port)
    return connect(host, port, 0, 2)
end

function close(fd)
    pushOver()
    pushHead(0, 5, fd)
    pushOver()
end

function read(fd)
    return pullPkg(fd)
end

function write(fd, buf)
    pushPkg(fd, buf)
end
