AppearanceWardrobe = {}

local OUTFITS = AppearanceDB.tables.outfits
local OWN = AppearanceDB.tables.own
local NAME_MAX = 30
local COMPONENTS = { '1', '3', '4', '5', '6', '7', '8', '9', '10', '11' }
local PROPS = { '0', '1', '2', '6', '7' }

local outfits = {}
local Opened = {}

local function notify(src, text, kind) exports.whip_core:NotifyPlayer(src, text, kind or 'info') end

local function vec3Of(p)
    if (type(p) ~= 'table' and type(p) ~= 'vector3' and type(p) ~= 'vector4') or not p.x then return nil end
    return vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
end

local function wardrobeAt(index)
    local w = type(Config.Wardrobes) == 'table' and Config.Wardrobes[index] or nil
    local coords = type(w) == 'table' and vec3Of(w.coords) or nil
    local job = type(w) == 'table' and type(w.job) == 'string' and w.job:lower():match('^%s*(.-)%s*$') or ''
    if not coords or job == '' then return nil end
    return w, coords, job
end
AppearanceWardrobe.at = wardrobeAt

local function near(src, coords, extra)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= (tonumber(Config.UseRange) or 2.5) + (extra or 0.0)
end

local function roleLevel(src, job)
    local r = exports.whip_core:GetPlayerRole(src, job)
    return type(r) == 'table' and (tonumber(r.level) or 0) or nil
end

local function canManage(src, job)
    if AppearanceRules.isAdmin(src) then return true end
    return exports.whip_core:HasJobPermission(src, job, Config.Wardrobe.managePermission or 'canManage') == true
end

local function int(v, lo, hi)
    local n = math.tointeger(tonumber(v))
    if not n or n < lo or n > hi then return nil end
    return n
end

local function cleanOutfit(o)
    if type(o) ~= 'table' then return nil, 'invalid outfit' end
    if o.model ~= Appearance.MODELS.male and o.model ~= Appearance.MODELS.female then return nil, 'invalid body' end
    local out = { model = o.model, components = {}, props = {} }
    local comps, props = type(o.components) == 'table' and o.components or {}, type(o.props) == 'table' and o.props or {}
    for _, k in ipairs(COMPONENTS) do
        local v = comps[k]
        local d = type(v) == 'table' and int(v.drawable, 0, 4095) or nil
        if not d then return nil, 'missing piece ' .. k end
        out.components[k] = { drawable = d, texture = type(v) == 'table' and int(v.texture, 0, 127) or 0 }
    end
    for _, k in ipairs(PROPS) do
        local v = props[k]
        local d = type(v) == 'table' and int(v.drawable, -1, 4095) or -1
        out.props[k] = { drawable = d, texture = d >= 0 and (int(v.texture, 0, 127) or 0) or 0 }
    end
    return out
end

local function tidyName(v)
    if type(v) ~= 'string' then return nil end
    v = v:gsub('[%c<>]', ''):match('^%s*(.-)%s*$')
    if v == '' then return nil end
    return v:sub(1, NAME_MAX)
end

local function load()
    if not AppearanceDB.wait() then return print('^1[whip_appearance] outfits not loaded: the database is not ready^0') end
    outfits = {}
    local rows = MySQL.query.await(('SELECT `id`, `job`, `name`, `model`, `minLevel`, `data` FROM `%s`'):format(OUTFITS)) or {}
    for _, row in ipairs(rows) do
        local ok, data = pcall(json.decode, row.data or '{}')
        local clean = ok and cleanOutfit({ model = row.model, components = data and data.components, props = data and data.props })
        if clean then
            outfits[row.job] = outfits[row.job] or {}
            outfits[row.job][row.id] = { id = row.id, job = row.job, name = row.name, model = row.model,
                                         minLevel = tonumber(row.minLevel) or 0, components = clean.components, props = clean.props }
        end
    end
    print(('[whip_appearance] loaded %d wardrobe outfit(s)'):format(#rows))
end

local function count(job)
    local n = 0
    for _ in pairs(outfits[job] or {}) do n = n + 1 end
    return n
end

local function ownOf(charId)
    local row = MySQL.single.await(('SELECT `outfit` FROM `%s` WHERE `charId` = ?'):format(OWN), { charId })
    if not row then return nil end
    local ok, data = pcall(json.decode, row.outfit or '')
    return ok and cleanOutfit(data) or nil
end

local function keepOwn(charId, outfit)
    MySQL.insert.await(('INSERT IGNORE INTO `%s` (`charId`, `outfit`) VALUES (?, ?)'):format(OWN), { charId, json.encode(outfit) })
end

function AppearanceWardrobe.forgetOwn(charId)
    if not charId then return end
    MySQL.update.await(('DELETE FROM `%s` WHERE `charId` = ?'):format(OWN), { charId })
end

local function jobName(job)
    local j = exports.whip_core:GetJob(job)
    return type(j) == 'table' and j.name or job
end

local function rolesOf(job)
    local out = {}
    local list = exports.whip_core:GetJobRoles(job)
    for _, r in ipairs(type(list) == 'table' and list or {}) do
        out[#out + 1] = { level = tonumber(r.level) or 0, name = r.name or ('Level ' .. tostring(r.level)) }
    end
    table.sort(out, function(a, b) return a.level < b.level end)
    return out
end

local function listFor(src, job, o)
    local level = roleLevel(src, job)
    local admin = AppearanceRules.isAdmin(src)
    local list = {}
    for _, x in pairs(outfits[job] or {}) do
        list[#list + 1] = { id = x.id, name = x.name, model = x.model, minLevel = x.minLevel, components = x.components,
                            props = x.props,
                            allowed = admin or o.free == true or (level ~= nil and level >= (x.minLevel or 0)) }
    end
    table.sort(list, function(a, b) return tostring(a.name):lower() < tostring(b.name):lower() end)
    return list
end

local function viewFor(src, o, title)
    local player = exports.whip_core:GetPlayer(src)
    local manage, admin = canManage(src, o.job), AppearanceRules.isAdmin(src)
    return {
        kind = 'wardrobe', title = title or ('Wardrobe: ' .. jobName(o.job)), free = true, test = false, allowBank = false,
        wardrobe = {
            job = o.job, jobName = jobName(o.job), outfits = listFor(src, o.job, o), roles = rolesOf(o.job),
            canManage = manage, hasOwn = type(player) == 'table' and ownOf(player.charId) ~= nil or false,
            max = tonumber(Config.Wardrobe.maxOutfits) or 60,

            rules = (manage and not admin) and AppearanceRules.view(src).rules or nil,
        },
    }
end

function AppearanceWardrobe.openFor(src, job, opts)
    opts = opts or {}
    local player = Whip.core:GetPlayer(src)
    if type(player) ~= 'table' then return false, 'the player is not on a character' end
    if AppearanceServer.isOpen(src) or Opened[src] then return false, 'the player is already in a store or wardrobe' end
    if type(job) ~= 'string' or job == '' then return false, 'no job' end
    Opened[src] = { job = job:lower(), session = player.session, free = true }
    TriggerClientEvent('whip_appearance:client:wardrobe', src, viewFor(src, Opened[src], opts.title))
    return true
end

function AppearanceWardrobe.outfitsOf(job)
    local out = {}
    for _, x in pairs(outfits[type(job) == 'string' and job:lower() or ''] or {}) do out[#out + 1] = x end
    return out
end

local function current(src)
    local o = Opened[src]
    if not o then return nil, 'No wardrobe open.' end
    if not exports.whip_core:IsSessionCurrent(src, o.session) then
        Opened[src] = nil
        return nil, 'No wardrobe open.'
    end
    if o.coords and not near(src, o.coords, 5.0) then return nil, 'You walked away from the wardrobe.' end
    return o
end

local function onOpen(source, player, index)
    if Opened[source] or AppearanceServer.isOpen(source) then return false, 'You are already in a store or wardrobe.' end
    local w, coords, job = wardrobeAt(index)
    if not w then return false, 'That wardrobe no longer exists.' end
    if not near(source, coords, 1.5) then return false, 'Get closer to the wardrobe.' end
    local admin = AppearanceRules.isAdmin(source)
    if not admin then
        if not roleLevel(source, job) then return false, 'This wardrobe is only for people who work here.' end
        if w.onDuty == true and exports.whip_core:IsPlayerClockedOn(source, job) ~= true then
            return false, 'Clock on to use the wardrobe.'
        end
    end
    local _, why = AppearanceServer.savedLook(source)
    if why then return false, why end
    Opened[source] = { job = job, coords = coords, session = player.session }
    return viewFor(source, Opened[source], w.name)
end

local function onWear(source, player, id)
    local o, why = current(source)
    if not o then return false, why end
    if o.busy then return false, 'Please wait.' end
    local x = outfits[o.job] and outfits[o.job][id]
    if not x then return false, 'That outfit no longer exists.' end
    if not o.free and not AppearanceRules.isAdmin(source) and (roleLevel(source, o.job) or -1) < (x.minLevel or 0) then
        return false, 'Your rank cannot wear this outfit.'
    end
    local saved, err = AppearanceServer.savedLook(source)
    if not saved then return false, err end
    if saved.model ~= x.model then
        return false, x.model == Appearance.MODELS.female and 'This outfit is for a female body.' or 'This outfit is for a male body.'
    end
    local ok, final = exports.whip_core:SanitizeAppearance(Appearance.wear(saved, x))
    if not ok then return false, 'Outfit refused: ' .. tostring(final) end

    o.busy = true

    keepOwn(player.charId, Appearance.outfitOf(saved))
    local saveOk = AppearanceServer.saveLook(source, player.session, final)
    o.busy = false
    if not saveOk then return false, 'Could not put the outfit on.' end
    return { ok = true, name = x.name }
end

local function onRestore(source, player)
    local o, why = current(source)
    if not o then return false, why end
    if o.busy then return false, 'Please wait.' end
    local own = ownOf(player.charId)
    if not own then return false, 'You are already in your own clothes.' end
    local saved, err = AppearanceServer.savedLook(source)
    if not saved then return false, err end
    if saved.model ~= own.model then
        AppearanceWardrobe.forgetOwn(player.charId)
        return false, 'The stored clothes were for another body and were discarded.'
    end
    local ok, final = exports.whip_core:SanitizeAppearance(Appearance.wear(saved, own))
    if not ok then return false, 'Clothes refused: ' .. tostring(final) end
    o.busy = true
    local saveOk = AppearanceServer.saveLook(source, player.session, final)
    o.busy = false
    if not saveOk then return false, 'Could not change clothes.' end
    AppearanceWardrobe.forgetOwn(player.charId)
    return { ok = true }
end

local function onSave(source, player, id, name, minLevel, outfit, fromWorn)
    local o, why = current(source)
    if not o then return false, why end
    if not canManage(source, o.job) then return false, 'Only company management (or staff) can build outfits.' end
    local nameOk = tidyName(name)
    if not nameOk then return false, 'Give the outfit a name.' end
    local level = int(minLevel, 0, 1000) or 0
    local list = outfits[o.job] or {}
    local existing = id and id > 0 and list[id] or nil
    if id and id > 0 and not existing then return false, 'That outfit no longer exists.' end

    local clean
    if fromWorn then
        local saved, err = AppearanceServer.savedLook(source)
        if not saved then return false, err end
        clean = cleanOutfit(Appearance.outfitOf(saved))
    elseif type(outfit) == 'table' then
        local err
        clean, err = cleanOutfit(outfit)
        if not clean then return false, 'Invalid outfit: ' .. tostring(err) end
    elseif existing then
        clean = { model = existing.model, components = existing.components, props = existing.props }
    end
    if not clean then return false, 'Build the outfit\'s clothes first.' end
    if not AppearanceRules.isAdmin(source) then
        local ok, err = AppearanceRules.checkOutfit(source, player.charId, clean)
        if not ok then return false, err end
    end

    local data = json.encode({ components = clean.components, props = clean.props })
    if existing then
        MySQL.update.await(('UPDATE `%s` SET `name` = ?, `model` = ?, `minLevel` = ?, `data` = ? WHERE `id` = ?'):format(OUTFITS),
            { nameOk, clean.model, level, data, id })
        existing.name, existing.model, existing.minLevel = nameOk, clean.model, level
        existing.components, existing.props = clean.components, clean.props
    else
        if count(o.job) >= (tonumber(Config.Wardrobe.maxOutfits) or 60) then
            return false, 'This company already has the most outfits allowed. Delete one to create another.'
        end
        local newId = MySQL.insert.await(('INSERT INTO `%s` (`job`, `name`, `model`, `minLevel`, `data`) VALUES (?, ?, ?, ?, ?)')
            :format(OUTFITS), { o.job, nameOk, clean.model, level, data })
        if not newId then return false, 'Could not save the outfit.' end
        outfits[o.job] = list
        list[newId] = { id = newId, job = o.job, name = nameOk, model = clean.model, minLevel = level,
                        components = clean.components, props = clean.props }
        id = newId
    end
    print(('[whip_appearance] wardrobe %s: outfit "%s" saved by %s'):format(o.job, nameOk, tostring(player.charId)))
    return { ok = true, id = id, outfits = listFor(source, o.job, o) }
end

local function onDelete(source, player, id)
    local o, why = current(source)
    if not o then return false, why end
    if not canManage(source, o.job) then return false, 'Only company management (or staff) can delete outfits.' end
    local x = outfits[o.job] and outfits[o.job][id]
    if not x then return false, 'That outfit no longer exists.' end
    MySQL.update.await(('DELETE FROM `%s` WHERE `id` = ?'):format(OUTFITS), { id })
    outfits[o.job][id] = nil
    print(('[whip_appearance] wardrobe %s: outfit "%s" deleted by %s'):format(o.job, x.name, tostring(player.charId)))
    return { ok = true, outfits = listFor(source, o.job, o) }
end

local function onClose(source) Opened[source] = nil end

RegisterCommand('appearance_wardrobe', function(source, args)
    if source == 0 then return print('[whip_appearance] use in game: /appearance_wardrobe <job>') end
    if not AppearanceRules.isAdmin(source) then return notify(source, 'Only staff (whip_appearance.admin) can use this command.', 'error') end
    local job = args[1] and args[1]:lower() or nil
    if not job or not exports.whip_core:GetJob(job) then
        return notify(source, 'Use /appearance_wardrobe <job> with a job key (e.g. police).', 'error')
    end
    local ok, why = AppearanceWardrobe.openFor(source, job, { title = 'Wardrobe: ' .. jobName(job) .. ' (staff)' })
    if not ok then notify(source, 'The wardrobe did not open: ' .. tostring(why), 'error') end
end, false)

Whip.register(function()
    exports.whip_core:SecureCallback('whip_appearance:wardrobe:open', {
        rateLimit = 1000, burst = 2,
        params = { { 'index', 'amount', 500 } },
    }, onOpen)
    exports.whip_core:SecureCallback('whip_appearance:wardrobe:wear', {
        rateLimit = 1500, burst = 2,
        params = { { 'id', 'id' } },
    }, onWear)
    exports.whip_core:SecureCallback('whip_appearance:wardrobe:restore', {
        rateLimit = 1500, burst = 2,
    }, onRestore)
    exports.whip_core:SecureCallback('whip_appearance:wardrobe:save', {
        rateLimit = 1000, burst = 3,
        params = {
            { 'id', 'id', 0, 100000000 },
            { 'name', 'string', 60, '' },
            { 'minLevel', 'id', 0, 1000 },
            { 'outfit', 'any' },
            { 'fromWorn', 'bool', false },
        },
    }, onSave)
    exports.whip_core:SecureCallback('whip_appearance:wardrobe:delete', {
        rateLimit = 1000, burst = 3,
        params = { { 'id', 'id' } },
    }, onDelete)
    exports.whip_core:SecureEvent('whip_appearance:wardrobe:close', {
        rateLimit = 500, burst = 3, whileDead = true,
    }, onClose)

    load()
end)

AddEventHandler('whip_core:player:logout', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' then return end
    local src = tonumber(e.source)
    if src then Opened[src] = nil end
end)

AddEventHandler('playerDropped', function()
    Opened[source] = nil
end)
