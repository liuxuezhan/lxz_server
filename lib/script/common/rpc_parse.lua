module("rpchelper",package.seeall)

RpcConfig = {}
RpcConfig.unionmember = {"pid","name","lv","language","rank","title","photo","eid","x","y","pow","online","tm_logout"}

local function get_table_cfg(tab)
	local temp_cfg = {}
	for i=2,#tab do
		temp_cfg[i - 1] = tab[i]
	end	
	return temp_cfg
end

function parse_rpc(src_tab,key)		
	local des_tab = {}
    local cfg_tab = RpcConfig[key] 
	for i=1,#cfg_tab do	
		local arg = cfg_tab[i]	
		if type(arg) == "table" then
			local temp_cfg = get_table_cfg(arg)			
			des_tab[i] = parse_rpc(src_tab[arg[1]],temp_cfg)
		else
			des_tab[i] = src_tab[arg]
		end
	end
	return des_tab
end

function decode_rpc(src_tab,key)
	local des_tab = {}
    local cfg_tab = RpcConfig[key] 
	for i = 1,#cfg_tab do
		local arg = cfg_tab[i]
		if type(arg) == "table" then
			local temp_cfg = get_table_cfg(arg)			
			local temp_key = arg[1]
			if src_tab[i] then
				des_tab[temp_key]  = decode_rpc(src_tab[i],temp_cfg)
			end
		else
			des_tab[arg] = src_tab[i]
		end
	end
	return des_tab
end

-- local src_tab = {name = "张三",eid = 5015222,pid = 5245888,x=312,y=353,power = 434343,photo=1,donate = {donate_cd = 350}}
-- local tab = parse_rpc(src_tab,"unionmember")
-- print_table(tab)
-- local next_tab = decode_rpc(tab,"unionmember")
-- print_table(next_tab)
