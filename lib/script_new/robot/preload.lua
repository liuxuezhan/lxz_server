--基础库
function print_r(sth)
    if type(sth) ~= "table" then
        if type(sth) == "boolean" then
            if sth then
                cprint("true")
            else
                cprint("true")
            end
        elseif type(sth) == "function" then
            cprint("function")
        else
            cprint(sth.."")
        end
        return
    end

    local space, deep = string.rep(' ', 2), 0
    local function _dump(t)
        local temp = {}

        for k,v in pairs(t) do
            local key = tostring(k)

            if type(v) == "table" then

                deep = deep + 2
                cprint(string.format( "%s[%s]=\n%s(", string.rep(space, deep - 1), key, string.rep(space, deep))) 
                _dump(v)
                cprint(string.format("%s)",string.rep(space, deep)))
                deep = deep - 2

            else
                cprint(string.format("%s[%s]=%s", string.rep(space, deep + 1), key, v)) 
            end 
        end 
    end
    cprint("(")
    _dump(sth)
    cprint(")")
end

function cprint(s,color)--颜色答应
    color = color or "echo -e \"\\033[40;31;2m"
    local cool = color..s.." \\033[0m \""
    os.execute(cool)
end

function lxz(...)--打印lua变量数据到日志文件
    local info = debug.getinfo(2)
    local head = "["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]["..os.date("%Y-%m-%d %X").."]:"
    cprint(head,"echo -e \"\\033[40;34;2m")
    for _,v in pairs({...}) do
        print_r(v)
    end
end
