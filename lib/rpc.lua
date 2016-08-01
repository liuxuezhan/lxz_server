--数据定时保存模块
local mode = {}
mode.key = {
   member = 1, 

}
mode.list = {}
mode.list[mode.key.member] = {"pid","name","lv","language","rank","title","photo","eid","x","y","pow","online","tm_logout"}

function mode.get(tab)
    local temp_cfg = {}
    for i=2,#tab do
        temp_cfg[i - 1] = tab[i]
    end 
    return temp_cfg
end

function mode.pack(src_tab,key)     
    local des_tab = {}
    local cfg_tab = list[key] 
    for i=1,#cfg_tab do 
        local arg = cfg_tab[i]  
        if type(arg) == "table" then
           local temp_cfg = mode.get(arg)         
            des_tab[i] = mode.pack(src_tab[arg[1]],temp_cfg)
        else
            des_tab[i] = src_tab[arg]
        end
    end
    return des_tab
end

function mode.unpack(src_tab,key)
    local des_tab = {}
    local cfg_tab = list[key] 
    for i = 1,#cfg_tab do
        local arg = cfg_tab[i]
        if type(arg) == "table" then
            local temp_cfg = mode.get(arg)         
            local temp_key = arg[1]
            if src_tab[i] then
                des_tab[temp_key]  = mode.unpack(src_tab[i],temp_cfg)
            end
        else
            des_tab[arg] = src_tab[i]
        end
    end
    return des_tab
end

return mode



