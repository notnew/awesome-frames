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

local function client_focus()
    local focused_frame = frames[frames.focus]
    local focused_client = focused_frame and focused_frame.client
    if focused_client then
        client.focus = focused_client
    end
end

function frame.focus_next_frame(rel_idx)
    local count = #frames
    if count == 0 then
        local pass = true
    elseif frames.focus < count and frames.focus > 0 then
        frames.focus = frames.focus + 1
    else
        frames.focus = 1
    end

    client_focus()
end

local function add_client(client)
    for _,frame in ipairs(frames) do
        if frame.client == nil then
            frame.client = client
            return
        end
    end
end

function frame.arrange(p)
    local cls = p.clients

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
    if count == 0 then
        local pass = true
    elseif frames.focus < count and frames.focus > 0 then
        frames.focus = frames.focus + 1
    else
        frames.focus = 1
    end

    client_focus()
end

function frame.dwim_next()
    local layout = awful.layout.get()
    if layout and layout.name == "frame" then
        frame.focus_next_frame()
        client_focus()
    else
        awful.client.focus.byidx(1)
        if client.focus then
            client.focus:raise()
        end
    end
end

return frame

