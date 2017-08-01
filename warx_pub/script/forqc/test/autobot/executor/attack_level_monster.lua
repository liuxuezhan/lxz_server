local AttackLevelMonster = {}

AttackLevelMonster.__index = AttackLevelMonster

local REGION_WIDTH = 16
local SEARCH_DISTANCE = 2
local REGION_SEARCH_INTERVAL = 3

local layer_info =                                                           
{                                                                            
    {-1, -1, 1, 0},                                                          
    {1, -1, 0, 1},                                                           
    {1, 1, -1, 0},                                                           
    {-1, 1, 0, -1},                                                          
}                                                                            

local function regions(max_layer)                                                  
    local function circle(layer)                                             
        for k, v in ipairs(layer_info) do                                    
            local start_x = layer * v[1]                                     
            local start_y = layer * v[2]                                     
            local count = layer * 2                                          
            for i = 0, count - 1 do                                          
                coroutine.yield(start_x + v[3] * i, start_y + v[4] * i)      
            end                                                              
        end                                                                  
    end                                                                      

    local function all_regions()                                             
        coroutine.yield(0, 0)                                                
        for i = 1, max_layer do                                              
            circle(i)                                                        
        end                                                                  
    end                                                                      

    return coroutine.wrap(all_regions)
end                                                                          

function AttackLevelMonster.create(...)
    local obj = setmetatable({}, AttackLevelMonster)
    obj:init(...)
    return obj
end

function AttackLevelMonster:init(player, monster_type, level)
    player.__executors = player.__executors or {}
    player.__executors[self] = true
    self.player = player
    self.monster_type = monster_type
    self.level = level
end

local function _onNewEntity(self, player, entity)
    self:_attackEntity(entity)
end

function AttackLevelMonster:_attackEntity(entity)
    local function get_type(mode)
        if mode <= 30 then --普通
            return 1
        elseif mode > 30 and mode <= 40 then --精英
            return 2
        elseif mode > 40 and mode <= 50 then --首领
            return 3
        elseif mode > 50 and mode <= 100 then --超级首领
            return 4
        else -- 任务
            return 5
        end
    end
    if not is_monster(entity) then
        return
    end
    local prop = resmng.prop_world_unit[entity.propid]
    if not prop then
        return
    end
    if prop.Clv == self.level then
        if 0 == self.monster_type or get_type(prop.Mode) == self.monster_type then
            local armys = {}
            local count = self.player:get_val("CountSoldier")
            for id, num in pairs(self.player._arm) do
                if num < count then
                    armys[id] = num
                    count = count - num
                else
                    armys[id] = count
                    count = 0
                    break
                end
                INFO("[Autobot|AttackLevelMonster|%d]start march to attack level monster %d|%d", self.player.pid, entity.eid, self.monster_type)
                Rpc:siege(self.player, entity.eid, {live_soldier = armys})
                -- TODO: 应该监控行军线及结果（添加行军线的monitor，而不是finish executor）
                self:_finishExecutor()
                return true
            end
        end
    end
end

local function _onNewEntities(self, player)
    action(function()
        wait_for_time(REGION_SEARCH_INTERVAL)
        self:_getNextRegionEntities()
    end)
end

function AttackLevelMonster:start()
    -- TODO: 需要添加监控，如果没杀死怎么办呢？
    -- 搜寻当前entity列表
    for k, v in pairs(self.player._etys) do
        if self:_attackEntity(v) then
            return
        end
    end
    self.running = true
    -- 没找到则搜寻其他列表
    self.player.eventNewEntity = self.player.eventNewEntity or newEventHandler()
    self.player.eventNewEntity:add(newFunctor(self, _onNewEntity))
    self.player.eventNewEntities = self.player.eventNewEntities or newEventHandler()
    self.player.eventNewEntities:add(newFunctor(self, _onNewEntities))
    self.regions_it = regions(SEARCH_DISTANCE)
    self.player_x = math.floor(self.player.x / REGION_WIDTH)
    self.player_y = math.floor(self.player.y / REGION_WIDTH)
    Rpc:remEye(self.player)
    self:_getNextRegionEntities()
end

function AttackLevelMonster:_getNextRegionEntities()
    if not self.running then
        INFO("[Autobot|AttackLevelMonster|%d]it's finished", self.player.pid)
        return
    end
    local x, y = self.regions_it()
    if nil == x then
        self:_finishExecutor()
        INFO("[Autobot|AttackLevelMonster|%d]Not found monster", self.player.pid)
        return
    end
    INFO("[Autobot|AttackLevelMonster|%d]search monster in region(%d,%d)", self.player.pid, self.player_x + x, self.player_y + y)
    x = (self.player_x + x) * REGION_WIDTH + math.floor(REGION_WIDTH / 2)
    y = (self.player_y + y) * REGION_WIDTH + math.floor(REGION_WIDTH / 2)
    Rpc:movEye(self.player, gMapID, x, y)
end

function AttackLevelMonster:_finishExecutor()
    if self.player.eventNewNtity then
        self.player.eventNewEntity:del(newFunctor(self, _onNewEntity))
    end
    if self.player.eventNewEntities then
        self.player.eventNewEntities:del(newFunctor(self, _onNewEntities))
    end
    self.player.__executors[self] = nil
    self.running = nil
end

return AttackLevelMonster

