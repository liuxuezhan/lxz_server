module("rpchelper",package.seeall)

RpcConfig = {}
RpcConfig.unionmember = {"pid","name","lv","language","rank","title","photo","eid","x","y","pow","tm_login","tm_logout","buildlv","propid"}
RpcConfig.union = {
                    "uid","new_union_sn","name","alias","mars_propid","membercount","memberlimit","language","flag","","note_in","leader","pow","tm_buf_over",
                    {"enlist","text","lv","pow","check",},"state","range"
                }

local function get_table_cfg(tab)
	local temp_cfg = {}
	for i=2,#tab do
		temp_cfg[i - 1] = tab[i]
	end	
	return temp_cfg
end

local function parse_by_table(src_tab,cfg_tab)	
	local des_tab = {}
	if not cfg_tab then return des_tab end
	for i=1,#cfg_tab do	
		local arg = cfg_tab[i]	
		if type(arg) == "table" then
			local temp_cfg = get_table_cfg(arg)			
			des_tab[i] = parse_by_table(src_tab[arg[1]],temp_cfg)
		else
			des_tab[i] = src_tab[arg]
		end
	end
	return des_tab	
end

function parse_rpc(src_tab,key)
    return parse_by_table(src_tab, RpcConfig[key])
end

local function decode_by_table( src_tab,cfg_tab )
	local des_tab = {}
	if not cfg_tab then return des_tab end
	for i = 1,#cfg_tab do
		local arg = cfg_tab[i]
		if type(arg) == "table" then
			local temp_cfg = get_table_cfg(arg)			
			local temp_key = arg[1]
			if src_tab[i] then
				des_tab[temp_key]  = decode_by_table(src_tab[i],temp_cfg)
			end
		else
			des_tab[arg] = src_tab[i]
		end
	end
	return des_tab
end

function decode_rpc(src_tab,key)
	return decode_by_table(src_tab,RpcConfig[key])	
end
