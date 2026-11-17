local SAVE_WAIT_MS = 10000
local SAVE_POLL_MS = 250
local LOOK_MAX_BYTES = 10000

Sessions = {}

local listeners = {}

AppearanceServer = {}

function AppearanceServer.onFinish(fn) listeners[#listeners + 1] = fn end

local function finish(src, outcome, info)
    local s = Sessions[src]
    if not s then return end
    Sessions[src] = nil
    info = info or {}
    info.kind, info.source = s.kind, src
    for _, fn in ipairs(listeners) do
        local ok, err = pcall(fn, src, s, outcome, info)
        if not ok then print(('[whip_appearance] a session-end listener failed: %s'):format(tostring(err))) end
    end
end

local function savedLook(src)
    local look = Whip.core:GetPlayerMetadata(src, 'appearance')
    if type(look) ~= 'table' or not look.model then
        return nil, 'Your character has no saved look yet. Finish creating your character first.'
    end
    return look
end
AppearanceServer.savedLook = savedLook

function AppearanceServer.saveLook(src, session, final)
    TriggerClientEvent('whip_appearance:client:saveLook', src, final)
    local deadline = GetGameTimer() + SAVE_WAIT_MS
    while GetGameTimer() < deadline do
        Wait(SAVE_POLL_MS)
        if not exports.whip_core:IsSessionCurrent(src, session) then return false end
        if Appearance.same(exports.whip_core:GetPlayerMetadata(src, 'appearance'), final) then return true end
    end
    return false
end

function AppearanceServer.inJobs(src, jobs, onDuty)
    for _, j in ipairs(jobs or {}) do
        if exports.whip_core:GetPlayerRole(src, j) then
            if not onDuty or exports.whip_core:IsPlayerClockedOn(src, j) == true then return true end
        end
    end
    return false
end

local function vec3Of(p)
    if (type(p) ~= 'table' and type(p) ~= 'vector3' and type(p) ~= 'vector4') or not p.x then return nil end
    return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
end

local function shopAt(kind, index)
    local list = Config.Shops and Config.Shops[kind]
    local shop = type(list) == 'table' and list[index] or nil
    local coords = type(shop) == 'table' and vec3Of(shop.coords) or nil
    if not coords then return nil end
    return shop, coords
end
AppearanceServer.shopAt = shopAt

local function pointsOf(shop)
    local p = vec3Of(shop.coords)
    return p and { p } or {}
end

local function near(src, coords, extra)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= (tonumber(Config.UseRange) or 2.5) + (extra or 0.0)
end

local function nearAny(src, points, extra)
    for _, p in ipairs(points) do
        if near(src, p, extra) then return true end
    end
    return false
end

local function sessionView(s, src)
    local r = AppearanceRules.view(src)
    return {
        kind = s.kind, title = s.title, free = s.free == true, test = s.test == true,
        allowBank = Config.AllowBank ~= false and not s.free and not s.test,
        brand = s.brand, rules = r.rules, categories = r.categories, tattoos = r.tattoos, admin = r.admin, jobs = r.jobs,
        catalog = Appearance.isCatalog(s.brand), catalogs = Appearance.catalogs(),
    }
end

function AppearanceServer.open(src, kind, opts)
    opts = opts or {}
    if not Appearance.KIND_SET[kind] then return false, 'unknown store kind' end
    local player = Whip.core:GetPlayer(src)
    if type(player) ~= 'table' then return false, 'the player is not on a character' end
    if player.isDead then return false, 'the player is down' end
    if Sessions[src] then return false, 'the player is already in a store' end
    local _, why = savedLook(src)
    if why then return false, why end
    local s = {
        kind = kind, title = opts.title or Appearance.KindLabel[kind], free = opts.free == true, test = opts.test == true,
        callId = opts.callId, by = opts.by or 'director', session = player.session,
    }
    Sessions[src] = s
    TriggerClientEvent('whip_appearance:client:open', src, sessionView(s, src))
    return true
end

function AppearanceServer.close(src, why)
    if not Sessions[src] then return end
    TriggerClientEvent('whip_appearance:client:forceClose', src, why)
    finish(src, 'cancelled', { reason = why })
end

function AppearanceServer.isOpen(src) return Sessions[src] ~= nil end

local shownBlips = {}

local function refreshBlips()
    for id in pairs(shownBlips) do Whip.core:HideBlip(id) end
    shownBlips = {}
    for _, kind in ipairs(Appearance.KINDS) do
        local b = Config.Blips[kind] or {}
        local sprite = math.floor(tonumber(b.sprite) or 0)
        if sprite > 0 then
            for i in ipairs(Config.Shops[kind] or {}) do
                local shop, coords = shopAt(kind, i)
                if shop and shop.hideBlip ~= true then
                    local id = ('whip_appearance_%s_%d'):format(kind, i)
                    local ok, why = Whip.core:ShowBlip('everyone', id, {
                        coords = coords, label = b.label or Appearance.KindLabel[kind], sprite = sprite,
                        color = math.floor(tonumber(b.color) or 0), shortRange = true, scale = 0.75,
                    })
                    if ok then shownBlips[id] = true else print(('[whip_appearance] blip %s: %s'):format(id, tostring(why))) end
                end
            end
        end
    end
end

Whip.onConfigChanged('Shops', function() CreateThread(refreshBlips) end)
Whip.onConfigChanged('Blips', function() CreateThread(refreshBlips) end)

function AppearanceServer.openShop(source, player, kind, index)
    if Sessions[source] then return false, 'You are already in a store.' end
    local shop = shopAt(kind, index)
    if not shop then return false, 'That store no longer exists.' end
    local points = pointsOf(shop)
    if not nearAny(source, points, 1.5) then return false, 'Get closer to the counter.' end
    local _, why = savedLook(source)
    if why then return false, why end

    local jobs = kind == 'clothing' and Appearance.jobList(shop.jobs) or nil
    if jobs and not AppearanceServer.inJobs(source, jobs, shop.onDuty == true) and not AppearanceRules.isAdmin(source) then
        return false, shop.onDuty == true and 'Only for people on duty at this company.' or 'Only for people who work at this company.'
    end
    local s = { kind = kind, title = shop.name or Appearance.KindLabel[kind], points = points, index = index, by = 'shop',
                session = player.session, brand = kind == 'clothing' and Appearance.brandOf(shop) or nil,
                free = kind == 'clothing' and shop.free == true or nil }
    Sessions[source] = s
    return sessionView(s, source)
end

local function onOpen(source, player, kind, index)
    return AppearanceServer.openShop(source, player, kind, index)
end

local function onBuy(source, player, look, method, shown)
    local s = Sessions[source]
    if not s then return false, 'No store open.' end
    if s.busy then return false, 'Please wait, your purchase is being recorded.' end
    if s.points and not nearAny(source, s.points, 5.0) then return false, 'You walked away from the store.' end

    local encoded = json.encode(look)
    if not encoded or #encoded > LOOK_MAX_BYTES then return false, 'Look too large.' end

    local saved, why = savedLook(source)
    if not saved then return false, why end

    local ok, clean = exports.whip_core:SanitizeAppearance(look)
    if not ok then return false, 'Look refused: ' .. tostring(clean) end
    if s.kind ~= 'surgery' and clean.model ~= saved.model then return false, 'Only the clinic changes sex.' end

    local ok2, final = exports.whip_core:SanitizeAppearance(Appearance.merge(s.kind, saved, clean))
    if not ok2 then return false, 'Look refused: ' .. tostring(final) end

    local quote = Appearance.quote(s.kind, saved, final, { tattooPrice = AppearanceRules.tattooPrice })
    if #quote.lines == 0 then return false, 'You did not change anything.' end

    local allowedOk, notAllowed = AppearanceRules.checkLook(source, player, s, saved, final)
    if not allowedOk then return false, notAllowed end
    if s.kind == 'tattoo' then
        allowedOk, notAllowed = AppearanceRules.checkTattoos(source, player, saved, final)
        if not allowedOk then return false, notAllowed end
    end

    local total = (s.free or s.test) and 0 or quote.total

    if total > shown then
        TriggerClientEvent('whip_appearance:client:prices', source)
        return false, 'Prices changed. Check the new total and try again.'
    end
    if method == 'bank' and Config.AllowBank == false then method = 'cash' end

    if s.test then
        TriggerClientEvent('whip_appearance:client:done', source, false)
        finish(source, 'changed', { total = 0, lines = quote.lines, test = true })
        return
    end

    s.busy = true
    local receipt
    if total > 0 then
        local r, err = exports.whip_core:ChargePlayer(source, total,
            { method = method, reason = ('%s: %d item(s)'):format(Appearance.KindLabel[s.kind], #quote.lines) })
        if not r then
            s.busy = false
            return false, err
        end
        receipt = r
    end

    local savedOk = AppearanceServer.saveLook(source, player.session, final)

    if not savedOk then
        if receipt then exports.whip_core:RefundPlayer(receipt) end
        if Sessions[source] == s then
            s.busy = false
            TriggerClientEvent('whip_appearance:client:saveFailed', source)
        end
        return false, receipt and 'Could not save the look. The money was refunded.' or 'Could not save the look.'
    end

    if Appearance.sexChanged(saved, final) then
        local gender = final.model == Appearance.MODELS.female and 'female' or 'male'
        local dbOk, err = pcall(MySQL.update.await, 'UPDATE `characters` SET `gender` = ? WHERE `charId` = ?',
            { gender, player.charId })
        if not dbOk then print(('[whip_appearance] could not store the sex of character %s: %s'):format(player.charId, tostring(err))) end
    end

    if s.kind == 'clothing' and AppearanceWardrobe then AppearanceWardrobe.forgetOwn(player.charId) end

    finish(source, 'changed', { total = total, lines = quote.lines })
    TriggerClientEvent('whip_appearance:client:done', source, true, total)
end

local function onClose(source)
    local s = Sessions[source]
    if not s or s.busy then return end
    finish(source, 'cancelled', { reason = 'closed' })
end

Whip.register(function()
    exports.whip_core:SecureCallback('whip_appearance:open', {
        rateLimit = 1000, burst = 2,
        params = {
            { 'kind', 'enum', Appearance.KINDS },
            { 'shop', 'amount', 200 },
        },
    }, onOpen)

    exports.whip_core:SecureEvent('whip_appearance:buy', {
        rateLimit = 3000, burst = 2,
        params = {
            { 'look', 'any' },
            { 'method', 'enum', { 'cash', 'bank' }, 'cash' },
            { 'shown', 'int', 0, 100000000 },
        },
    }, onBuy)

    exports.whip_core:SecureEvent('whip_appearance:close', {
        rateLimit = 500, burst = 3,
        whileDead = true,
    }, onClose)

    CreateThread(refreshBlips)
end)

AddEventHandler('whip_core:player:logout', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' then return end
    local src = tonumber(e.source)
    if src and Sessions[src] then finish(src, 'cancelled', { reason = 'logout' }) end
end)

AddEventHandler('whip_core:player:died', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' then return end
    local src = tonumber(e.source)
    if src and Sessions[src] and not Sessions[src].busy then finish(src, 'cancelled', { reason = 'died' }) end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Sessions[src] then finish(src, 'cancelled', { reason = 'dropped' }) end
end)
