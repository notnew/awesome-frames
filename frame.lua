local ipairs = ipairs
local awful = require("awful")
local tag = require("awful.tag")
local client = client

local frame = {}

frame.name = "frame"

-- frames are tables containing
-- geometry, a geometry table that can by passed to client.geometry (x,y,widht,
-- height)
-- client, a focused client for the frame
local uzbl_frame = {
    geometry =
        function (p)
            local wa = p.workarea
            local t = tag.selected(p.screen)
            local mwidth = wa.width * tag.getmwfact(t)

            return { width = mwidth, height = wa.height, x = wa.x, y = wa.y }
        end,
    client = nil
}

local emacs_frame = {
    geometry =
        function (p)
            local wa = p.workarea
            local t = tag.selected(p.screen)
            local mwidth = wa.width * tag.getmwfact(t)

            return { width = wa.width - mwidth, height = wa.height/2,
                     x = mwidth, y = wa.y }
        end,
    client = nil
}

local urxvt_frame = {
    geometry =
        function (p)
            local wa = p.workarea
            local t = tag.selected(p.screen)
            local mwidth = wa.width * tag.getmwfact(t)

            return { width = wa.width - mwidth, height = wa.height - wa.height/2,
                     x = mwidth, y = wa.y + wa.height/2 }
        end,
    client = nil
}

local frames = {uzbl_frame, emacs_frame, urxvt_frame
               , focus = 1 }
frameless_clients = {}

local function client_focus()
    local focused_frame = frames[frames.focus]
    local focused_client = focused_frame and focused_frame.client
    if focused_client then
        client.focus = focused_client
        focused_client:raise()
    end
end

local function find_index(table, elem)
    for i,e in ipairs(table) do
        if e == elem then
            return i
        end
    end
    return nil
end

local function add_client(client)
    local position = find_index(frameless_clients, client)

    for _,frame in ipairs(frames) do
        if frame.client == client then
            return
        elseif frame.client == nil then
            frame.client = client
            if position then
                table.remove(frameless_clients, position)
            end
            return
        end
    end

    if position == nil then
        table.insert(frameless_clients, client)
    end
end

local function remove_stale(fresh_clients)
    local stale = {}

    for _,client in ipairs(frameless_clients) do
        if find_index(fresh_clients, client) == nil then
            table.insert(stale, client)
        end
    end

    for _,frame in ipairs(frames) do
        if not find_index(fresh_clients, frame.client) then
            frame.client = nil
        end
    end

    for _,client in ipairs(stale) do
        local pos = find_index(frameless_clients, client)
        table.remove(frameless_clients, pos)
    end
end

function frame.arrange(p)
    local cls = p.clients

    remove_stale(cls)
    for _,client in ipairs(cls) do
        add_client(client)
    end

    for _,frame in ipairs(frames) do
        local client = frame.client
        if client then
            client:geometry(frame.geometry(p))
            client:raise()
        end
    end

    client_focus()
end

function frame.focus_next_frame()
    local count = #frames
    if frames.focus < count and frames.focus > 0 then
        frames.focus = frames.focus + 1
    else
        frames.focus = 1
    end

    client_focus()
end

function frame.focus_prev_frame()
    local count = #frames
    if  frames.focus > 1 and frames.focus <= (count + 1) then
        frames.focus = frames.focus - 1
    else
        frames.focus = count
    end

    client_focus()
end

-- pull next unseen client into current frame
function frame.pull_prev()
    local next = table.remove(frameless_clients, 1)
    local focused_frame = frames[frames.focus]

    if next and focused_frame then
        table.insert(frameless_clients, focused_frame.client)
        focused_frame.client = next
        client_focus()
    end
end

function frame.pull_next()
    local prev = table.remove(frameless_clients)
    local focused_frame = frames[frames.focus]

    if next and focused_frame then
        table.insert(frameless_clients, 1, focused_frame.client)
        focused_frame.client = prev
        client_focus()
    end
end

return frame

