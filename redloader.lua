local config = {
    ["modem_side"] = "back",
    ["whitelist"] = {
        [9] = true
    },
    ["key"] = "1wi7i9h15p4rk73",
    ["channel_update"] = "__update__",
    ["channel_reset"] = "__reset__",
    ["tries"] = 3,
    ["timeout"] = 5,
    ["default"] = "default"
}

function prepareFs(file)
    if(fs.exists(file)) then
        if(fs.isDir(file)) then
            fs.delete(file)
        end
        return
    end
    local parent = fs.getDir(file)
    while(parent ~= "..") do
        if(fs.exists(parent) and not fs.isDir(parent)) then
            fs.delete(parent)
        end
        parent = fs.getDir(parent)
    end
end

function listenReset()
    while(true) do
        local id, msg = rednet.receive(config.channel_reset)
        local err, errmsg = pcall(function()
            if(config.whitelist ~= nil and not config.whitelist[id]) then
                error("Server not whitelisted")
            end
            local resetmsg = textutils.unserialize(msg)
            if(config.key ~= nil and resetmsg.key ~= config.key) then
                error("Secret key doesn't match")
            end
            if(resetmsg.reset) then
                os.reboot()
            end
        end)
        if(not err) then
            print(string.format("[REDLOADER] Won't reset from %d: %s", id, errmsg))
        end
    end
end

function listenUpdate()
    while(true) do
        local id, msg = rednet.receive(config.channel_update)
        local err, errmsg = pcall(function()
            if(config.whitelist ~= nil and not config.whitelist[id]) then
                error("Server not whitelisted")
            end
            local bootframe = textutils.unserialize(msg)
            if(config.key ~= nil and bootframe.key ~= config.key) then
                error("Secret key doesn't match")
            end
            for fname, content in pairs(bootframe.data) do
                prepareFs(fname)
                local flhndl = fs.open(fname, "w")
                flhndl.write(content)
                flhndl.close()
            end
        end)
        if(not err) then
            print(string.format("[REDLOADER] Won't update from %d: %s", id, errmsg))
        end
    end
end

print("[REDLOADER]")
rednet.open(config.modem_side)

local threads = {
    listenReset,
    listenUpdate}

if(config.default ~= nil) then
    table.insert(threads, function() shell.run(config.default) end)
end

parallel.waitForAll(unpack(threads))
