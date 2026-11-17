AppearanceRules = {}

local TABLE = AppearanceDB.tables.rules
local CATS = AppearanceDB.tables.categories
local BRANDS = { binco = true, suburban = true, ponsonbys = true, discount = true }
local PROP_SLOTS = { [0] = true, [1] = true, [2] = true, [6] = true, [7] = true }
local ITEM_PICTURE = 'html/img/items/whip_appearance_clothing.png'
local ALL = -1

local TATS = AppearanceDB.tables.tattoo_rules

local rules = {}
local cats = {}
local byItem = {}
local tats = {}

local function keyOf(gender, kind, slot, drawable, texture)
    return ('%s:%s:%d:%d:%d'):format(gender, kind, slot, drawable, texture or ALL)
end

local function catKeyOf(kind, slot) return ('%s:%d'):format(kind, slot) end

local function groupKey(kind, slot) return (kind == 'prop' and 'p' or 'c') .. slot end

local function groupOf(kind, slot)
    for _, g in ipairs(Appearance.Groups.clothing) do
        if g.key == groupKey(kind, slot) then return g end
    end
    return nil
end

local HAIR_SLOT = 2

local function isCategoryKind(kind) return kind == 'barber' or kind == 'surgery' end

local function slotLabel(kind, slot)
    if isCategoryKind(kind) then
        local g = Appearance.Groups[kind][slot]
        return g and g.label or 'Category'
    end
    if kind == 'component' and slot == HAIR_SLOT then return 'Haircut' end
    if kind == 'tattoo' then
        local g = Appearance.Groups.tattoo[slot]
        return g and ('Tattoos: ' .. g.label) or 'Tattoos'
    end
    local g = groupOf(kind, slot)
    return g and g.label or 'Clothing'
end

local function isAdmin(src)
    return exports.whip_core:HasPermission(src, Config.Admin.permission) == true or exports.whip_core:HasDevTools(src) == true
end

local function catRule(kind, slot)
    local saved = cats[catKeyOf(kind, slot)]
    if saved then return saved, false end
    if kind ~= 'component' and kind ~= 'prop' then return nil, false end
    local d = (Config.CategoryDefaults or {})[groupKey(kind, slot)]
    if type(d) == 'table' then
        return { blocked = d.blocked == true, jobs = d.jobs, chars = d.chars, onDuty = d.onDuty == true }, true
    end
    return nil, false
end

local function allowed(src, charId, r)
    if r.blocked or r.exclusive then return false end
    local jobs, chars = r.jobs or {}, r.chars or {}
    if #jobs == 0 and #chars == 0 then return true end
    for _, c in ipairs(chars) do
        if c == charId then return true end
    end
    for _, job in ipairs(jobs) do
        if exports.whip_core:GetPlayerRole(src, job) then
            if not r.onDuty or exports.whip_core:IsPlayerClockedOn(src, job) == true then return true end
        end
    end
    return false
end

local function restricted(r) return (#(r.jobs or {}) + #(r.chars or {})) > 0 end

function AppearanceRules.view(src)
    local player = exports.whip_core:GetPlayer(src)
    local charId = type(player) == 'table' and player.charId or nil
    local admin = isAdmin(src)
    local list = {}
    for key, r in pairs(rules) do
        local v = { key = key, texture = r.texture, brands = r.brands, allowed = allowed(src, charId, r),
                    blocked = r.blocked == true, exclusive = r.exclusive ~= nil, restricted = restricted(r) }
        if admin then
            v.jobs, v.chars, v.onDuty, v.label = r.jobs, r.chars, r.onDuty == true, r.label
            v.item = r.exclusive and r.exclusive.item or nil
            v.itemLabel = r.exclusive and r.exclusive.label or nil
            v.exTexture = r.exclusive and r.exclusive.texture or nil
        end
        list[#list + 1] = v
    end
    local categories = {}
    local function addCategory(kind, slot)
        local r, isDefault = catRule(kind, slot)
        if r then
            local v = { key = catKeyOf(kind, slot), allowed = allowed(src, charId, r), blocked = r.blocked == true,
                        restricted = restricted(r), isDefault = isDefault, saved = cats[catKeyOf(kind, slot)] ~= nil }
            if admin then v.jobs, v.chars, v.onDuty = r.jobs, r.chars, r.onDuty == true end
            categories[#categories + 1] = v
        end
    end
    for _, g in ipairs(Appearance.Groups.clothing) do addCategory(g.ui.type, g.ui.id) end
    for i = 1, #Appearance.TATTOO_ZONES do addCategory('tattoo', i) end
    for _, kind in ipairs(Appearance.CATEGORY_KINDS) do
        for i = 1, #Appearance.Groups[kind] do addCategory(kind, i) end
    end

    local tattoos = {}
    for key, r in pairs(tats) do
        local v = { key = key, price = r.price, allowed = allowed(src, charId, r), blocked = r.blocked == true,
                    restricted = restricted(r) }
        if admin then v.jobs, v.chars, v.onDuty = r.jobs, r.chars, r.onDuty == true end
        tattoos[#tattoos + 1] = v
    end
    local out = { rules = list, categories = categories, tattoos = tattoos, admin = admin }
    if admin then
        local jobs = {}
        for _, j in ipairs(exports.whip_core:GetJobs() or {}) do
            if type(j) == 'table' and type(j.key) == 'string' then jobs[#jobs + 1] = { key = j.key, name = j.name or j.key } end
        end
        table.sort(jobs, function(a, b) return tostring(a.name) < tostring(b.name) end)
        out.jobs = jobs
    end
    return out
end

local function sellsIn(r, brand)
    local brands = r and r.brands
    if Appearance.isCatalog(brand) then
        for _, b in ipairs(brands or {}) do if b == brand then return true end end
        return false
    end
    if type(brands) ~= 'table' or #brands == 0 then return true end
    local onlyCatalogs = true
    for _, b in ipairs(brands) do
        if brand and b == brand then return true end
        if not Appearance.isCatalog(b) then onlyCatalogs = false end
    end
    if brand then return false end
    return not onlyCatalogs
end

function AppearanceRules.checkLook(src, player, s, saved, final)
    local gender = final.model == Appearance.MODELS.female and 'female' or 'male'
    for _, g in ipairs(Appearance.Groups.clothing) do
        local kind, slot = g.ui.type, g.ui.id
        local store = kind == 'prop' and 'props' or 'components'
        local now = final[store] and final[store][tostring(slot)]
        local was = saved.model == final.model and saved[store] and saved[store][tostring(slot)] or nil
        local d, t = now and tonumber(now.drawable), now and (tonumber(now.texture) or 0)
        local newModel = d and d >= 0 and (not was or tonumber(was.drawable) ~= d)
        local newColor = d and d >= 0 and (newModel or tonumber(was.texture) ~= t)
        if newColor then
            local c, isDefault = catRule(kind, slot)

            if isDefault and Appearance.isCatalog(s.brand) then c = nil end
            if c and not allowed(src, player.charId, c) then
                return false, ('%s are not for sale to you.'):format(g.label)
            end
            local m = newModel and rules[keyOf(gender, kind, slot, d, ALL)] or nil
            local r = rules[keyOf(gender, kind, slot, d, t)]
            if m and not allowed(src, player.charId, m) then return false, ('%s %d is not for sale to you.'):format(g.label, d) end
            if r and not allowed(src, player.charId, r) then
                return false, ('%s %d, color %d, is not for sale to you.'):format(g.label, d, t + 1)
            end
            local brandRule = (r and r.brands) and r or (rules[keyOf(gender, kind, slot, d, ALL)])
            if not sellsIn(brandRule, s.brand) then return false, ('%s %d is not sold in this store.'):format(g.label, d) end
        end
    end
    return true
end

function AppearanceRules.checkGroups(src, player, kind, saved, final)
    if not isCategoryKind(kind) then return true end
    local changed = {}
    for _, l in ipairs(Appearance.quote(kind, saved, final).lines) do changed[l.key] = true end
    for i, g in ipairs(Appearance.Groups[kind]) do
        if changed[g.key] then
            local c = catRule(kind, i)
            if c and not allowed(src, player.charId, c) then
                return false, ('%s is not available to you here.'):format(g.label)
            end
        end
    end
    if kind == 'barber' and changed.hair then
        local gender = final.model == Appearance.MODELS.female and 'female' or 'male'
        local style = final.hair and tonumber(final.hair.style)
        local was = saved.hair and tonumber(saved.hair.style)
        local r = style and style ~= was and rules[keyOf(gender, 'component', HAIR_SLOT, style, ALL)] or nil
        if r and not allowed(src, player.charId, r) then
            return false, ('Haircut %d is not available to you.'):format(style)
        end
    end
    return true
end

function AppearanceRules.checkOutfit(src, charId, outfit)
    local gender = outfit.model == Appearance.MODELS.female and 'female' or 'male'
    for _, g in ipairs(Appearance.Groups.clothing) do
        local kind, slot = g.ui.type, g.ui.id
        local store = kind == 'prop' and outfit.props or outfit.components
        local v = store and store[tostring(slot)]
        local d, t = v and tonumber(v.drawable), v and (tonumber(v.texture) or 0)
        if d and d >= 0 then
            local m = rules[keyOf(gender, kind, slot, d, ALL)]
            local r = rules[keyOf(gender, kind, slot, d, t)]
            if (m and not allowed(src, charId, m)) or (r and not allowed(src, charId, r)) then
                return false, ('%s %d cannot be part of an outfit (blocked, exclusive or another job\'s).'):format(g.label, d)
            end
        end
    end
    return true
end

AppearanceRules.isAdmin = function(src) return isAdmin(src) end

function AppearanceRules.tattooPrice(key)
    local r = tats[key]
    return r and r.price or nil
end

function AppearanceRules.checkTattoos(src, player, saved, final)
    local had = {}
    for _, t in ipairs(type(saved.tattoos) == 'table' and saved.tattoos or {}) do
        local k = Appearance.tattooKey(t)
        if k then had[k] = true end
    end
    for _, t in ipairs(type(final.tattoos) == 'table' and final.tattoos or {}) do
        local k = Appearance.tattooKey(t)
        if k and not had[k] then
            local info = Appearance.tattooInfo(k) or {}
            local zone = Appearance.TATTOO_ZONE_INDEX[info.zone or '']
            local c = zone and catRule('tattoo', zone)
            if c and not allowed(src, player.charId, c) then
                return false, 'Tattoos on this body part are not available to you.'
            end
            local r = tats[k]
            if r and not allowed(src, player.charId, r) then
                return false, ('The tattoo "%s" is not available to you.'):format(info.name or 'selected')
            end
        end
    end
    return true
end

local function itemKeyOf(id) return 'whip_appearance_x' .. id end

local function onUse(source, _, slotData)
    local r = byItem[slotData and slotData.item or '']
    if not r or not r.exclusive then return false, 'This piece no longer exists.' end
    local look = exports.whip_core:GetPlayerMetadata(source, 'appearance')
    if type(look) ~= 'table' or not look.model then return false, 'Your character has no saved look yet.' end
    local want = r.gender == 'female' and Appearance.MODELS.female or Appearance.MODELS.male
    if look.model ~= want then
        return false, ('This piece is for %s characters.'):format(r.gender == 'female' and 'female' or 'male')
    end
    if AppearanceServer.isOpen(source) then return false, 'Close the store first.' end
    TriggerClientEvent('whip_appearance:client:wearPiece', source, {
        kind = r.kind, slot = r.slot, drawable = r.drawable, texture = r.exclusive.texture or 0, key = groupKey(r.kind, r.slot),
    })
    return false
end

local function onTakeOff(source, _, slotData)
    local r = byItem[slotData and slotData.item or '']
    if not r then return false, 'This piece no longer exists.' end
    if AppearanceServer.isOpen(source) then return false, 'Close the store first.' end
    TriggerClientEvent('whip_appearance:client:removePiece', source, { kind = r.kind, slot = r.slot, drawable = r.drawable,
        key = groupKey(r.kind, r.slot) })
end

local function pictureOf(p)
    if type(p) ~= 'table' or type(p.res) ~= 'string' or type(p.path) ~= 'string' then return nil end
    if not p.res:match('^whip_media_clothing_[%w_]+$') then return nil end
    if not p.path:match('^img/clothing/[%w_]+/[%w_]+/[%w_]+%.webp$') then return nil end
    if LoadResourceFile(p.res, p.path) == nil then return nil end
    return ('@%s/%s'):format(p.res, p.path)
end

local function registerItem(r)
    local key = r.exclusive.item
    local ok, why = Whip.core:RegisterItem(key, {
        name = r.exclusive.label, desc = ('Exclusive piece: %s'):format(slotLabel(r.kind, r.slot)),
        weight = tonumber(Config.Admin.itemWeight) or 0.3, type = 'clothing', stack = false, usable = true,

        image = r.exclusive.image or ITEM_PICTURE,
        contextOptions = { { action = 'whip_appearance:takeOff', label = 'Take the piece off', order = 1 } },
    })
    if not ok then print(('[whip_appearance] item %s was not registered: %s'):format(key, tostring(why))) return end
    Whip.core:RegisterUseHandler(key, onUse)
    byItem[key] = r
end

local COLS = '`id`, `gender`, `kind`, `slot`, `drawable`, `texture`, `data`'

local function decodeData(raw)
    local ok, data = pcall(json.decode, raw or '{}')
    return ok and type(data) == 'table' and data or {}
end

local function decode(row)
    local data = decodeData(row.data)
    local r = {
        id = row.id, gender = row.gender, kind = row.kind, slot = tonumber(row.slot), drawable = tonumber(row.drawable),
        texture = tonumber(row.texture) or ALL,
        label = data.label, brands = data.brands, blocked = data.blocked == true, jobs = data.jobs, chars = data.chars,
        onDuty = data.onDuty == true, exclusive = data.exclusive,
    }
    if r.exclusive then r.exclusive.item = itemKeyOf(r.id) end
    return r
end

local function load()
    if not AppearanceDB.wait() then return print('^1[whip_appearance] rules not loaded: the database is not ready^0') end
    rules, cats, byItem = {}, {}, {}
    local rows = MySQL.query.await(('SELECT %s FROM `%s`'):format(COLS, TABLE)) or {}
    for _, row in ipairs(rows) do
        local r = decode(row)
        rules[keyOf(r.gender, r.kind, r.slot, r.drawable, r.texture)] = r
        if r.exclusive then registerItem(r) end
    end
    local crow = MySQL.query.await(('SELECT `kind`, `slot`, `data` FROM `%s`'):format(CATS)) or {}
    for _, row in ipairs(crow) do
        local data = decodeData(row.data)
        cats[catKeyOf(row.kind, tonumber(row.slot))] = { blocked = data.blocked == true, jobs = data.jobs, chars = data.chars,
            onDuty = data.onDuty == true }
    end
    tats = {}
    local trow = MySQL.query.await(('SELECT `tattoo`, `data` FROM `%s`'):format(TATS)) or {}
    for _, row in ipairs(trow) do
        local data = decodeData(row.data)
        tats[row.tattoo] = { price = tonumber(data.price), blocked = data.blocked == true, jobs = data.jobs, chars = data.chars,
            onDuty = data.onDuty == true }
    end
    print(('[whip_appearance] loaded %d piece rule(s), %d category rule(s) and %d tattoo rule(s)'):format(#rows, #crow, #trow))
end

local function list(v, max, check)
    local out = {}
    if type(v) ~= 'table' then return out end
    for _, x in ipairs(v) do
        if #out >= max then break end
        local y = check(x)
        if y ~= nil then out[#out + 1] = y end
    end
    return out
end

local function text(v, max)
    if type(v) ~= 'string' then return nil end
    v = v:gsub('[%c<>]', ''):match('^%s*(.-)%s*$')
    if v == '' then return nil end
    return v:sub(1, max)
end

local function knownJobs()
    local out = {}
    for _, j in ipairs(exports.whip_core:GetJobs() or {}) do if type(j) == 'table' and j.key then out[j.key] = true end end
    return out
end

local function access(rule, jobsKnown)
    local jobs = list(rule.jobs, 20, function(j) return type(j) == 'string' and jobsKnown[j] and j or nil end)
    local chars = list(rule.chars, 50, function(c) local n = math.tointeger(tonumber(c)); return n and n > 0 and n or nil end)
    return {
        blocked = rule.blocked == true or nil,
        jobs = #jobs > 0 and jobs or nil,
        chars = #chars > 0 and chars or nil,
        onDuty = rule.onDuty == true or nil,
    }
end

local function slotOf(t, forPiece)
    local kind = (t.kind == 'prop' or t.kind == 'component' or t.kind == 'tattoo' or isCategoryKind(t.kind)) and t.kind or nil
    local slot = math.tointeger(tonumber(t.slot))
    if not kind or not slot then return nil end
    if isCategoryKind(kind) then
        if forPiece or slot < 1 or slot > #Appearance.Groups[kind] then return nil end
        return kind, slot
    end
    if kind == 'component' and slot == HAIR_SLOT then
        if not forPiece then return nil end
        return kind, slot
    end
    if kind == 'tattoo' then
        if slot < 1 or slot > #Appearance.TATTOO_ZONES then return nil end
        return kind, slot
    end
    if kind == 'prop' and not PROP_SLOTS[slot] then return nil end
    if kind == 'component' and (slot < 1 or slot > 11 or slot == 2) then return nil end
    return kind, slot
end

local function answer(source, message)
    local view = AppearanceRules.view(source)
    return { rules = view.rules, categories = view.categories, tattoos = view.tattoos, message = message }
end

local function onSave(source, _, piece, rule)
    if not isAdmin(source) then return false, 'Only a store admin can do that.' end
    if type(piece) ~= 'table' or type(rule) ~= 'table' then return false, 'Invalid data.' end
    local gender = piece.gender == 'female' and 'female' or (piece.gender == 'male' and 'male' or nil)
    local kind, slot = slotOf(piece, true)
    if kind == 'tattoo' then kind = nil end
    local drawable = math.tointeger(tonumber(piece.drawable))
    local texture = math.tointeger(tonumber(piece.texture)) or ALL
    local hair = kind == 'component' and slot == HAIR_SLOT
    if hair then
        texture = ALL
        rule.brands, rule.exclusive = nil, nil
    end
    if not gender or not kind or not drawable or drawable < 0 or drawable > 4095 or texture < ALL or texture > 127 then
        return false, 'Invalid piece.'
    end

    local data = access(rule, knownJobs())
    data.label = text(piece.label, 60)
    data.brands = rule.brands ~= nil and list(rule.brands, 12, function(b)
        return (BRANDS[b] or (type(b) == 'string' and b:match('^c:[%w_]+$') and #b <= 32)) and b or nil
    end) or nil
    if type(rule.exclusive) == 'table' then
        local label = text(rule.exclusive.label, 40)
        if not label then return false, 'Give the exclusive item a name.' end
        local tex = texture >= 0 and texture or math.tointeger(tonumber(rule.exclusive.texture)) or 0
        data.exclusive = { label = label, texture = math.max(0, math.min(127, tex)), image = pictureOf(rule.exclusive.picture) }
    end
    if data.brands and #data.brands == 0 then return false, 'Pick at least one brand, or go back to automatic.' end

    local key = keyOf(gender, kind, slot, drawable, texture)
    local empty = not (data.brands or data.blocked or data.jobs or data.chars or data.exclusive)
    local where = '`gender` = ? AND `kind` = ? AND `slot` = ? AND `drawable` = ? AND `texture` = ?'
    local args = { gender, kind, slot, drawable, texture }
    if empty then
        MySQL.query.await(('DELETE FROM `%s` WHERE %s'):format(TABLE, where), args)
        rules[key] = nil
        return answer(source, 'Rule removed: the piece is back to normal.')
    end
    MySQL.query.await(('INSERT INTO `%s` (`gender`, `kind`, `slot`, `drawable`, `texture`, `data`) VALUES (?, ?, ?, ?, ?, ?) '
        .. 'ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)'):format(TABLE),
        { gender, kind, slot, drawable, texture, json.encode(data) })
    local row = MySQL.single.await(('SELECT %s FROM `%s` WHERE %s'):format(COLS, TABLE, where), args)
    if not row then return false, 'Could not save.' end
    local r = decode(row)
    rules[key] = r
    if r.exclusive then
        registerItem(r)
        return answer(source, ('Saved. Exclusive item: %s (%s).'):format(r.exclusive.label, r.exclusive.item))
    end
    return answer(source, 'Rule saved.')
end

local function onSaveCategory(source, _, cat, rule)
    if not isAdmin(source) then return false, 'Only a store admin can do that.' end
    if type(cat) ~= 'table' or type(rule) ~= 'table' then return false, 'Invalid data.' end
    local kind, slot = slotOf(cat)
    if not kind then return false, 'Invalid category.' end
    local key = catKeyOf(kind, slot)
    local label = slotLabel(kind, slot)
    if rule.reset == true then
        MySQL.query.await(('DELETE FROM `%s` WHERE `kind` = ? AND `slot` = ?'):format(CATS), { kind, slot })
        cats[key] = nil
        return answer(source, ('%s: back to the default.'):format(label))
    end
    local data = access(rule, knownJobs())
    MySQL.query.await(('INSERT INTO `%s` (`kind`, `slot`, `data`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)')
        :format(CATS), { kind, slot, json.encode(data) })
    cats[key] = { blocked = data.blocked == true, jobs = data.jobs, chars = data.chars, onDuty = data.onDuty == true }
    return answer(source, ('%s: category rule saved.'):format(label))
end

local MAX_BATCH = 300

local function onSaveTattoos(source, _, keys, rule)
    if not isAdmin(source) then return false, 'Only a store admin can do that.' end
    if type(keys) ~= 'table' or type(rule) ~= 'table' then return false, 'Invalid data.' end
    local list = {}
    for _, k in ipairs(keys) do
        if #list >= MAX_BATCH then break end
        if type(k) == 'string' and Appearance.tattooInfo(k:lower()) then list[#list + 1] = k:lower() end
    end
    if #list == 0 then
        local first = type(keys) == 'table' and keys[1] or nil
        print(('[whip_appearance] admin tattoos: none recognized. keys=%s (%d), first=%s (%s), TattooList=%s, index=%d')
            :format(type(keys), type(keys) == 'table' and #keys or -1, tostring(first), type(first), type(TattooList),
                Appearance.tattooCount()))
        return false, 'Pick at least one tattoo.'
    end
    local data = access(rule, knownJobs())
    local price = rule.price ~= nil and math.tointeger(tonumber(rule.price)) or nil
    if rule.price ~= nil and (not price or price < 0 or price > 10000000) then return false, 'Invalid price.' end
    data.price = price
    local empty = rule.reset == true or not (data.price or data.blocked or data.jobs or data.chars)
    for _, k in ipairs(list) do
        if empty then
            MySQL.query.await(('DELETE FROM `%s` WHERE `tattoo` = ?'):format(TATS), { k })
            tats[k] = nil
        else
            MySQL.query.await(('INSERT INTO `%s` (`tattoo`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)')
                :format(TATS), { k, json.encode(data) })
            tats[k] = { price = data.price, blocked = data.blocked == true, jobs = data.jobs, chars = data.chars,
                        onDuty = data.onDuty == true }
        end
    end
    local n = #list
    print(('[whip_appearance] admin tattoos (%d): %s on %d tattoo(s), price %s'):format(source, empty and 'rule removed' or 'rule saved',
        n, tostring(data.price)))
    return answer(source, empty and ('Rule removed from %d tattoo(s).'):format(n) or ('Rule saved on %d tattoo(s).'):format(n))
end

local function onGive(source, _, item)
    if not isAdmin(source) then return false, 'Only a store admin can do that.' end
    if not byItem[item] then return false, 'That item does not exist.' end
    local where, why = exports.whip_core:AddItem(source, item, 1, nil, 'whip_appearance: admin')
    if not where then return false, why end
    return true
end

Whip.register(function()
    Whip.core:RegisterPermission(Config.Admin.permission, {
        label = 'Appearance: Admin Mode',
        description = 'Pick brands, restrict, block and create exclusive items for clothing pieces and categories in the store.',
    })
    Whip.core:RegisterContextAction('whip_appearance:takeOff', onTakeOff)

    exports.whip_core:SecureCallback('whip_appearance:admin:save', {
        rateLimit = 1000, burst = 3,
        params = { { 'piece', 'any' }, { 'rule', 'any' } },
    }, onSave)
    exports.whip_core:SecureCallback('whip_appearance:admin:category', {
        rateLimit = 1000, burst = 3,
        params = { { 'category', 'any' }, { 'rule', 'any' } },
    }, onSaveCategory)
    exports.whip_core:SecureCallback('whip_appearance:admin:tattoos', {
        rateLimit = 1000, burst = 3,
        params = { { 'keys', 'any' }, { 'rule', 'any' } },
    }, onSaveTattoos)
    exports.whip_core:SecureCallback('whip_appearance:admin:give', {
        rateLimit = 1000, burst = 3,
        params = { { 'item', 'key', 50 } },
    }, onGive)

    load()
end)
