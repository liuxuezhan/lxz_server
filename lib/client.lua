require "robot"

_num = 1 --机器人数量
_conf = { --机器人操作集合
			{"open","192.168.103.225",8001,"10000","pwd","game_server"},
			--{"open","127.0.0.1",8001,"10000","pwd","game_server1"},
			{"send","cs_enter",},
			{"close"},
	}
function robot_init(id)--初始化配置
    robot.robot_init(id,_num,_conf)
end

function robot_start()--开始执行
    robot.robot_start(_num,_conf)
end


