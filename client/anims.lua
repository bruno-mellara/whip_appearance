Anims = {}

local SETTLE_MS = 450

local TRY = {
    male = {
        shirt    = { 'clothingshirt', 'try_shirt_positive_a' },
        trousers = { 'clothingtrousers', 'try_trousers_positive_a' },
        shoes    = { 'clothingshoes', 'try_shoes_positive_a' },
        glasses  = { 'clothingspecs', 'try_glasses_positive_a' },
        tie      = { 'clothingtie', 'try_tie_positive_a' },
        mask     = { 'mp_masks@on_foot', 'put_on_mask' },
        hat      = { 'missheistdockssetup1hardhat@', 'put_on_hat' },
    },
    female = {
        shirt    = { 'mp_clothing@female@shirt', 'try_shirt_positive_a' },
        trousers = { 'mp_clothing@female@trousers', 'try_trousers_positive_a' },
        shoes    = { 'mp_clothing@female@shoes', 'try_shoes_positive_a' },
        glasses  = { 'mp_clothing@female@glasses', 'try_glasses_positive_a' },
        tie      = { 'mp_clothing@female@shirt', 'try_shirt_positive_a' },
        mask     = { 'mp_masks@on_foot', 'put_on_mask' },
        hat      = { 'missheistdockssetup1hardhat@', 'put_on_hat' },
    },
}

local PART = {
    c11 = 'shirt', c8 = 'shirt', c3 = 'shirt', c5 = 'shirt', c9 = 'shirt', c10 = 'shirt', c4 = 'trousers', c6 = 'shoes',
    c1 = 'mask', c7 = 'tie',
    p0 = 'hat', p1 = 'glasses', p2 = 'glasses', p6 = 'tie', p7 = 'tie',
}

local known = {}

local function animMs(dict, clip)
    local key = dict .. '/' .. clip
    if known[key] ~= nil then return known[key] end
    local ms = 0
    if DoesAnimDictExist(dict) then
        RequestAnimDict(dict)
        local deadline = GetGameTimer() + 2000
        while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
        if HasAnimDictLoaded(dict) then ms = math.floor((GetAnimDuration(dict, clip) or 0.0) * 1000) end
    end
    known[key] = ms
    return ms
end

local playing = nil

local function play(part)
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, true) then return end
    if playing and IsEntityPlayingAnim(ped, playing[1], playing[2], 3) then return end
    local body = GetEntityModel(ped) == GetHashKey(Appearance.MODELS.female) and 'female' or 'male'
    local list = TRY[body]
    for _, a in ipairs({ list[part], list.shirt }) do
        if a and animMs(a[1], a[2]) > 0 then
            TaskPlayAnim(ped, a[1], a[2], 4.0, -4.0, -1, 0, 0.0, false, false, false)
            playing = a
            return
        end
    end
end

local token = 0

function Anims.tryOn(key)
    local part = PART[key]
    if not part then return end
    token = token + 1
    local mine = token
    SetTimeout(SETTLE_MS, function()
        if mine ~= token then return end
        CreateThread(function() play(part) end)
    end)
end

function Anims.now(key)
    local part = PART[key]
    if part then play(part) end
end

function Anims.stop()
    token = token + 1
    local ped = PlayerPedId()
    if playing and IsEntityPlayingAnim(ped, playing[1], playing[2], 3) then StopAnimTask(ped, playing[1], playing[2], 2.0) end
    playing = nil
end

RegisterCommand('appearance_anims', function()
    if Whip.core:HasDevTools() ~= true then return Whip.core:Notify('Turn on the developer tools (/w) first.', 'error') end
    CreateThread(function()
        local bad = 0
        for body, parts in pairs(TRY) do
            for part, a in pairs(parts) do
                local ms = animMs(a[1], a[2])
                print(('[whip_appearance] %s %s %s: %s/%s %s'):format(ms > 0 and 'OK   ' or 'MISSING', body, part, a[1], a[2], ms > 0 and (ms .. ' ms') or ''))
                if ms == 0 then bad = bad + 1 end
            end
        end
        Whip.core:Notify(bad == 0 and 'Every animation exists (details in F8).'
            or ('%d animation(s) missing: they use the shirt-adjust one (see F8).'):format(bad), bad == 0 and 'success' or 'error')
    end)
end, false)
