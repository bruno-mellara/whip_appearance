MaskFix = {}

local cfg = Config.MaskFix or {}
local SHRINK_HEAD = GetHashKey('SHRINK_HEAD')
local TAG_HAT = GetHashKey('HAT')
local TAG_EAR = GetHashKey('EAR_PIECE')
local MALE = GetHashKey('mp_m_freemode_01')
local FEMALE = GetHashKey('mp_f_freemode_01')

local function set(list)
    local out = {}
    for _, v in ipairs(list or {}) do out[math.floor(tonumber(v) or -1)] = true end
    return out
end
local headList = set(cfg.shrinkHead)
local keepHeadList = set(cfg.keepHead)
local keepList = set(cfg.keepFace)

local applied = { ped = 0, key = nil, head = false, face = false }

local lookSource = nil
function MaskFix.setLookSource(fn) lookSource = fn end

local paused = false
function MaskFix.pause(on) paused = on == true end

local function trueLook()
    local look = lookSource and lookSource() or nil
    if type(look) == 'table' then return look end
    return Appearance.Client and Appearance.Client.savedLook and Appearance.Client.savedLook() or nil
end

local function hasTag(hash, tag)
    if hash == 0 or not DoesShopPedApparelHaveRestrictionTag then return false end
    local ok, yes = pcall(DoesShopPedApparelHaveRestrictionTag, hash, tag, 0)
    return ok and yes == true
end

local function maskHash(ped, d, t)
    if not GetHashNameForComponent then return 0 end
    local ok, h = pcall(GetHashNameForComponent, ped, 1, d, t)
    return ok and tonumber(h) or 0
end

local function wants(ped)
    local d = GetPedDrawableVariation(ped, 1)
    if d <= 0 then return false, false, d, 0 end
    local t = GetPedTextureVariation(ped, 1)
    local hash = maskHash(ped, d, t)

    local face = not (keepList[d] or hasTag(hash, TAG_HAT) or hasTag(hash, TAG_EAR))
    local head
    if cfg.shrinkHeadAll ~= false then
        head = face and not keepHeadList[d]
    else
        head = headList[d] == true or hasTag(hash, SHRINK_HEAD)
    end
    return head, face, d, t, hash
end

local function waitBlend(ped)
    local deadline = GetGameTimer() + 500
    while not HasPedHeadBlendFinished(ped) and GetGameTimer() < deadline do Wait(0) end
end

local function setBlend(ped, shapeA, shapeB, shapeC, hb, shapeMix, thirdMix)
    SetPedHeadBlendData(ped, shapeA, shapeB, shapeC, hb.mom or 0, hb.dad or 0, hb.grandparent or 0,
        shapeMix + 0.0, (tonumber(hb.skinWeight) or 0.5) + 0.0, thirdMix + 0.0, false)
    if Preview and Preview.forgetBlend then Preview.forgetBlend() end
    waitBlend(ped)
end

local function setFeatures(ped, ff)
    for i = 0, 19 do SetPedFaceFeature(ped, i, ((ff and tonumber(ff[i + 1])) or 0.0) + 0.0) end
end

function MaskFix.update(look, fresh)
    if cfg.enabled == false then return end
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then return end
    local model = GetEntityModel(ped)
    if model ~= MALE and model ~= FEMALE then return end
    look = look or trueLook()
    if type(look) ~= 'table' then return end
    local hb = type(look.headBlend) == 'table' and look.headBlend or {}

    if fresh or applied.ped ~= ped then applied = { ped = ped, key = nil, head = false, face = false } end
    local head, face, d, t = wants(ped)
    if paused then head, face = false, false end
    local key = ('%d|%d|%d|%s|%s'):format(model, d, t, tostring(head), tostring(face))
    if key == applied.key and not fresh then return end

    if head then
        setBlend(ped, model == MALE and 0 or 21, 0, 0, hb, 0.0, 0.0)
    elseif applied.head then
        setBlend(ped, hb.mom or 0, hb.dad or 0, hb.grandparent or 0, hb, tonumber(hb.faceWeight) or 0.5, tonumber(hb.thirdWeight) or 0.0)
    end

    if face then
        setFeatures(ped, nil)
    elseif applied.face or applied.head then
        setFeatures(ped, look.faceFeatures)
    end
    applied.key, applied.head, applied.face = key, head, face
end

function MaskFix.forget() applied = { ped = 0, key = nil, head = false, face = false } end

local function soon(ms)
    SetTimeout(ms or 300, function()
        CreateThread(function() MaskFix.forget(); MaskFix.update(nil, true) end)
    end)
end

AddEventHandler('whip_core:player:spawned', function() soon(600) end)
AddEventHandler('whip_core:player:revived', function() soon(600) end)
AddEventHandler('whip_core:appearance:modelChanged', function() soon(400) end)

CreateThread(function()
    local last = nil
    while true do
        Wait(math.max(200, math.floor(tonumber(cfg.checkMs) or 500)))
        if cfg.enabled ~= false and Whip.isReady() then
            local ped = PlayerPedId()
            local k = ('%d|%d|%d|%d'):format(ped, GetEntityModel(ped), GetPedDrawableVariation(ped, 1), GetPedTextureVariation(ped, 1))
            if k ~= last then
                last = k
                MaskFix.update(nil, false)
            end
        end
    end
end)
