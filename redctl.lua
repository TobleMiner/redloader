tArgs = { ... }

--[[
Usage: redctl <reset/update> <id> [fs]
Parameter fs is only requiered together with update
If fs is a directory all files from the directory and its subdirectories will
be uploaded to id

Examples:
    redctl reset 112
    redctl update 112 /farm
    redctl update 112 /farm/growWeed
]]
local config = {
    ["modem_side"] = "back",
    ["key"] = "1wi7i9h15p4rk73", --Secret key needed to reset/update this PC (optional)
    ["channel_update"] = "__update__", --Rednet protocol for updates
    ["channel_reset"] = "__reset__" --Rednet protocol for reset messages
}

function printUsage()
    error("Usage: redctl <reset/update> <id> [fs]")
end

function getFiles(dir)
    local files = { }
    if(fs.isDir(dir)) then
        for _, file in pairs(fs.list(dir)) do
            for _, fname in pairs(getFiles(fs.combine(dir, file))) do
                table.insert(files, fname)
            end
        end
    else
        table.insert(files, dir)
    end
    return files
end

function relatePath(base, path)
    path = shell.resolve(path)
    base = shell.resolve(base)
    return path:gsub(base, "", 1)
end

if(#tArgs < 2) then
    printUsage()
end

local op = tArgs[1]
local id = tonumber(tArgs[2])
if(type(id) ~= "number") then
    printUsage()
end

rednet.open(config.modem_side)

local baseObj = {
    ["key"] = config.key
}

if(op == "reset") then
    baseObj.reset = true
    rednet.send(id, textutils.serialize(baseObj), config.channel_reset)
elseif(op == "update") then
    if(#tArgs < 3) then
        printUsage()
    end
    local dir = tArgs[3]
    if(not fs.exists(dir)) then
        printUsage()
    end
    local data = { }
    for _, fname in pairs(getFiles(dir)) do
        local flhndl = fs.open(fname, "r")
        if(fs.isDir(dir)) then
            fname = relatePath(dir, fname)
        else
            fname = relatePath(fs.getDir(fname), fname)
        end
        data[fname] = flhndl.readAll()
        flhndl.close()
    end
    baseObj.data = data
    rednet.send(id, textutils.serialize(baseObj), config.channel_update)
end
