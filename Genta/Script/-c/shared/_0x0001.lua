rhy = {
    inv = function(itemid)
        local inventory = getInventory()
        if not inventory then return 0 end
        for _, item in pairs(inventory) do
            if item.id == itemid then
                return item.amount
            end
        end
        return 0
    end,
    randomSleep = function(a, b)
        sleep(math.random(a, b))
    end,
    notify = function(message)
        sendVariant({[0] = "OnTextOverlay", [1] = message})
    end,
    logSystem = function(message)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1System`0] `5"..message})
    end,
    drop = function(id, maxRetries)
        maxRetries = maxRetries or 5
        local retries = 0
    
        while rhy.inv(id) > 0 and retries < maxRetries do
            local playerPos = getLocal().pos
            if not playerPos then break end
        
            sendPacketRaw(false, {type = 0, state = 48, x = playerPos.x, y = playerPos.y})
            rhy.randomSleep(50, 100)
            sendPacket(2, "action|drop\n|itemID|" .. id)
        
            local dropped = waitUntil(function()
                return rhy.inv(id) == 0
            end, 2)
        
            if not dropped then
                local tileX = math.floor(playerPos.x / 32)
                local tileY = math.floor(playerPos.y / 32)
            
                if checkPath(tileX + 1, tileY) then
                    findPath(tileX + 1, tileY)
                    rhy.randomSleep(500, 600)
                else
                    rhy.logSystem("`4Can't move tiles when dropping..")
                    break
                end
            end
        
            retries = retries + 1
            rhy.randomSleep(300, 500)
        end
    
        return rhy.inv(id) == 0
    end,
    log = function(a, b)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1"..a.."`0] `5"..b})
    end,
    cek = function(world, timeout) 
        timeout = timeout or 30
        local endTime = os.time() + timeout
        local save = string.find(world, "|") and string.match(world, "([^|]+)") or world
    
        while os.time() < endTime do
            local currentWorld = getWorld()
            if currentWorld and string.upper(currentWorld.name) == string.upper(save) then
                return true 
            end
            rhy.randomSleep(1574, 1674)
        end
        return false
    end,
    warp = function(r)
        sendPacket(3, "action|join_request\nname|"..r.."\ninvitedWorld|0")
    end,
    watermark = function(name, link)
        return name == "Rhy Universe" and link == "https://discord.com/invite/xVyUWvut2D" or false
    end,
    isOnPos = function(x, y)
        return math.floor(getLocal().pos.x/32) == x and math.floor(getLocal().pos.y/32) == y
    end
}

local dropped = false

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

function waitUntil(predicate, timeout)
    local startTime = os.clock()
    local maxTime = timeout or 15
    
    while (os.clock() - startTime) < maxTime do
        local ok, res = pcall(predicate)
        if ok and res then
            return true
        end
        sleep(100)
    end
    return false
end

function take(itemid)
    for _, item in pairs(getWorldObject()) do
        if item.id == itemid then
            local objX, objY = math.floor((item.pos.x + 10) / 32), math.floor(item.pos.y / 32)
            if checkPath(objX, objY) then
                findPath(objX, objY)
                rhy.randomSleep(200, 300)
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

                if rhy.inv(itemid) > 0 then
                    return true
                end
            end
        end
    end
end

AddHook("OnVarlist", "rhy_hook", function(v)
    local packetType, packetContent = v[0], v[1]
    if packetType:find("OnDialogRequest") and packetContent:find("drop_item") then
        local ca, id = packetContent:match("count||(%d+)"), packetContent:match("itemID|(%d+)")
        sendPacket(2, string.format("action|dialog_return\ndialog_name|drop_item\nitemID|%s|\ncount|%s", id, ca))

        local isDropped = waitUntil(function()
            return (rhy.inv(id) == 0)
        end, 15)

        if isDropped then
            rhy.logSystem(string.format("Dropped `1%s %s", ca, getItemByID(id).name))
            dropped = true
        end
        return true
    elseif packetType:find("OnTextOverlay") and packetContent:find("emptier") then
        drop_x = drop_x + 1
    end
    return false
end)

load(makeRequest("https://raw.githubusercontent.com/notrhy/discordID/refs/heads/main/vip_wtw.lua", "GET").content)()

function cekDiscordID(tabel)
    local discordUserID = getDiscordID()
    for _, discordID in pairs(tabel) do
        if discordID == discordUserID then
            return true
        end
    end
    return false
end

function main()
    if not rhy.watermark("Rhy Universe", "https://discord.com/invite/xVyUWvut2D") then
        rhy.logSystem("`4Wrong watermark!")
        return
    end
    if not cekDiscordID(id_vip_wtw) then
        rhy.logSystem("`4Who are you? You are not the buyer of this script!")
        return
    end
    while true do 
        if rhy.inv(item_id) < 200 then
            rhy.notify("Taking items..")
            rhy.warp(world1)
            if rhy.cek(world1) then
                rhy.randomSleep(delay_after_warp, delay_after_warp + 500)
                if not take(item_id) then
                    rhy.logSystem("`4Failed to take items. Exiting script.")
                    return
                end
                rhy.randomSleep(50, 150)
            else
                rhy.logSystem("`4Failed to warp to `1"..world1)
                return
            end
        else
            rhy.notify("Moving to drop point..")
            rhy.warp(world2)
            if rhy.cek(world2) then
                rhy.randomSleep(delay_after_warp, delay_after_warp + 500)

                local drop_path = checkPath(drop_x, drop_y)
                if drop_path then
                    findPath(drop_x, drop_y)
                    rhy.randomSleep(300, 500)
                else
                    rhy.logSystem("`4Couldn't find a path to drop position.")
                    return
                end

                local isCorrectDropPath = waitUntil(function()
                    local player = pos()
                    if not player then return end

                    return (player.px == drop_x and player.py == drop_y)
                end, 15)

                if isCorrectDropPath then
                    rhy.randomSleep(300, 400)
                    local player = pos()
                    if player then
                        sendPacketRaw(false, {type = 0, state = 48, x = player.x, y = player.y})
                        rhy.randomSleep(10, 20)
                    end
                    rhy.drop(item_id)
                    rhy.randomSleep(300, 500)
                    waitUntil(function()
                        return dropped
                    end, 15)
                    dropped = false
                end
            else
                rhy.logSystem("`4Failed to warp to `1"..world2)
                return
            end
        end
    end
end

rhy.log("System","Script Loaded.")

rhy.log("Move WTW","Starting `1Move")
rhy.log("Move WTW","Set `1Item `5to `1"..getItemByID(item_id).name)
toggleCheat(26, true)
main()
rhy.log("Move WTW","Move has been completed.")
