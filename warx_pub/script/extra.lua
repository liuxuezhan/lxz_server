player_t.gClientExtra = [[
--监听玩家延迟情况
if join_run_delay ~= nil then
  stop_delay(join_run_delay)
end
local max_ping_count = 20
local ping_count = 0

local function start_join_run_delay_ping()
  join_run_delay = delay(function()
      ping_count = 0
      join_run_delay_table = {}
      Rpc:say1(tostring(os.clock()),0)
    end,20)
end

function ProtocolImp.say1(data,type)
  local cur_time = os.clock()
  local remote_time = tonumber(data)
  local last = cur_time - remote_time
  ping_count = ping_count+1
  table.insert(join_run_delay_table,last)

  if ping_count < max_ping_count then
    Rpc:say1(tostring(os.clock()),0)
  else
    local min = 100000
    local max = -100000
    local ava = 0
    for i,v in ipairs(join_run_delay_table) do
      ava = ava+v
      min = math.min(min,v)
      max = math.max(max,v)
    end
    ava = ava/max_ping_count
    Rpc:say1(string.format("min,%d,max,%d,ava,%d",min*1000,max*1000,ava*1000),1)
    start_join_run_delay_ping()
  end
end
start_join_run_delay_ping()


]]
