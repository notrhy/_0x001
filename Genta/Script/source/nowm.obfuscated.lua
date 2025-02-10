function runCoroutine(func)
    co = coroutine.create(func)
    success, err = coroutine.resume(co)
    if not success then
        logToConsole("Error in coroutine:", err)
    end
end
function collect(a)
    tx = math.floor(a.pos.y/32) == 0 and (a.pos.x + 6) or (a.pos.x + 6 + 32 * (math.floor(a.pos.y/32)))
    pkt = {
        type = 11,
        value = a.oid,
        x = a.pos.x,
        y = a.pos.y,
        punchx = tx,
        punchy = 0
    }
    sendPacketRaw(false, pkt)
end
function scanTree(id)
    countReady, countUnready = 0, 0
    for _, tree in pairs(getTile()) do
        if tree.fg == id then
            if getExtraTile(tree.pos.x, tree.pos.y).ready then
                countReady = countReady + 1
            else
                countUnready = countUnready + 1
            end
        end
    end
    return { Ready = countReady, Unready = countUnready }
end
function scanFossil()
    countFossil = 0
    for _, fossil in pairs(getTile()) do
        if fossil.fg == 3918 then
            countFossil = countFossil + 1
        end
    end
    return countFossil
end
function scanFloat(id)
    countFloat = 0
    for _, obj in pairs(getWorldObject()) do
        if obj.id == id then
            countFloat = countFloat + obj.amount
        end
    end
    return countFloat
end
function cekDiscordID(tabel)
    for _, discordID in pairs(tabel) do
        if discordID == getDiscordID() then
            return true
        end
    end
    return false
end
rhy = {
    inv = function(itemid)
        for _, item in pairs(getInventory()) do
            if item.id == itemid then
                return item.amount
            end
        end
        return 0
    end,
    randomSleep = function(a, b)
        sleep(math.random(a, b))
    end,
    spr = function(a, b, c, d)
        sendPacketRaw(false, {type = a, value = b, punchx = c, punchy = d, x = getLocal().pos.x, y = getLocal().pos.y})
    end,
    checkPath = function(x, y)
        _path0x001 = math.floor(getLocal().pos.x / 32)
        _path0x002 = math.floor(getLocal().pos.y / 32)
        _path0x003 = {}
        _path0x004 = {{x=_path0x001, y=_path0x002, _path0x008 = {}}}
        while #_path0x004 > 0 do
            _path0x005 = table.remove(_path0x004, 1)
            _path0x006, _path0x007 = _path0x005.x, _path0x005.y
            _path0x008 = _path0x005._path0x008
            if _path0x006 == x and _path0x007 == y then
                return _path0x008
            end
            if _path0x006 >= 0 and _path0x006 <= 99 and _path0x007 >= 0 and _path0x007 <= 53 and not _path0x003[_path0x006.."-".._path0x007] then
                _path0x003[_path0x006.."-".._path0x007] = true
                if checkTile(_path0x006, _path0x007).fg == 0 or not checkTile(_path0x006, _path0x007).isCollideable then
                    table.insert(_path0x004, {x = _path0x006 + 1, y = _path0x007, _path0x008 = rhy.copyPath(_path0x008, {_path0x006 + 1, _path0x007})})
                    table.insert(_path0x004, {x = _path0x006 - 1, y = _path0x007, _path0x008 = rhy.copyPath(_path0x008, {_path0x006 - 1, _path0x007})})
                    table.insert(_path0x004, {x = _path0x006, y = _path0x007 + 1, _path0x008 = rhy.copyPath(_path0x008, {_path0x006, _path0x007 + 1})})
                    table.insert(_path0x004, {x = _path0x006, y = _path0x007 - 1, _path0x008 = rhy.copyPath(_path0x008, {_path0x006, _path0x007 - 1})})
                end
            end
        end
        return nil
    end,
    copyPath = function(_path0x008, _path0x009)
         _path0x010 = {}
        for i = 1, #_path0x008 do
            _path0x010[i] = _path0x008[i]
        end
        table.insert(_path0x010, _path0x009)
        return _path0x010
    end,
    moveTo = function(_path0x008, step, path_delay)
        step = step or 1
        path_delay = path_delay or 80
        length = #_path0x008
        for i = 1, length, step do
            if i + step > length then
                nextPos = _path0x008[length]
            else
                nextPos = _path0x008[i]
            end
            nextX, nextY = nextPos[1], nextPos[2]
            findPath(nextX, nextY)
            rhy.randomSleep(path_delay, path_delay + 100)
        end
    end,
    sendCollect = function(a, ItemID)
        localPosX, localPosY = math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)
        for _, v in pairs(getWorldObject()) do
            if v.id ~= 0 and (not ItemID or v.id == ItemID) then
                objPosX, objPosY = math.floor(v.pos.x / 32), math.floor(v.pos.y / 32)
                collectPosX, collectPosY = math.abs(objPosX - localPosX), math.abs(objPosY - localPosY)
                if collectPosX <= a and collectPosY <= a then
                    tx = (objPosY == 0) and (v.pos.x + 6) or (v.pos.x + 6 + 32 * objPosY)
                    sendPacketRaw(false, {type = 11, value = v.oid, x = v.pos.x, y = v.pos.y, punchx = tx, punchy = 0})
                end
            end
        end
    end,
    webhook = function(message, url, msgID)
        content = [=[
        {
            "username": "rhy-test",
            "content": "]=] .. message .. [=["
        }
        ]=]
    
        function sendWebhook(url, content)
            return makeRequest(url, "POST", {["content-type"]="application/json"}, content).content
        end
    
        function patchWebhook(url, msgID, content)
            return makeRequest(url .. "/messages/" .. msgID, "PATCH", {["content-type"]="application/json"}, content).content
        end
    
        if msgID then
            return patchWebhook(url, msgID, content)
        else
            return sendWebhook(url, content)
        end
    end,
    notify = function(message)
        sendVariant({[0] = "OnTextOverlay", [1] = message})
    end,
    logSystem = function(message)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1System`0] `5"..message})
    end,
    drop = function(id)
        while rhy.inv(id) > 0 do
            sendPacketRaw(false, {type = 0, state = 48, x = getLocal().pos.x, y = getLocal().pos.y})
            rhy.randomSleep(1, 100)
            sendPacket(2, "action|drop\n|itemID|" .. id)
            rhy.randomSleep(1300, 1500)
            if  rhy.inv(id) ~= 0 then
                if rhy.checkPath(math.floor(getLocal().pos.x / 32 + 1), math.floor(getLocal().pos.y / 32)) then
                    rhy.moveTo(rhy.checkPath(math.floor(getLocal().pos.x / 32 + 1), math.floor(getLocal().pos.y / 32)))
                    rhy.randomSleep(700, 800)
                else
                    rhy.logSystem("`4Can't move tiles when dropping..")
                    break
                end
            end
        end
        return  rhy.inv(id) == 0
    end,
    log = function(a, b)
        sendVariant({[0] = "OnConsoleMessage", [1] = "`0[`#Dr.Rhy Universe`0][`1"..a.."`0] `5"..b})
    end,
    cek = function(world) 
        while true do
            if string.find(world, "|") then
                save = string.match(world, "([^|]+)")
            else
                save = world
            end
            if string.upper(getWorld().name) == string.upper(save) then
                return true 
            end
            rhy.randomSleep(1574, 1674)
        end
    end,
    warp = function(r)
        sendPacket(3, "action|join_request\nname|"..r.."\ninvitedWorld|0")
    end,
    webhookEmbed = function(title, bot, blabla, url, msgID)
        function checkTime()
            Time = os.date("*t")
            hour = Time.hour
            ampm = "AM"
            if hour >= 12 then
                ampm = "PM"
            end
            if hour > 12 then
                hour = hour - 12
            elseif hour == 0 then
                hour = 12
            end
            
            formatTime = string.format("Rhy Universe | %02d:%02d:%02d %s", hour, Time.min, Time.sec, ampm)
            return formatTime
        end
        content = [=[
        {
            "username": "rhy-webhook",
            "avatar_url": "https://cdn.discordapp.com/attachments/1291822336252710915/1301006314817851422/WM_Copy_2_D3FDA35.jpg",
            "content": "",
            "embeds": [
                {
                    "author": {
                        "name": "! Rhy | Universe 愛",
                        "url": "https://discord.gg/xVyUWvut2D",
                        "icon_url": "https://cdn.discordapp.com/attachments/1291822336252710915/1301007480662524025/970a47d3578d6e6b2c67fce5b7bad69b.jpg"
                    },
                    "title": "]=]..title..[=[",
                    "url": "",
                    "description": "",
                    "color": 1380255,
                    "fields": [
                        {
                            "name": "]=]..bot..[=[",
                            "value": "]=]..blabla:gsub("\n", "\\n")..[=[",
                            "inline": false
                        },
                        {
                            "name": "The Universe",
                            "value": "https://discord.com/invite/xVyUWvut2D"
                        }
                    ],
                    "thumbnail": {
                        "url": "https://cdn.discordapp.com/attachments/1291822336252710915/1301079464171667486/Proyek_Baru_63_0D7B86F.gif"
                    },
                    "image": {
                        "url": ""
                    },
                    "footer": {
                        "text": "]=]..checkTime()..[=[",
                        "icon_url": "https://cdn.discordapp.com/attachments/1291822336252710915/1301008710679789662/1127270711250145341.gif"
                    }
                }
            ]
        }
        ]=]
        function sendWebhook(url, content)
            return makeRequest(url, "POST", {["content-type"] = "application/json"}, content).content
        end
        function patchWebhook(url, msgID, content)
            return makeRequest(url .. "/messages/" .. msgID, "PATCH", {["content-type"] = "application/json"}, content).content
        end
        if msgID then
            return patchWebhook(url, msgID, content)
        else
            return sendWebhook(url, content)
        end
    end,
    embedText = function(a, b)
        embedTeks = [[Status: ]]..a..[[\nSeed: ]]..b..[[\nUptime: <t:]]..currentTime..[[:R>
        ]]
        return embedTeks
    end,
    cekUptime = function(a)
        diff = os.difftime(os.time(), a)
        if diff <= 0 then
            return "00:00:00"
        else
            hours = string.format("%02.f", math.floor(diff / 3600))
            mins = string.format("%02.f", math.floor(diff / 60 - hours * 60))
            secs = string.format("%02.f", math.floor(diff - hours * 3600 - mins * 60))
            return hours .. ":" .. mins .. ":" .. secs
        end
    end,
    watermark = function(name, link)
        return name == "Rhy Universe" and link == "https://discord.com/invite/xVyUWvut2D" or false
    end,
    isOnPos = function(x, y)
        return math.floor(getLocal().pos.x/32) == x and math.floor(getLocal().pos.y/32) == y
    end
}
rhy.logSystem("API Loaded")

await = load(makeRequest("https://raw.githubusercontent.com/notrhy/_0x001/refs/heads/main/Genta/Script/function/func-aw.lua", "GET").content)()
