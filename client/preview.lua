Preview = {}

local PROP_SLOTS = { 0, 1, 2, 6, 7 }

local function safeComponent(ped, id, drawable, texture)
    local d, t = math.floor(tonumber(drawable) or 0), math.floor(tonumber(texture) or 0)
    local nd = GetNumberOfPedDrawableVariations(ped, id)
    if nd and nd > 0 then
        if d < 0 or d >= nd then d = nd - 1 end
    else
        d = 0
    end
    local nt = GetNumberOfPedTextureVariations(ped, id, d)
    if not nt or nt <= 0 or t < 0 or t >= nt then t = 0 end
    return id, d, t, 0
end

local function setProp(ped, id, drawable, texture)
    local d, t = math.floor(tonumber(drawable) or -1), math.floor(tonumber(texture) or 0)
    local nd = GetNumberOfPedPropDrawableVariations(ped, id)
    if d < 0 or not nd or nd <= 0 or d >= nd then
        ClearPedProp(ped, id)
        return
    end
    local nt = GetNumberOfPedPropTextureVariations(ped, id, d)
    if not nt or nt <= 0 or t < 0 or t >= nt then t = 0 end
    SetPedPropIndex(ped, id, d, t, true)
end

local function blendSig(hb)
    hb = hb or {}
    return ('%s|%s|%s|%s|%s|%s'):format(hb.mom or 0, hb.dad or 0, hb.grandparent or 0,
        hb.faceWeight or 0.5, hb.skinWeight or 0.5, hb.thirdWeight or 0.0)
end

local function decoSig(look)
    local parts = {}
    for i, t in ipairs(type(look.tattoos) == 'table' and look.tattoos or {}) do
        parts[i] = tostring(t.collection) .. '/' .. tostring(t.overlay)
    end
    local f = type(look.hairFade) == 'table' and (tostring(look.hairFade.collection) .. '/' .. tostring(look.hairFade.overlay)) or ''
    return f .. '|' .. table.concat(parts, ',')
end

local function applyDecorations(ped, look)
    ClearPedDecorationsLeaveScars(ped)
    local fade = look.hairFade
    if type(fade) == 'table' and type(fade.collection) == 'string' and type(fade.overlay) == 'string' then
        AddPedDecorationFromHashes(ped, GetHashKey(fade.collection), GetHashKey(fade.overlay))
    end
    for _, t in ipairs(type(look.tattoos) == 'table' and look.tattoos or {}) do
        if type(t) == 'table' and type(t.collection) == 'string' and type(t.overlay) == 'string' then
            AddPedDecorationFromHashes(ped, GetHashKey(t.collection), GetHashKey(t.overlay))
        end
    end
end

local last = { ped = 0, blend = nil, deco = nil }

function Preview.reset() last = { ped = 0, blend = nil, deco = nil } end

function Preview.forgetBlend() last.blend = nil end

function Preview.apply(ped, look, force)
    if not ped or ped == 0 or type(look) ~= 'table' then return end
    if ped ~= last.ped then force = true end

    local sig = blendSig(look.headBlend)
    if force or sig ~= last.blend then
        local hb = look.headBlend or {}
        SetPedHeadBlendData(ped, hb.mom or 0, hb.dad or 0, hb.grandparent or 0, hb.mom or 0, hb.dad or 0, hb.grandparent or 0,
            (hb.faceWeight or 0.5) + 0.0, (hb.skinWeight or 0.5) + 0.0, (hb.thirdWeight or 0.0) + 0.0, false)
        local deadline = GetGameTimer() + 500
        while not HasPedHeadBlendFinished(ped) and GetGameTimer() < deadline do Wait(0) end
        last.blend = sig
    end

    local ff = look.faceFeatures or {}
    for i = 0, 19 do SetPedFaceFeature(ped, i, (tonumber(ff[i + 1]) or 0.0) + 0.0) end
    SetPedEyeColor(ped, math.floor(tonumber(look.eyeColor) or 0))

    local hair = look.hair or {}
    SetPedComponentVariation(ped, safeComponent(ped, 2, hair.style, hair.texture))
    SetPedHairColor(ped, math.floor(tonumber(hair.color) or 0), math.floor(tonumber(hair.highlight) or 0))

    local ovs = look.overlays or {}
    for name, id in pairs(Appearance.OVERLAY_ID) do
        local o = ovs[name] or {}
        local t, op = math.floor(tonumber(o.type) or 0), (tonumber(o.opacity) or 0.0) + 0.0
        if (t == 0 and op == 0.0) or t == 255 then
            SetPedHeadOverlay(ped, id, 255, 0.0)
        else
            SetPedHeadOverlay(ped, id, t, op)
            local ct = Appearance.OVERLAY_COLOR[name]
            if ct then SetPedHeadOverlayColor(ped, id, ct, math.floor(tonumber(o.color) or 0), math.floor(tonumber(o.color2) or 0)) end
        end
    end

    for key, c in pairs(look.components or {}) do
        local id = tonumber(key)
        if id and id ~= 2 and type(c) == 'table' then SetPedComponentVariation(ped, safeComponent(ped, id, c.drawable, c.texture)) end
    end
    for key, p in pairs(look.props or {}) do
        local id = tonumber(key)
        if id and type(p) == 'table' then setProp(ped, id, p.drawable, p.texture) end
    end

    local deco = decoSig(look)
    if force or deco ~= last.deco then
        applyDecorations(ped, look)
        last.deco = deco
    end
    last.ped = ped

    if MaskFix then MaskFix.update(look, true) end
end

function Preview.complete(ped, look)
    local out = Appearance.copy(look)
    out.components = type(out.components) == 'table' and out.components or {}
    out.props = type(out.props) == 'table' and out.props or {}
    for i = 1, 11 do
        local k = tostring(i)
        if i ~= 2 and type(out.components[k]) ~= 'table' then
            out.components[k] = { drawable = GetPedDrawableVariation(ped, i), texture = GetPedTextureVariation(ped, i) }
        end
    end
    for _, i in ipairs(PROP_SLOTS) do
        local k = tostring(i)
        if type(out.props[k]) ~= 'table' then
            out.props[k] = { drawable = GetPedPropIndex(ped, i), texture = math.max(0, GetPedPropTextureIndex(ped, i)) }
        end
    end
    out.hair = type(out.hair) == 'table' and out.hair or {}
    out.overlays = type(out.overlays) == 'table' and out.overlays or {}
    for name in pairs(Appearance.OVERLAY_ID) do
        if type(out.overlays[name]) ~= 'table' then
            out.overlays[name] = Appearance.OVERLAY_COLOR[name] and { type = 0, opacity = 0.0, color = 0, color2 = 0 }
                or { type = 0, opacity = 0.0 }
        end
    end
    return out
end

function Preview.maxes(ped)
    local out = { components = {}, props = {}, overlays = {}, hair = GetNumberOfPedDrawableVariations(ped, 2) }
    for i = 0, 11 do out.components[tostring(i)] = GetNumberOfPedDrawableVariations(ped, i) end
    for _, i in ipairs(PROP_SLOTS) do out.props[tostring(i)] = GetNumberOfPedPropDrawableVariations(ped, i) end
    for name, id in pairs(Appearance.OVERLAY_ID) do out.overlays[name] = GetPedHeadOverlayNum(id) end
    return out
end

function Preview.textures(ped, kind, id, drawable)
    drawable = math.floor(tonumber(drawable) or 0)
    if kind == 'prop' then
        if drawable < 0 then return 0 end
        return GetNumberOfPedPropTextureVariations(ped, id, drawable)
    end
    return GetNumberOfPedTextureVariations(ped, id, drawable)
end

function Preview.palettes()
    local hair, makeup = {}, {}
    for i = 0, GetNumHairColors() - 1 do
        local r, g, b = GetPedHairRgbColor(i)
        hair[#hair + 1] = { r, g, b }
    end
    for i = 0, GetNumMakeupColors() - 1 do
        local r, g, b = GetPedMakeupRgbColor(i)
        makeup[#makeup + 1] = { r, g, b }
    end
    return { hair = hair, makeup = makeup }
end

local function iconNames(count, nameOf, indexOf, base)
    local out = {}
    for d = 0, count - 1 do
        local name, idx = nameOf(d), indexOf(d)
        if type(name) ~= 'string' or type(idx) ~= 'number' or idx < 0 then
            out[d + 1] = ''
        else
            if name == '' or name == base then name = 'base' end
            out[d + 1] = ('%s_%03d'):format(name, idx)
        end
    end
    return out
end

function Preview.icons(ped)
    local model = GetEntityModel(ped)
    local gender = (model == GetHashKey(Appearance.MODELS.male) and 'male') or (model == GetHashKey(Appearance.MODELS.female) and 'female') or nil
    if not gender or GetPedCollectionNameFromDrawable == nil or GetPedCollectionNameFromProp == nil then return nil end
    local base = GetPedCollectionName(ped, 0)
    local out = { gender = gender, components = {}, props = {} }
    for comp = 0, 11 do
        out.components[tostring(comp)] = iconNames(GetNumberOfPedDrawableVariations(ped, comp),
            function(d) return GetPedCollectionNameFromDrawable(ped, comp, d) end,
            function(d) return GetPedCollectionLocalIndexFromDrawable(ped, comp, d) end, base)
    end
    for _, slot in ipairs(PROP_SLOTS) do
        out.props[tostring(slot)] = iconNames(GetNumberOfPedPropDrawableVariations(ped, slot),
            function(d) return GetPedCollectionNameFromProp(ped, slot, d) end,
            function(d) return GetPedCollectionLocalIndexFromProp(ped, slot, d) end, base)
    end
    return out
end

local picturesFor, picturesAsked = {}, {}

function Preview.pictures(gender)
    if not gender then return nil end
    if picturesFor[gender] == nil and not picturesAsked[gender] then
        picturesAsked[gender] = true
        local got = Whip.core:Callback('whip_core:appearance:clothingPictures', gender)
        picturesAsked[gender] = nil
        picturesFor[gender] = type(got) == 'table' and got or false
    end
    return picturesFor[gender] or nil
end

local DECO_ZONES = { [0] = 'torso', [1] = 'head', [2] = 'larm', [3] = 'rarm', [4] = 'lleg', [5] = 'rleg' }
local tattoosByBody = {}

function Preview.tattoos(ped)
    local model = GetEntityModel(ped)
    local body = (model == GetHashKey(Appearance.MODELS.male) and 'm') or (model == GetHashKey(Appearance.MODELS.female) and 'f') or nil
    if not body or Appearance.tattooCount() == 0 then return nil end
    if tattoosByBody[body] then return tattoosByBody[body] end
    local out = { head = {}, torso = {}, larm = {}, rarm = {}, lleg = {}, rleg = {} }
    local hashes = {}
    for i, c in ipairs(TattooList.collections) do hashes[i] = GetHashKey(c.name) end
    for _, t in ipairs(TattooList.list) do
        if t[4]:find(body, 1, true) then
            local zone = DECO_ZONES[GetPedDecorationZoneFromHashes(hashes[t[1]], GetHashKey(t[2]))]
            local coll = TattooList.collections[t[1]]
            if zone and coll then
                local list = out[zone]
                list[#list + 1] = { key = (coll.name .. '/' .. t[2]):lower(), collection = coll.name, overlay = t[2],
                                    name = (t[6] ~= nil and t[6] ~= '') and t[6] or nil, facing = t[5] or '' }
            end
        end
    end
    tattoosByBody[body] = out
    return out
end

local NOTHING = {
    male = {
        ['1'] = { 'base', 0 }, ['3'] = { 'base', 15 }, ['4'] = { 'base', 14 }, ['5'] = { 'base', 0 },
        ['6'] = { 'male_apt01', 1 }, ['7'] = { 'base', 0 }, ['8'] = { 'base', 15 }, ['9'] = { 'base', 0 },
        ['10'] = { 'base', 0 }, ['11'] = { 'base', 15 },
    },
    female = {
        ['1'] = { 'base', 0 }, ['3'] = { 'base', 15 }, ['4'] = { 'base', 15 }, ['5'] = { 'base', 0 },
        ['6'] = { 'female_apt01', 1 }, ['7'] = { 'base', 0 }, ['8'] = { 'base', 14 }, ['9'] = { 'base', 0 },
        ['10'] = { 'base', 0 }, ['11'] = { 'base', 15 },
    },
}

function Preview.nothingFor(ped, slot)
    local body = GetEntityModel(ped) == GetHashKey(Appearance.MODELS.female) and 'female' or 'male'
    local item = NOTHING[body][tostring(slot)]
    if not item then return 0 end
    if item[1] == 'base' then return item[2] end
    if GetPedDrawableGlobalIndexFromCollection ~= nil then
        local d = GetPedDrawableGlobalIndexFromCollection(ped, slot, item[1], item[2])
        if d and d >= 0 and d < GetNumberOfPedDrawableVariations(ped, slot) then return d end
    end
    return 0
end

local HEAD_COMPONENTS = { 1 }
local HEAD_PROPS = { 0, 1 }
local TORSO_COMPONENTS = { 3, 8, 11 }

function Preview.hidden(ped, look, hide)
    if hide.clothes then return Preview.undressed(ped, look) end
    local out = Appearance.copy(look)
    out.components = type(out.components) == 'table' and out.components or {}
    out.props = type(out.props) == 'table' and out.props or {}
    local slots = {}
    if hide.head then for _, i in ipairs(HEAD_COMPONENTS) do slots[#slots + 1] = i end end
    if hide.torso then for _, i in ipairs(TORSO_COMPONENTS) do slots[#slots + 1] = i end end
    for _, i in ipairs(slots) do
        out.components[tostring(i)] = { drawable = Preview.nothingFor(ped, i), texture = 0 }
    end
    if hide.head then
        for _, i in ipairs(HEAD_PROPS) do out.props[tostring(i)] = { drawable = -1, texture = 0 } end
    end
    return out
end

function Preview.undressed(ped, look)
    local out = Appearance.copy(look)
    out.components = type(out.components) == 'table' and out.components or {}
    out.props = type(out.props) == 'table' and out.props or {}
    for slot in pairs(NOTHING.male) do
        out.components[slot] = { drawable = Preview.nothingFor(ped, tonumber(slot)), texture = 0 }
    end
    for _, i in ipairs(PROP_SLOTS) do out.props[tostring(i)] = { drawable = -1, texture = 0 } end
    return out
end

function Preview.fades(model)
    local body = model == Appearance.MODELS.female and 'f' or 'm'
    local out = {}
    if type(HairFades) ~= 'table' then return out end
    for _, f in ipairs(HairFades.list or {}) do
        if tostring(f[3]):find(body, 1, true) then
            local coll = HairFades.collections[f[1]]
            if coll then out[#out + 1] = { collection = coll.name, overlay = f[2] } end
        end
    end
    return out
end

function Preview.swapModel(look)
    local model = look.model
    local hash = GetHashKey(model)
    if GetEntityModel(PlayerPedId()) == hash then
        Preview.apply(PlayerPedId(), look, true)
        return true
    end
    local loaded = Whip.core:LoadModel(model)
    if not loaded then return false end

    local old = PlayerPedId()
    local health, armour = GetEntityHealth(old), GetPedArmour(old)
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    Wait(100)

    local ped = PlayerPedId()
    if health > 100 then SetEntityHealth(ped, health) end
    if armour > 0 then SetPedArmour(ped, armour) end
    SetPedDefaultComponentVariation(ped)

    Whip.core:HoldPlayerPed('newped', {})
    Whip.core:ReleasePlayerPed('newped')

    Preview.reset()
    Preview.apply(ped, look, true)
    TriggerEvent('whip_core:appearance:modelChanged', {})
    return true
end
