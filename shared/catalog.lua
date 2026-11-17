Appearance = {}

Appearance.KINDS = { 'clothing', 'barber', 'surgery', 'tattoo' }
Appearance.KIND_SET = { clothing = true, barber = true, surgery = true, tattoo = true }

Appearance.KindLabel = {
    clothing = 'Clothing Store',
    barber   = 'Barber Shop',
    surgery  = 'Plastic Surgery',
    tattoo   = 'Tattoo Studio',
}

Appearance.TATTOO_ZONES = { 'head', 'torso', 'larm', 'rarm', 'lleg', 'rleg' }
Appearance.TATTOO_ZONE_INDEX = { head = 1, torso = 2, larm = 3, rarm = 4, lleg = 5, rleg = 6 }
Appearance.TATTOO_MAX = 40

Appearance.MODELS = { male = 'mp_m_freemode_01', female = 'mp_f_freemode_01' }

Appearance.OVERLAY_COLOR = { beard = 1, eyebrows = 1, chestHair = 1, makeup = 2, blush = 2, lipstick = 2 }
Appearance.OVERLAY_ID = {
    blemishes = 0, beard = 1, eyebrows = 2, ageing = 3, makeup = 4, blush = 5,
    complexion = 6, sunDamage = 7, lipstick = 8, moles = 9, chestHair = 10,
}

Appearance.FEATURES = {
    'Nose width', 'Nose tip height', 'Nose tip length', 'Nose bone height',
    'Nose tip lowering', 'Nose bone twist', 'Brow height', 'Brow depth',
    'Cheekbone height', 'Cheekbone width', 'Cheek width', 'Eye opening',
    'Lip thickness', 'Jaw width', 'Jaw length', 'Chin height',
    'Chin length', 'Chin width', 'Chin dimple', 'Neck thickness',
}

local function comp(id, key, label, cam)
    return { key = key, label = label, cam = cam, ui = { type = 'component', id = id }, paths = { { 'components', tostring(id) } } }
end
local function prop(id, key, label, cam)
    return { key = key, label = label, cam = cam, ui = { type = 'prop', id = id }, paths = { { 'props', tostring(id) } } }
end
local function overlay(name, label)
    return { key = name, label = label, cam = 'head',
             ui = { type = 'overlay', name = name, id = Appearance.OVERLAY_ID[name], colorType = Appearance.OVERLAY_COLOR[name] },
             paths = { { 'overlays', name } } }
end

Appearance.Groups = {
    clothing = {
        comp(11, 'c11', 'Jackets and Shirts', 'torso'),
        comp(8,  'c8',  'Undershirts', 'torso'),
        comp(3,  'c3',  'Arms and Gloves', 'torso'),
        comp(4,  'c4',  'Pants', 'legs'),
        comp(6,  'c6',  'Shoes', 'feet'),
        comp(1,  'c1',  'Masks', 'head'),
        comp(7,  'c7',  'Accessories', 'torso'),
        comp(5,  'c5',  'Bags and Backpacks', 'body'),
        comp(9,  'c9',  'Vests', 'torso'),
        comp(10, 'c10', 'Decals', 'torso'),
        prop(0,  'p0',  'Hats and Caps', 'head'),
        prop(1,  'p1',  'Glasses', 'head'),
        prop(2,  'p2',  'Earrings', 'head'),
        prop(6,  'p6',  'Watches', 'torso'),
        prop(7,  'p7',  'Bracelets', 'torso'),
    },
    barber = {
        { key = 'hair', label = 'Haircut', cam = 'head', ui = { type = 'hair' },
          paths = { { 'hair', 'style' }, { 'hair', 'texture' } } },
        { key = 'hairColor', label = 'Hair Color', cam = 'head', ui = { type = 'hairColor' },
          paths = { { 'hair', 'color' }, { 'hair', 'highlight' } } },
        { key = 'fade', label = 'Fade', cam = 'head', ui = { type = 'fade' }, paths = { { 'hairFade' } } },
        overlay('beard', 'Beard'),
        overlay('eyebrows', 'Eyebrows'),
        overlay('chestHair', 'Chest Hair'),
        overlay('makeup', 'Makeup'),
        overlay('blush', 'Blush'),
        overlay('lipstick', 'Lipstick'),
    },
    surgery = {
        { key = 'sex', label = 'Sex', cam = 'body', ui = { type = 'sex' }, paths = { { 'model' } } },
        { key = 'heritage', label = 'Heritage', cam = 'head', ui = { type = 'heritage' }, paths = { { 'headBlend' } } },
        { key = 'features', label = 'Face Features', cam = 'head', ui = { type = 'features' }, paths = { { 'faceFeatures' } } },
        { key = 'eyes', label = 'Eye Color', cam = 'head', ui = { type = 'eyes' }, paths = { { 'eyeColor' } } },
        { key = 'skin', label = 'Skin Details', cam = 'head',
          ui = { type = 'overlays', list = {
              { name = 'blemishes', id = 0, label = 'Blemishes' },
              { name = 'ageing', id = 3, label = 'Ageing' },
              { name = 'complexion', id = 6, label = 'Complexion' },
              { name = 'sunDamage', id = 7, label = 'Sun damage' },
              { name = 'moles', id = 9, label = 'Freckles and moles' },
          } },
          paths = { { 'overlays', 'blemishes' }, { 'overlays', 'ageing' }, { 'overlays', 'complexion' },
                    { 'overlays', 'sunDamage' }, { 'overlays', 'moles' } } },
    },

    tattoo = {
        { key = 'head',  label = 'Head',        cam = 'head',  ui = { type = 'tattoo', zone = 'head',  index = 1 }, paths = {} },
        { key = 'torso', label = 'Torso',        cam = 'torso', ui = { type = 'tattoo', zone = 'torso', index = 2 }, paths = {} },
        { key = 'larm',  label = 'Left Arm', cam = 'torso', ui = { type = 'tattoo', zone = 'larm',  index = 3 }, paths = {} },
        { key = 'rarm',  label = 'Right Arm',  cam = 'torso', ui = { type = 'tattoo', zone = 'rarm',  index = 4 }, paths = {} },
        { key = 'lleg',  label = 'Left Leg', cam = 'legs',  ui = { type = 'tattoo', zone = 'lleg',  index = 5 }, paths = {} },
        { key = 'rleg',  label = 'Right Leg',  cam = 'legs',  ui = { type = 'tattoo', zone = 'rleg',  index = 6 }, paths = {} },
    },

    wardrobe = {
        { key = 'outfits', label = 'Outfits', cam = 'body', ui = { type = 'outfits' }, paths = {} },
    },
}

local tattooIndex = nil
local tattooCount = 0

local function ensureTattooList()
    if type(TattooList) == 'table' then return true end
    local code = LoadResourceFile('whip_core', 'shared/tattoo_list.lua')
    if type(code) ~= 'string' then return false end
    local fn = load(code, '@whip_core/shared/tattoo_list.lua', 't')
    if fn then pcall(fn) end
    return type(TattooList) == 'table'
end

local function buildTattooIndex()
    tattooIndex, tattooCount = {}, 0
    if not ensureTattooList() then return end
    for _, t in ipairs(TattooList.list or {}) do
        local coll = TattooList.collections[t[1]]
        if coll then
            local key = (coll.name .. '/' .. t[2]):lower()
            tattooIndex[key] = { collection = coll.name, overlay = t[2], zone = t[3], body = t[4], facing = t[5] or '',
                                 name = (t[6] ~= nil and t[6] ~= '') and t[6] or nil }
            tattooCount = tattooCount + 1
        end
    end
end

function Appearance.tattooKey(t)
    if type(t) ~= 'table' or type(t.collection) ~= 'string' or type(t.overlay) ~= 'string' then return nil end
    return (t.collection .. '/' .. t.overlay):lower()
end

function Appearance.tattooInfo(key)

    if not tattooIndex or tattooCount == 0 then buildTattooIndex() end
    return key and tattooIndex[key] or nil
end

function Appearance.tattooCount()
    if not tattooIndex or tattooCount == 0 then buildTattooIndex() end
    return tattooCount
end

local function deepCopy(v)
    if type(v) ~= 'table' then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = deepCopy(x) end
    return out
end
Appearance.copy = deepCopy

local EPS = 0.001

local function same(a, b)
    if type(a) == 'number' and type(b) == 'number' then return math.abs(a - b) <= EPS end
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for k, v in pairs(a) do
        if not same(v, b[k]) then return false end
    end
    for k, v in pairs(b) do
        if a[k] == nil and v ~= nil then return false end
    end
    return true
end
Appearance.same = same

local function getPath(t, path)
    for i = 1, #path do
        if type(t) ~= 'table' then return nil end
        t = t[path[i]]
    end
    return t
end

local function setPath(t, path, value)
    for i = 1, #path - 1 do
        local k = path[i]
        if type(t[k]) ~= 'table' then t[k] = {} end
        t = t[k]
    end
    t[path[#path]] = deepCopy(value)
end

local function groupChanged(group, saved, new)
    for _, path in ipairs(group.paths) do
        local a = getPath(saved, path)
        if a ~= nil and not same(a, getPath(new, path)) then return true end

        if a == nil and group.key == 'fade' and getPath(new, path) ~= nil then return true end
    end
    return false
end

local function priceOf(kind, key)
    local p = Config.Prices and Config.Prices[kind] and Config.Prices[kind][key]
    p = math.floor(tonumber(p) or 0)
    return p > 0 and p or 0
end
Appearance.priceOf = priceOf

function Appearance.sexChanged(saved, new)
    return type(saved) == 'table' and type(new) == 'table' and saved.model ~= nil and new.model ~= saved.model
end

local function tattooKeys(look)
    local list, set = {}, {}
    for _, t in ipairs(type(look) == 'table' and type(look.tattoos) == 'table' and look.tattoos or {}) do
        local k = Appearance.tattooKey(t)
        if k and not set[k] then list[#list + 1] = k; set[k] = true end
    end
    return list, set
end

local function tattooQuote(saved, new, opts)
    local lines, total = {}, 0
    local savedList, savedSet = tattooKeys(saved)
    local newList, newSet = tattooKeys(new)
    for _, k in ipairs(newList) do
        if not savedSet[k] then
            local info = Appearance.tattooInfo(k) or {}
            local own = opts and opts.tattooPrice and opts.tattooPrice(k)
            local price = tonumber(own) and math.max(0, math.floor(own)) or priceOf('tattoo', info.zone or 'torso')
            lines[#lines + 1] = { key = 'tat:' .. k, group = info.zone, label = info.name or 'Tattoo', price = price }
            total = total + price
        end
    end
    for _, k in ipairs(savedList) do
        if not newSet[k] then
            local info = Appearance.tattooInfo(k) or {}
            local price = priceOf('tattoo', 'remove')
            lines[#lines + 1] = { key = 'rem:' .. k, group = info.zone, label = 'Removal: ' .. (info.name or 'tattoo'),
                                  price = price }
            total = total + price
        end
    end
    return { lines = lines, total = total }
end

function Appearance.quote(kind, saved, new, opts)
    if kind == 'tattoo' then return tattooQuote(saved, new, opts) end
    local lines, total = {}, 0
    local groups = Appearance.Groups[kind] or {}
    for _, g in ipairs(groups) do
        if groupChanged(g, saved, new) then
            local price = priceOf(kind, g.key)
            lines[#lines + 1] = { key = g.key, label = g.label, price = price }
            total = total + price
        end
    end
    return { lines = lines, total = total }
end

function Appearance.merge(kind, saved, new)
    if kind == 'tattoo' then
        local final = deepCopy(saved)
        final.tattoos = deepCopy(type(new.tattoos) == 'table' and new.tattoos or {})
        return final
    end
    local final
    if kind == 'surgery' and Appearance.sexChanged(saved, new) then
        final = deepCopy(new)
    else
        final = deepCopy(saved)
        for _, g in ipairs(Appearance.Groups[kind] or {}) do
            for _, path in ipairs(g.paths) do setPath(final, path, getPath(new, path)) end
        end
        final.model = saved.model
    end
    final.tattoos = deepCopy(saved.tattoos)
    return final
end

function Appearance.catalogKey(text)
    if type(text) ~= 'string' then return nil end
    local slug = text:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if slug == '' then return nil end
    return 'c:' .. slug:sub(1, 30)
end

function Appearance.isCatalog(b) return type(b) == 'string' and b:sub(1, 2) == 'c:' end

function Appearance.catalogs()
    local out, seen = {}, {}
    for _, shop in ipairs(Config.Shops and Config.Shops.clothing or {}) do
        local k = type(shop) == 'table' and Appearance.catalogKey(shop.catalog) or nil
        if k and not seen[k] then
            seen[k] = true
            out[#out + 1] = { key = k, label = shop.catalog }
        end
    end
    return out
end

function Appearance.jobList(text)
    if type(text) ~= 'string' then return nil end
    local out = {}
    for j in text:gmatch('[^,;%s]+') do out[#out + 1] = j:lower() end
    return #out > 0 and out or nil
end

function Appearance.brandOf(shop)
    if type(shop) ~= 'table' then return nil end
    local own = Appearance.catalogKey(shop.catalog)
    if own then return own end
    if shop.brand == 'all' then return nil end
    local names = Config.Brands and Config.Brands.names or {}
    if type(shop.brand) == 'string' and names[shop.brand] then return shop.brand end
    local n = tostring(shop.name or ''):lower()
    for key in pairs(names) do
        if n:find(key, 1, true) then return key end
    end
    return nil
end

function Appearance.outfitOf(look)
    if type(look) ~= 'table' then return nil end
    local out = { model = look.model, components = {}, props = {} }
    for _, g in ipairs(Appearance.Groups.clothing) do
        local path = g.paths[1]
        local v = getPath(look, path)
        if type(v) == 'table' then
            setPath(out, path, { drawable = math.floor(tonumber(v.drawable) or 0), texture = math.floor(tonumber(v.texture) or 0) })
        end
    end
    return out
end

function Appearance.wear(look, outfit)
    local out = deepCopy(look)
    for _, g in ipairs(Appearance.Groups.clothing) do
        local path = g.paths[1]
        local v = getPath(outfit, path)
        if v ~= nil then setPath(out, path, v) end
    end
    return out
end
