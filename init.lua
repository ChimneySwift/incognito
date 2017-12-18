local INCOGNITOCOOLDOWN = 60

local PLAYERRANGE = 100

local player_list = {}
local incognito_players = {}
local huds = {}
local player_warning_huds = {}

minetest.register_privilege("incognito", {
    description = "Enables players to become completely invisible.",
})

local function show_confirm(text, name)
    minetest.show_formspec(name, "incognito_check", [[
        size[6,1]
        bgcolor[#080808BB;true]
        background[5,5;1,1;gui_formbg.png;true]
        label[0,0;]]..text..[[]
        button_exit[-0.1,0.65;2,1;yes;Yes]
        button_exit[4.2,0.65;2,1;no;No]
    ]])
end

local function hide_player(player)
    name = player:get_player_name()
    minetest.log("action", "Player "..name.." just went incognito.")
    if player_list[name] ~= nil then
        core.chat_send_all("*** " ..  name .. " left the game.")
        player_list[name] = nil
    end
    incognito_players[name] = {}
    incognito_players[name].name = name
    -- For some reason it doesn't work properly if done straight after the player has joined
    minetest.after(0.0001, function()
        player:set_properties({
            visual_size = {x = 0, y = 0},
            collisionbox = {0, 0, 0, 0, 0, 0},
            makes_footstep_sound = false,
        })
    end)
    local oldcolor = player:get_properties().nametag_color
    local newcolor = {a = 0, r = oldcolor.r, g = oldcolor.g, b = oldcolor.b}
    player:set_nametag_attributes({color = newcolor, text = " "})
    huds[name] = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.90},
        text = "You are incognito. You're invisible visually and to /status. You can't send public messages or die.",
        number = 0x00BC00
    })
end

local function unhide_player(player)
    name = player:get_player_name()
    minetest.log("action", "Player "..name.." is no longer incognito.")
    player_list[name] = player
    if not minetest.is_singleplayer() then
        core.chat_send_all("*** " .. name .. " joined the game.")
    end
    player:set_properties({
        visual_size = {x = 1, y = 1},
        collisionbox = {-0.35, -1, -0.35, 0.35, 1, 0.35},
        makes_footstep_sound = true,
    })
    local oldcolor = player:get_properties().nametag_color
    local newcolor = {a = 255, r = oldcolor.r, g = oldcolor.g, b = oldcolor.b}
    player:set_nametag_attributes({color = newcolor, text = name})
    incognito_players[name] = nil
    if huds[name] then
        player:hud_remove(huds[name])
    end
end

function core.get_connected_players()
    local temp_table = {}
    for index, value in pairs(player_list) do
        if value:is_player_connected() then
            temp_table[#temp_table + 1] = value
        end
    end
    return temp_table
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "incognito_check" then return end
    if fields.no then
        unhide_player(player)
        return
    else
        return
    end
end)

-- Overwite all status messages:

local function explode(sep, input)
        local t={}
        local i=0
        for k in string.gmatch(input,"([^"..sep.."]+)") do
            t[i]=k
            i=i+1
        end
        return t
end

local function get_max_lag()
        local arrayoutput = explode(", ",minetest.get_server_status())
        local arrayoutput = explode("=",arrayoutput[4])
        return arrayoutput[1]
end

minetest.setting_set("show_statusline_on_connect", "false")

function core.new_get_server_status()
    local player_name_list = {}
    for i, n in ipairs(core.get_connected_players()) do
        table.insert(player_name_list, n:get_player_name())
    end
    local msg = "# Server: ".."version="..minetest.get_version().string..", uptime="..tostring(minetest.get_server_uptime())..", max_lag="..tostring(get_max_lag())..", clients={"..table.concat(player_name_list, ",").."}"
    local motd = minetest.setting_get("motd")
    if motd ~= "" then
        msg = msg.."\n# Server: " .. motd
    end
    return msg
end

core.register_on_joinplayer(function(player)
    minetest.chat_send_player(player:get_player_name(), core.new_get_server_status())
end)

core.override_chatcommand("status", {
    func = function(name, param)
        minetest.chat_send_player(name, core.new_get_server_status())
    end,
})

-- Deny incognito player's public chat messages.

minetest.register_on_chat_message(function(name, message)
    if incognito_players[name] then
        minetest.chat_send_player(name, "You cant send public chat messages while you are incognito!")
        return true
    end
end)

core.override_chatcommand("me", {
    func = function(name, param)
        if incognito_players[name] then
            minetest.chat_send_player(name, "You cant send public chat messages while you are incognito!")
            return
        else
            core.chat_send_all("* " .. name .. " " .. param)
        end
    end,
})

-- Make sure incognito players don't die (in case there is some kind of death message mod enabled)

minetest.register_on_player_hpchange(function(player, hp_change)
    local name = player:get_player_name()
    if incognito_players[name] then
        return 0
    else
        return hp_change
    end
end, true)

-- Make it possible to toggle via command

local restricted_players = {}

minetest.register_chatcommand("incognito", {
    description = "Toggle incognito mode.",
    privs = {incognito=true},
    func = function(name, param)
        player = minetest.get_player_by_name(name)
        for i, n in ipairs(restricted_players) do
            if n == name then
                minetest.log("action", "Player "..name.." tried to run /incognito again too soon, ignoring.")
                minetest.chat_send_player(name, "To avoid suspicions, you can only run this command every "..tostring(INCOGNITOCOOLDOWN).." seconds.")
                return
            end
        end

        if incognito_players[name] then
            unhide_player(player)
        else
            hide_player(player)
        end

        if INCOGNITOCOOLDOWN > 0 then
            table.insert(restricted_players, name)
            minetest.after(INCOGNITOCOOLDOWN, function()
                for i, p in ipairs(restricted_players) do
                    if p == name then
                        table.remove(restricted_players, i)
                    end
                end
            end)
        end
    end,
})

minetest.register_globalstep(function(dtime)
    for n in pairs(incognito_players) do
        local player = minetest.get_player_by_name(n)
        local pos = player:get_pos()
        local objects = minetest.get_objects_inside_radius(pos, PLAYERRANGE)
        local areplayers = false
        for i, o in pairs(objects) do
            if o:is_player() and o:get_player_name() ~= n then
                areplayers = true
            end
        end
        if areplayers then
            if not player_warning_huds[n] then
                player_warning_huds[n] = player:hud_add({
                    hud_elem_type = "text",
                    position = {x = 0.5, y = 0.88},
                    text = "There are players within "..tostring(PLAYERRANGE).." nodes of you!",
                    number = 0xFF0000
                })
            end
        else
            if player_warning_huds[n] then
                player:hud_remove(player_warning_huds[n])
                player_warning_huds[n] = nil
            end
        end
    end
end)

core.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    if minetest.check_player_privs(player_name, {incognito = true}) then
        hide_player(player)
        show_confirm("Would you like to enable incognito mode this session?", player_name)
        return
    else
        player_list[player_name] = player
        if not minetest.is_singleplayer() then
            core.chat_send_all("*** " .. player_name .. " joined the game.")
        end
    end
end)

core.register_on_leaveplayer(function(player, timed_out)
    local player_name = player:get_player_name()
    if incognito_players[player_name] then
        unhide_player(player)
        incognito_players[player_name] = nil
        return
    else
        player_list[player_name] = nil
    end
    local announcement = "*** " ..  player_name .. " left the game."
    if timed_out then
        announcement = announcement .. " (timed out)"
    end
    core.chat_send_all(announcement)
end)