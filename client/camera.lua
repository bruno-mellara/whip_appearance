Cam = {}

local cam = nil
local framing = 'body'
local zoom = 0.0
local lift = 0.0
local front = 0.0
local INTERP_MS = 450
local SIDE = 0.40

local function targetOf(f)
    local ped = PlayerPedId()
    local bone = tonumber(f.bone)
    if bone then
        local b = GetPedBoneCoords(ped, bone, 0.0, 0.0, 0.0)
        if b and (b.x ~= 0.0 or b.y ~= 0.0) then return b end
    end
    return GetEntityCoords(ped)
end

local function spot(name)
    local cfg = Config.Camera or {}
    local f = cfg[name] or cfg.body or { dist = 2.8, z = 0.0, fov = 50.0 }
    local p = targetOf(f)
    local dist = math.max(0.45, (tonumber(f.dist) or 2.0) + zoom)
    local z = (tonumber(f.z) or 0.0) + lift
    local fov = (tonumber(f.fov) or 45.0) + 0.0
    local h = math.rad(front)
    local fx, fy = -math.sin(h), math.cos(h)

    local rx, ry = -fy, fx
    local side = dist * math.tan(math.rad(fov / 2.0)) * GetAspectRatio(false) * SIDE
    local from = vector3(p.x + fx * dist - rx * side, p.y + fy * dist - ry * side, p.z + z)
    local at = vector3(p.x - rx * side, p.y - ry * side, p.z + z)
    return from, at, fov
end

local function place(c, name)
    local from, at, fov = spot(name)
    SetCamCoord(c, from.x, from.y, from.z)
    PointCamAtCoord(c, at.x, at.y, at.z)
    SetCamFov(c, fov)
end

function Cam.start(name)
    framing, zoom, lift = name or 'body', 0.0, 0.0
    if cam then return end
    front = GetEntityHeading(PlayerPedId())
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    place(cam, framing)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 600, true, false)
end

function Cam.frame(name)
    if not cam or not name or not (Config.Camera or {})[name] then return end
    if name == framing and zoom == 0.0 and lift == 0.0 then return end
    framing, zoom, lift = name, 0.0, 0.0
    local nextCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    place(nextCam, framing)
    SetCamActiveWithInterp(nextCam, cam, INTERP_MS, 1, 1)
    local old = cam
    cam = nextCam
    SetTimeout(INTERP_MS + 50, function()
        if DoesCamExist(old) then DestroyCam(old, false) end
    end)
end

function Cam.zoom(delta)
    if not cam then return end
    zoom = math.max(-1.5, math.min(1.5, zoom + (tonumber(delta) or 0.0)))
    place(cam, framing)
end

function Cam.raise(delta)
    if not cam then return end
    lift = math.max(-0.9, math.min(0.9, lift + (tonumber(delta) or 0.0)))
    place(cam, framing)
end

function Cam.turn(deg)
    local ped = PlayerPedId()
    SetEntityHeading(ped, (GetEntityHeading(ped) + (tonumber(deg) or 0.0)) % 360.0)
end

local turnToken = 0

function Cam.faceSide(deg)
    if not cam then return end
    turnToken = turnToken + 1
    local token = turnToken
    local ped = PlayerPedId()
    local from = GetEntityHeading(ped)
    local to = (front + (tonumber(deg) or 0.0)) % 360.0
    local diff = ((to - from + 540.0) % 360.0) - 180.0
    CreateThread(function()
        local start, ms = GetGameTimer(), 350
        while token == turnToken and cam do
            local k = math.min(1.0, (GetGameTimer() - start) / ms)
            k = k * k * (3.0 - 2.0 * k)
            SetEntityHeading(ped, (from + diff * k) % 360.0)
            if k >= 1.0 then break end
            Wait(0)
        end
    end)
end

function Cam.refresh()
    if cam then place(cam, framing) end
end

function Cam.stop()
    if not cam then return end
    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(cam, false)
    cam = nil
    SetEntityHeading(PlayerPedId(), front)
end

function Cam.active() return cam ~= nil end
