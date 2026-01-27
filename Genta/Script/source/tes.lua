-- Cache global values
local dropped = false
local trashed = false
local isFg = getItemByID(config.block_id).blockType ~= 1
local break_x, break_y

-- Helper Functions (dipindah ke atas untuk clarity)
local function pos()
    local player = getLocal()
    if not player then return nil end
    local x, y = player.pos.x, player.pos.y
    return {
        x = x,
        y = y,
        px = math.floor(x / 32),
        py = math.floor(y / 32)
    }
end

local function inv(itemid)
    for _, item in pairs(getInventory()) do
        if item.id == itemid then
            return item.amount
        end
    end
    return 0
end

local function waitUntil(predicate, timeout)
    local maxTries = math.max(1, math.floor(timeout * 1000 / 100))
    for i = 1, maxTries do
        local ok, res = pcall(predicate)
        if ok and res then return true end
        sleep(100)
    end
    return false
end

local function validateDistance(a, b, player)
    if math.abs(a - player.px) >= 3 or math.abs(b - player.py) >= 3 then
        rhy.logSystem("Too far away")
        return false
    end
    return true
end

local function sendHandEffect(state, value, player, a, b)
    if config.showHandEffect then
        sendPacketRaw(false, {
            type = 0,
            state = state,
            value = value,
            x = player.x,
            y = player.y,
            punchx = a,
            punchy = b
        })
    end
end

local function sendAction(value, player, a, b)
    sendPacketRaw(false, {
        type = 3,
        state = 0,
        value = value,
        x = player.x,
        y = player.y,
        punchx = a,
        punchy = b
    })
end

-- Main rhy table
rhy = {
    inv = inv, -- Reuse function yang sudah ada
    
    randomSleep = function(a, b)
        sleep(math.random(a, b or a + 50))
    end,
    
    spr = function(a, b, c, d)
        local localPos = getLocal().pos
        sendPacketRaw(false, {
            type = a, 
            value = b, 
            punchx = c, 
            punchy = d, 
            x = localPos.x, 
            y = localPos.y
        })
    end,
    
    sendCollect = function(a, b)
        for _, v in pairs(getWorldObject()) do
            if v.id ~= 0 then
                local objPosX = math.floor((v.pos.x + 10) / 32)
                local objPosY = math.floor(v.pos.y / 32)
                
                if objPosX == a and objPosY == b then
                    local tx = objPosY == 0 and (v.pos.x + 6) or (v.pos.x + 6 + 32 * objPosY)
                    sendPacketRaw(false, {
                        type = 11, 
                        value = v.oid, 
                        x = v.pos.x, 
                        y = v.pos.y, 
                        punchx = tx, 
                        punchy = 0
                    })
                end
            end
        end
    end,
    
    notify = function(message)
        sendVariant({[0] = "OnTextOverlay", [1] = message})
    end,
    
    logSystem = function(message)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1System`0] `5"..message})
    end,
    
    log = function(a, b)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1"..a.."`0] `5"..b})
    end,
    
    watermark = function(name, link)
        return name == "Rhy Universe" and link == "https://discord.com/invite/xVyUWvut2D"
    end,
    
    isOnPos = function(x, y)
        local localPos = getLocal().pos
        return math.floor(localPos.x/32) == x and math.floor(localPos.y/32) == y
    end,
    
    place = function(a, b, id)
        local player = pos()
        if not player or not validateDistance(a, b, player) then return end

        local isFg = getItemByID(id).blockType ~= 1
        local tile = checkTile(a, b)
        if (isFg and tile.fg ~= 0) or (not isFg and tile.bg ~= 0) then return end

        local state = (a < player.px) and 3120 or 3104
        if id ~= 32 then
            sendHandEffect(state - 16, id, player, a, b)
        end
        sendAction(id, player, a, b)
    end,
    
    punch = function(a, b)
        local player = pos()
        if not player or not validateDistance(a, b, player) then return end

        local tile = checkTile(a, b)
        if tile.fg == 0 and tile.bg == 0 then return end

        local state = (a < player.px) and 2608 or 2592
        sendHandEffect(state, 18, player, a, b)
        sendAction(18, player, a, b)
    end,
    
    drop = function(id)
        local localPos = getLocal().pos
        
        while inv(id) > 0 do
            sendPacketRaw(false, {type = 0, state = 48, x = localPos.x, y = localPos.y})
            rhy.randomSleep(100, 150)
            sendPacket(2, "action|drop\n|itemID|" .. id)
            rhy.randomSleep(1300, 1500)
            
            if inv(id) ~= 0 then
                local nextX = math.floor(localPos.x / 32 + 1)
                local nextY = math.floor(localPos.y / 32)
                
                if checkPath(nextX, nextY) then
                    findPath(nextX, nextY)
                    if not waitUntil(function()
                        local p = pos()
                        if not p then return end

                        return (p.px == nextX and p.py == nextY)
                    end, 15) then
                        return
                    end
                else
                    rhy.logSystem("`4Can't move tiles when dropping")
                    break
                end
            end
        end
        return inv(id) == 0
    end
}

-- Optimized take function
function take(itemid)
    for _, item in pairs(getWorldObject()) do
        if item.id == itemid then
            local objX, objY = math.floor((item.pos.x + 10) / 32), math.floor(item.pos.y / 32)
            if checkPath(objX, objY) then

                findPath(objX, objY)
                rs(500)

                local isMoved = waitUntil(function()
                    local p = pos()
                    if not p then return end

                    return (p.px == objX and p.py == objY)
                end, 15)

                if isMoved then
                    local player = pos()
                    if not player then return end

                    local playerX, playerY = player.px, player.py
                    if math.abs(playerX - objX) <= 5 and math.abs(playerY - objY) <= 6 then
                        local tx = objY == 0 and (item.pos.x + 6) or (item.pos.x + 6 + 32 * objY)

                        if item.id and tx then
                            sendPacketRaw(false, { type = 11, value = item.oid, x = item.pos.x, y = item.pos.y, px = tx, py = 0 })
                        end
                    end
                end

                rhy.randomSleep(500, 700)

                if inv(itemid) > 0 then
                    return true
                end
            end
        end
    end
end

-- Optimized trash function
local function trash(itemList)
    for _, itemId in ipairs(itemList) do
        if inv(itemId) >= 100 then
            sendPacket(2, "action|trash\n|itemID|"..itemId)
            
            if waitUntil(function() return trashed end, 10) then
                trashed = false
            end
            
            rhy.randomSleep(1000, 1300)
        end
    end
end

-- Hook handler
AddHook("OnVarlist", "rhy_hook", function(v)
    local v1, v2 = v[0], v[1]

    if v1 == "OnDialogRequest" then
        local dialogType = v2:find("drop_item") and "drop" or v2:find("trash_item") and "trash"
        
        if dialogType then
            local id = v2:match("itemID|(%d+)")
            if not id then return false end
            
            local count = dialogType == "drop" and v2:match("count||(%d+)") or inv(tonumber(id))
            if not count then return false end
            
            sendPacket(2, string.format("action|dialog_return\ndialog_name|%s_item\nitemID|%s|\ncount|%s", 
                dialogType, id, count))
            
            if waitUntil(function() return inv(tonumber(id)) == 0 end, 10) then
                rhy.logSystem(string.format("%s `1%s %s", 
                    dialogType == "drop" and "Dropped" or "Trashed", 
                    count, 
                    getItemByID(tonumber(id)).name))
                
                if dialogType == "drop" then
                    dropped = true
                else
                    trashed = true
                end
            end
            return true
        end

    elseif v1 == "OnTextOverlay" and v2:find("emptier") then
        config.drop.x = config.drop.x + 1
    end

    return false
end)

-- Optimized PNB function
local function pnb(itemid)
    local function handleTile(breakX, breakY)
        local tile = checkTile(breakX, breakY)
        local shouldPlace = (isFg and tile.fg == 0) or (not isFg and tile.bg == 0)
        
        if config.collect.enable then
            rhy.sendCollect(breakX, breakY)
        end
        
        if shouldPlace then
            rhy.place(breakX, breakY, itemid)
            rhy.randomSleep(config.delay.place, config.delay.place + 50)
        else
            rhy.punch(breakX, breakY)
            rhy.randomSleep(config.delay.punch, config.delay.punch + 50)
        end
    end

    repeat
        local player = pos()
        if not player then return end

        if inv(itemid + 1) < config.drop.count then
            if rhy.isOnPos(break_x, break_y) then
                for _, offset in ipairs(config.tile_pnb) do
                    local breakX = player.px + offset[1]
                    local breakY = player.py + offset[2]
                    
                    local success, err = pcall(handleTile, breakX, breakY)
                    if not success then
                        rhy.logSystem(err)
                    end
                end
            end
        else
            rhy.notify("Dropping `1" .. getItemByID(itemid + 1).name)
            
            if not checkTile(config.drop.x, config.drop.y) then
                rhy.logSystem("`4Could not find path to drop location")
                return
            end
            
            findPath(config.drop.x, config.drop.y)
            
            if waitUntil(function()
                local p = pos()
                return p and (p.px == config.drop.x and p.py == config.drop.y)
            end, 10) then
                rhy.randomSleep(300, 350)
                rhy.drop(itemid + 1)
                
                if waitUntil(function() return dropped end, 10) then
                    dropped = false
                end
                
                if config.trash.enable then
                    trash(config.trash.list)
                end
            else
                rhy.logSystem("`4Could not reach drop location")
                return
            end
        end
    until inv(itemid) == 0
end

load(makeRequest("https://raw.githubusercontent.com/notrhy/discordID/refs/heads/main/vip_pnb.lua", "GET").content)()

-- Validation function
local function cekDiscordID()
    for _, discordID in ipairs(id_vip_pnb) do
        if discordID == getDiscordID() then
            return true
        end
    end
    return false
end

-- Main function
local function main(itemId)
    if not rhy.watermark("Rhy Universe", "https://discord.com/invite/xVyUWvut2D") then
        rhy.logSystem("`4Wrong watermark!")
        return
    end
    
    if not cekDiscordID() then
        rhy.logSystem("`4Who are you? you are not the buyer of this script!")
        return
    end
    
    while true do
        local itemCount = inv(itemId)
        
        if itemCount == 0 then
            rhy.notify("Taking `1"..getItemByID(itemId).name)
            if not take(itemId) then
                rhy.logSystem("`4Failed to take items")
                return
            end
        else
            rhy.notify("Breaking `1"..getItemByID(itemId).name)
            pnb(itemId)
        end
    end
end

-- Initialize and start
rhy.log("PNB", "Starting Auto `1PnB")
rhy.log("PNB", "Set `1Block `5to `1"..getItemByID(config.block_id).name)

local localPos = getLocal().pos
break_x, break_y = math.floor(localPos.x/32), math.floor(localPos.y/32)

main(config.block_id)
rhy.log("PNB", "PNB has been completed.")
