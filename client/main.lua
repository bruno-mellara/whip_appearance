local S = nil
local RES = GetCurrentResourceName()

local function notify(text, kind) Whip.core:Notify(text, kind or 'info') end

local pending, applying = nil, false

local function shown(look)
    if S and S.undressed then return Preview.undressed(PlayerPedId(), look) end
    return look
end

local function queueApply(look)
    pending = shown(look)
    if applying then return end
    applying = true
    CreateThread(function()
        while pending do
            local l = pending
            pending = nil
            Preview.apply(PlayerPedId(), l)
        end
        applying = false
    end)
end

local function tattooPrice(key)
    for _, t in ipairs(S and S.view.tattoos or {}) do
        if t.key == key then return t.price end
    end
    return nil
end

local function quote()
    if not S then return { lines = {}, total = 0 } end
    local final = Appearance.merge(S.view.kind, S.saved, S.look)
    local q = Appearance.quote(S.view.kind, S.saved, final, { tattooPrice = tattooPrice })
    if S.view.free or S.view.test or S.mode == 'builder' then q.total = 0 end
    return q
end

local function groupsFor(kind)
    local list = {}
    for _, g in ipairs(Appearance.Groups[kind]) do
        list[#list + 1] = { key = g.key, label = g.label, cam = g.cam, ui = g.ui, price = Appearance.priceOf(kind, g.key) }
    end

    if kind == 'surgery' then
        for _, extra in ipairs({ 'barber', 'clothing' }) do
            for _, g in ipairs(Appearance.Groups[extra]) do
                list[#list + 1] = { key = g.key, label = g.label, cam = g.cam, ui = g.ui, price = 0, sexOnly = true }
            end
        end
    end
    return list
end

local function pageData()
    local ped = PlayerPedId()
    local icons = Preview.icons(ped)
    return {
        look = S.look,
        savedModel = S.saved.model,
        maxes = Preview.maxes(ped),
        fades = Preview.fades(S.look.model),
        icons = icons,
        pictures = icons and Preview.pictures(icons.gender) or nil,
        tattooList = S.view.kind == 'tattoo' and Preview.tattoos(ped) or nil,
        undressed = S.undressed == true,
        removePrice = Appearance.priceOf('tattoo', 'remove'),
        quote = quote(),
    }
end

local STICK_TURN = 140.0
local STICK_LIFT = 0.8
local TRIGGER_ZOOM = 1.6

local screen = Whip.padScreen({
    buttons = { 'up', 'down', 'left', 'right', 'a', 'b', 'x', 'y', 'lb', 'rb' },
    onFrame = function()
        if not S then return end
        local dt = GetFrameTime()
        local rx = GetDisabledControlNormal(0, 220)
        local ry = GetDisabledControlNormal(0, 221)
        local lt = GetDisabledControlNormal(0, 228)
        local rt = GetDisabledControlNormal(0, 229)
        if math.abs(rx) > 0.15 then Cam.turn(rx * STICK_TURN * dt) end
        if math.abs(ry) > 0.15 then Cam.raise(-ry * STICK_LIFT * dt) end
        if lt > 0.05 or rt > 0.05 then Cam.zoom((lt - rt) * TRIGGER_ZOOM * dt) end
    end,
})

local function cannotOpen(kind)
    if not Whip.core:IsPlayerLoaded() then return 'No character loaded.' end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then return 'Not while you are down.' end
    if IsPedInAnyVehicle(ped, true) then return 'Get out of the vehicle first.' end
    if kind == 'surgery' and GetSelectedPedWeapon(ped) ~= GetHashKey('WEAPON_UNARMED') then return 'Put your weapon away first.' end
    return nil
end

local function savedLook()
    local me = Whip.core:GetPlayer()
    local look = type(me) == 'table' and type(me.metadata) == 'table' and me.metadata.appearance or nil
    if type(look) ~= 'table' or not look.model then return nil end
    if GetEntityModel(PlayerPedId()) ~= GetHashKey(look.model) then return nil end
    return Appearance.copy(look)
end

local function open(view, opts)
    opts = opts or {}
    if S then return false, 'A store is already open.' end
    local why = cannotOpen(view.kind)
    if why then return false, why end
    local saved = savedLook()
    if not saved then return false, 'You are not wearing your character\'s look right now.' end

    local ped = PlayerPedId()
    local base = Preview.complete(ped, saved)
    S = { view = view, mode = opts.mode or 'shop', onPick = opts.onPick, saved = saved, base = base, look = Appearance.copy(base),
          undressed = view.kind == 'tattoo' }
    Preview.reset()
    if S.undressed then queueApply(S.look) end

    MaskFix.pause(view.kind ~= 'clothing' and view.kind ~= 'wardrobe')
    MaskFix.update(nil, false)

    local groups = groupsFor(view.kind)
    Cam.start(groups[1] and groups[1].cam or 'body')
    Whip.core:SetScreenOpen(true, 'whip_appearance')
    local data = pageData()
    data.action = 'open'
    data.view = view
    data.mode = S.mode
    data.groups = groups
    data.features = Appearance.FEATURES
    data.palettes = Preview.palettes()
    data.brands = Config.Brands
    data.pad = screen:open()
    SendNUIMessage(data)
    return true
end

local revertOnRevive = nil

local function revertTo(look)
    local ped = PlayerPedId()
    if GetEntityModel(ped) ~= GetHashKey(look.model) then
        if IsEntityDead(ped) then
            revertOnRevive = look
            return
        end
        Preview.swapModel(look)
    else
        Preview.apply(ped, look, true)
    end
end

AddEventHandler('whip_core:player:revived', function()
    local look = revertOnRevive
    revertOnRevive = nil
    if look then CreateThread(function() Preview.swapModel(look) end) end
end)

local function close(revert, tellServer)
    if not S then return end
    local s = S
    S = nil
    pending = nil
    Anims.stop()
    SendNUIMessage({ action = 'close' })
    screen:close()
    Whip.core:SetScreenOpen(false, 'whip_appearance')
    if tellServer and s.mode == 'shop' then
        TriggerServerEvent(s.view.kind == 'wardrobe' and 'whip_appearance:wardrobe:close' or 'whip_appearance:close')
    end
    MaskFix.pause(false)
    CreateThread(function()
        while applying do Wait(0) end
        if revert then
            revertTo(s.base)
        elseif s.undressed then
            Preview.apply(PlayerPedId(), s.look, true)
        end
        MaskFix.update(nil, false)
        Cam.stop()
        if s.mode == 'builder' and s.onPick then s.onPick(s.picked) end
    end)
end

MaskFix.setLookSource(function() return S and S.look or nil end)

Appearance.Client = Appearance.Client or {}
Appearance.Client.savedLook = savedLook
Appearance.Client.isOpen = function() return S ~= nil end

local function openFromShop(kind, index)
    local view, why = Whip.core:Callback('whip_appearance:open', kind, index)
    if not view then
        notify(why or 'The store did not open.', 'error')
        return
    end
    local ok, err = open(view)
    if not ok then
        TriggerServerEvent('whip_appearance:close')
        notify(err, 'error')
    end
end

local function buildActions()
    Whip.core:RemoveActionGroup('whip_appearance')
    for _, kind in ipairs(Appearance.KINDS) do
        for i, shop in ipairs(Config.Shops[kind] or {}) do
            local c = type(shop) == 'table' and shop.coords
            if c and c.x then
                Whip.core:AddAction({
                    id = ('whip_appearance_%s_%d'):format(kind, i),
                    group = 'whip_appearance',
                    at = { coords = vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0) },
                    label = shop.name and ('%s'):format(shop.name) or Appearance.KindLabel[kind],
                    icon = 'store',
                    reach = tonumber(Config.UseRange) or 2.5,
                    focusMode = 'near',

                    require = (function()
                        local jobs = kind == 'clothing' and Appearance.jobList(shop.jobs) or nil
                        if jobs and #jobs == 1 then
                            return { alive = true, vehicle = 'out', job = jobs[1], onDuty = shop.onDuty == true or nil }
                        end
                        return { alive = true, vehicle = 'out' }
                    end)(),
                    onSelect = function() openFromShop(kind, i) end,
                })
            end
        end
    end

    for i, w in ipairs(Config.Wardrobes or {}) do
        local c = type(w) == 'table' and w.coords
        local job = type(w) == 'table' and type(w.job) == 'string' and w.job:lower():match('^%s*(.-)%s*$') or ''
        if c and c.x and job ~= '' then
            Whip.core:AddAction({
                id = ('whip_appearance_wardrobe_%d'):format(i),
                group = 'whip_appearance',
                at = { coords = vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0) },
                label = w.name or 'Wardrobe',
                icon = 'store',
                reach = tonumber(Config.UseRange) or 2.5,
                focusMode = 'near',
                require = { alive = true, vehicle = 'out', job = job, onDuty = w.onDuty == true or nil },
                onSelect = function() Appearance.Client.openWardrobe(i) end,
            })
        end
    end
end

Whip.register(buildActions)
Whip.onConfigChanged('Shops', function() CreateThread(buildActions) end)
Whip.onConfigChanged('UseRange', function() CreateThread(buildActions) end)
Whip.onConfigChanged('Wardrobes', function() CreateThread(buildActions) end)

RegisterNetEvent('whip_appearance:client:open', function(view)
    if type(view) ~= 'table' or not Appearance.KIND_SET[view.kind] then return end
    CreateThread(function()
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
            local deadline = GetGameTimer() + 4000
            while IsPedInAnyVehicle(ped, true) and GetGameTimer() < deadline do Wait(100) end
        end
        local ok, why = open(view)
        if not ok then
            TriggerServerEvent('whip_appearance:close')
            notify(why, 'error')
        end
    end)
end)

RegisterNetEvent('whip_appearance:client:saveLook', function(final)
    if type(final) ~= 'table' then return end
    if S then
        if S.mode ~= 'shop' then return end
        S.saving = true
        S.look = final
        queueApply(final)
    else
        CreateThread(function() Preview.apply(PlayerPedId(), final, true) end)
    end
    TriggerServerEvent('whip_core:server:saveAppearance', final)
end)

RegisterNetEvent('whip_appearance:client:done', function(saved, total)
    if not S then return end
    if saved then
        S.base = S.look
        total = tonumber(total) or 0
        notify(total > 0 and ('Paid $%d. Looking great!'):format(total) or 'Done. Looking great!', 'success')
        close(false, false)
    else
        notify('Director test: nothing was paid or saved.', 'info')
        close(true, false)
    end
end)

RegisterNetEvent('whip_appearance:client:saveFailed', function()
    if not S then return end
    S.busy, S.saving = false, false
    SendNUIMessage({ action = 'result', ok = false })
end)

RegisterNetEvent('whip_appearance:client:forceClose', function(why)
    if not S or S.mode ~= 'shop' then return end
    if why and why ~= '' then notify(why, 'info') end
    close(true, false)
end)

RegisterNetEvent('whip_appearance:client:prices', function()
    if not S then return end
    S.busy = false
    SendNUIMessage({ action = 'quote', quote = quote(), groups = groupsFor(S.view.kind),
                     removePrice = Appearance.priceOf('tattoo', 'remove') })
    SendNUIMessage({ action = 'result', ok = false })
end)

AddEventHandler('whip_core:player:died', function()
    if S then close(true, false) end
end)

AddEventHandler('whip_core:player:logout', function()
    revertOnRevive = nil
    if S then close(false, false) end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RES or not S then return end
    Cam.stop()

    Preview.apply(PlayerPedId(), S.base, false)
end)

local function cb(name, fn)
    RegisterNUICallback(name, function(data, done)
        local ok, res = pcall(fn, type(data) == 'table' and data or {})
        if not ok then
            print(('[whip_appearance] callback "%s" failed: %s'):format(name, tostring(res)))
            res = nil
        end
        done(res or {})
    end)
end

cb('change', function(data)
    if not S or S.busy or type(data.look) ~= 'table' then return end
    local look = data.look
    look.model = S.look.model
    if S.view.kind == 'tattoo' then

        local list, seen = {}, {}
        for _, t in ipairs(type(look.tattoos) == 'table' and look.tattoos or {}) do
            local k = Appearance.tattooKey(t)
            if k and not seen[k] and Appearance.tattooInfo(k) and #list < Appearance.TATTOO_MAX then
                seen[k] = true
                list[#list + 1] = { collection = t.collection, overlay = t.overlay }
            end
        end
        look = Appearance.copy(S.base)
        look.tattoos = list
        S.look = look
        queueApply(look)
        return { quote = quote() }
    end
    look.tattoos = S.base.tattoos
    if type(look.faceFeatures) ~= 'table' or #look.faceFeatures ~= 20 then return end
    S.look = look
    queueApply(look)
    return { quote = quote() }
end)

cb('textures', function(data)
    if not S then return end
    local id = math.floor(tonumber(data.id) or -1)
    if id < 0 or id > 11 then return { count = 0 } end
    return { count = Preview.textures(PlayerPedId(), data.kind == 'prop' and 'prop' or 'component', id, data.drawable) }
end)

cb('sex', function(data)
    if not S or S.busy or S.view.kind ~= 'surgery' then return end
    local model = data.female and Appearance.MODELS.female or Appearance.MODELS.male
    if model == S.look.model then return { reload = pageData() } end
    while applying do Wait(0) end

    local look = Appearance.copy(S.look)
    look.model = model
    if model == S.base.model then

        for _, k in ipairs({ 'components', 'props', 'hair', 'hairFade' }) do look[k] = Appearance.copy(S.base[k]) end
        for _, n in ipairs({ 'beard', 'eyebrows', 'chestHair', 'makeup', 'blush', 'lipstick' }) do
            look.overlays[n] = Appearance.copy(S.base.overlays[n])
        end
    else
        look.components, look.props, look.hairFade = {}, {}, nil
        look.hair = { style = 0, texture = 0, color = look.hair and look.hair.color or 0, highlight = look.hair and look.hair.highlight or 0 }
        for _, n in ipairs({ 'beard', 'chestHair', 'makeup', 'blush', 'lipstick' }) do
            look.overlays[n] = Appearance.OVERLAY_COLOR[n] and { type = 0, opacity = 0.0, color = 0, color2 = 0 } or { type = 0, opacity = 0.0 }
        end
    end
    look.tattoos = S.base.tattoos

    if not Preview.swapModel(look) then
        notify('Could not load the model.', 'error')
        return { reload = pageData() }
    end
    S.look = Preview.complete(PlayerPedId(), look)
    Cam.refresh()
    return { reload = pageData() }
end)

cb('frame', function(data)
    if S and type(data.cam) == 'string' then Cam.frame(data.cam) end
end)

cb('turn', function(data)
    if S then Cam.turn(math.max(-90.0, math.min(90.0, tonumber(data.deg) or 0.0))) end
end)

cb('faceSide', function(data)
    if S then Cam.faceSide(math.max(-180.0, math.min(180.0, tonumber(data.deg) or 0.0))) end
end)

cb('undress', function(data)
    if not S or S.view.kind ~= 'tattoo' then return end
    S.undressed = data.on == true
    queueApply(S.look)
    return { undressed = S.undressed }
end)

cb('orbit', function(data)
    if not S then return end
    local dx = math.max(-90.0, math.min(90.0, tonumber(data.dx) or 0.0))
    local dy = math.max(-0.5, math.min(0.5, tonumber(data.dy) or 0.0))
    if dx ~= 0.0 then Cam.turn(dx) end
    if dy ~= 0.0 then Cam.raise(dy) end
end)

cb('zoom', function(data)
    if S then Cam.zoom(math.max(-0.5, math.min(0.5, tonumber(data.delta) or 0.0))) end
end)

cb('buy', function(data)
    if not S or S.busy then return end
    if S.mode == 'builder' then
        S.picked = Appearance.outfitOf(S.look)
        close(true, false)
        return
    end
    local q = quote()
    if #q.lines == 0 then
        notify('You did not change anything.', 'info')
        return { ok = false }
    end
    local method = data.method == 'bank' and S.view.allowBank and 'bank' or 'cash'
    S.busy = true
    TriggerServerEvent('whip_appearance:buy', S.look, method, q.total)

    SetTimeout(4000, function()
        if S and S.busy and not S.saving then
            S.busy = false
            SendNUIMessage({ action = 'result', ok = false })
        end
    end)
    return { ok = true }
end)

cb('cancel', function()
    if not S or S.busy then return end
    close(true, true)
end)

cb('pick', function(data)
    if S and type(data.key) == 'string' then Anims.tryOn(data.key) end
end)

cb('typing', function(data)
    if S then screen:typing(data.on == true) end
end)

cb('adminSave', function(data)
    if not S or not S.view.admin then return { ok = false } end
    local res, why = Whip.core:Callback('whip_appearance:admin:save', data.piece, data.rule)
    if not res then
        notify(why or 'Could not save.', 'error')
        return { ok = false }
    end
    S.view.rules, S.view.categories = res.rules, res.categories
    notify(res.message or 'Rule saved.', 'success')
    return { ok = true, rules = res.rules, categories = res.categories }
end)

cb('adminCategory', function(data)
    if not S or not S.view.admin then return { ok = false } end
    local res, why = Whip.core:Callback('whip_appearance:admin:category', data.category, data.rule)
    if not res then
        notify(why or 'Could not save.', 'error')
        return { ok = false }
    end
    S.view.rules, S.view.categories = res.rules, res.categories
    if res.tattoos then S.view.tattoos = res.tattoos end
    notify(res.message or 'Category saved.', 'success')
    return { ok = true, rules = res.rules, categories = res.categories }
end)

cb('adminTattoos', function(data)
    if not S then return { ok = false, why = 'The store is not open.' } end
    if not S.view.admin then return { ok = false, why = 'No Admin permission in this store.' } end
    if type(data.keys) ~= 'table' then return { ok = false, why = 'No tattoo selected.' } end
    local rule = type(data.rule) == 'table' and data.rule or {}
    local res, why = Whip.core:Callback('whip_appearance:admin:tattoos', data.keys, rule)
    if not res then
        notify(why or 'Could not save.', 'error')
        return { ok = false, why = why or 'Could not save.' }
    end
    S.view.rules, S.view.categories, S.view.tattoos = res.rules, res.categories, res.tattoos
    notify(res.message or 'Rule saved.', 'success')
    return { ok = true, tattoos = res.tattoos, quote = quote() }
end)

local function wardrobeOutfit(id)
    for _, o in ipairs(S and S.view.wardrobe and S.view.wardrobe.outfits or {}) do
        if o.id == id then return o end
    end
    return nil
end

local function openWardrobeView(view)
    local ok, why = open(view)
    if not ok then
        TriggerServerEvent('whip_appearance:wardrobe:close')
        notify(why, 'error')
    end
    return ok
end

function Appearance.Client.openWardrobe(index)
    local view, why = Whip.core:Callback('whip_appearance:wardrobe:open', index)
    if not view then return notify(why or 'The wardrobe did not open.', 'error') end
    openWardrobeView(view)
end

RegisterNetEvent('whip_appearance:client:wardrobe', function(view)
    if type(view) ~= 'table' or view.kind ~= 'wardrobe' then return end
    CreateThread(function() openWardrobeView(view) end)
end)

local function isWardrobe() return S ~= nil and S.view.kind == 'wardrobe' and type(S.view.wardrobe) == 'table' end

cb('wardrobePreview', function(data)
    if not isWardrobe() or S.busy then return end
    local o = wardrobeOutfit(tonumber(data.id))
    if o and o.model == S.base.model then
        S.look = Appearance.wear(S.base, o)
        Anims.tryOn('c11')
    else
        S.look = Appearance.copy(S.base)
    end
    queueApply(S.look)
end)

cb('wardrobeWear', function(data)
    if not isWardrobe() or S.busy then return { ok = false } end
    S.busy = true
    local res, why = Whip.core:Callback('whip_appearance:wardrobe:wear', math.floor(tonumber(data.id) or 0))
    if not S then return { ok = false } end
    S.busy, S.saving = false, false
    if not res then
        notify(why or 'Could not put it on.', 'error')
        return { ok = false }
    end
    S.base = S.look
    notify(('Outfit "%s" put on.'):format(tostring(res.name or '')), 'success')
    close(false, true)
    return { ok = true }
end)

cb('wardrobeRestore', function()
    if not isWardrobe() or S.busy then return { ok = false } end
    S.busy = true
    local res, why = Whip.core:Callback('whip_appearance:wardrobe:restore')
    if not S then return { ok = false } end
    S.busy, S.saving = false, false
    if not res then
        notify(why or 'Could not change.', 'error')
        return { ok = false }
    end
    S.base = S.look
    notify('You are back in your own clothes.', 'success')
    close(false, true)
    return { ok = true }
end)

cb('wardrobeBuild', function()
    if not isWardrobe() or S.busy or not S.view.wardrobe.canManage then return end
    local view = S.view
    close(true, false)
    CreateThread(function()
        while S or applying do Wait(50) end
        Wait(250)
        local ok, why = open({ kind = 'clothing', title = 'Build outfit: ' .. tostring(view.wardrobe.jobName), free = true,
                               test = false, allowBank = false, rules = view.wardrobe.rules },
            { mode = 'builder', onPick = function(outfit)
                CreateThread(function()
                    Wait(250)
                    if not openWardrobeView(view) then return end
                    if outfit then
                        S.draft = outfit
                        S.look = Appearance.wear(S.base, outfit)
                        queueApply(S.look)
                        SendNUIMessage({ action = 'wardrobeDraft' })
                    end
                end)
            end })
        if not ok then
            notify(why or 'The store did not open.', 'error')
            openWardrobeView(view)
        end
    end)
end)

cb('wardrobeSave', function(data)
    if not isWardrobe() or not S.view.wardrobe.canManage then return { ok = false } end
    local id = math.floor(tonumber(data.id) or 0)
    local outfit = (data.source == 'draft') and S.draft or nil
    if data.source == 'draft' and not outfit then return { ok = false, why = 'Build the outfit first.' } end
    local res, why = Whip.core:Callback('whip_appearance:wardrobe:save', id, tostring(data.name or ''),
        math.max(0, math.floor(tonumber(data.minLevel) or 0)), outfit or false, data.source == 'worn')
    if not res then
        notify(why or 'Could not save the outfit.', 'error')
        return { ok = false, why = why }
    end
    if S and S.view.wardrobe then
        S.view.wardrobe.outfits = res.outfits
        S.draft = nil
    end
    notify('Outfit saved.', 'success')
    return { ok = true, id = res.id, outfits = res.outfits }
end)

cb('wardrobeDelete', function(data)
    if not isWardrobe() or not S.view.wardrobe.canManage then return { ok = false } end
    local res, why = Whip.core:Callback('whip_appearance:wardrobe:delete', math.floor(tonumber(data.id) or 0))
    if not res then
        notify(why or 'Could not delete.', 'error')
        return { ok = false }
    end
    if S and S.view.wardrobe then S.view.wardrobe.outfits = res.outfits end
    S.look = Appearance.copy(S.base)
    queueApply(S.look)
    notify('Outfit deleted.', 'success')
    return { ok = true, outfits = res.outfits }
end)

cb('adminGive', function(data)
    if not S or not S.view.admin then return end
    local ok, why = Whip.core:Callback('whip_appearance:admin:give', tostring(data.item or ''))
    notify(ok and 'Item given to you.' or (why or 'Could not give the item.'), ok and 'success' or 'error')
end)

Appearance.Client = Appearance.Client or {}

function Appearance.Client.pickOutfit(onPick)
    return open({ kind = 'clothing', title = 'Pick outfit (Director)', free = true, test = false, allowBank = false },
        { mode = 'builder', onPick = onPick })
end

RegisterNetEvent('whip_appearance:client:wear', function(outfit)
    if S or type(outfit) ~= 'table' then return end
    local saved = savedLook()
    if not saved then return end
    if outfit.model and outfit.model ~= saved.model then return end
    CreateThread(function() Preview.apply(PlayerPedId(), Appearance.wear(Preview.complete(PlayerPedId(), saved), outfit), false) end)
end)

RegisterNetEvent('whip_appearance:client:restore', function()
    if S then return end
    local saved = savedLook()
    if not saved then return end
    CreateThread(function() Preview.apply(PlayerPedId(), saved, true) end)
end)
