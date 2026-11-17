local WORLD = { x = { -5000, 5000 }, y = { -7000, 8500 }, z = { -200, 2000 } }

local function shops(kind, label, help)
    local blip = Config.Blips[kind] or {}
    local fields = {
        { key = 'coords', type = 'vec3', limits = WORLD, here = true, label = 'Where' },
        { key = 'name', type = 'string', maxLen = 50, label = 'Name' },
        { key = 'hideBlip', type = 'bool', nullable = true, emptyLabel = 'no', label = 'No map icon',
          help = 'The store works the same but does not show on the map (e.g. a company store inside its building).' },
    }
    if kind == 'clothing' then
        local options = { { value = 'all', label = 'All (sells everything)' } }
        for _, key in ipairs({ 'binco', 'suburban', 'ponsonbys', 'discount' }) do
            options[#options + 1] = { value = key, label = Config.Brands.names[key] }
        end
        fields[#fields + 1] = { key = 'brand', type = 'enum', options = options, nullable = true, label = 'Brand',
            help = 'What the store sells (Config.Brands). Empty: by the store\'s name ("Binco - ..." is Binco).' }

        fields[#fields + 1] = { key = 'catalog', type = 'string', maxLen = 30, nullable = true, label = 'Own catalog',
            help = 'E.g. LSPD. The store only sells the pieces marked with this catalog in Admin Mode (Brand is ignored).' }
        fields[#fields + 1] = { key = 'jobs', type = 'string', maxLen = 200, nullable = true, label = 'Jobs only',
            help = 'Job keys, comma separated (e.g. police, sheriff). Empty: everyone.' }
        fields[#fields + 1] = { key = 'onDuty', type = 'bool', nullable = true, emptyLabel = 'no', label = 'On duty only' }
        fields[#fields + 1] = { key = 'free', type = 'bool', nullable = true, emptyLabel = 'no', label = 'Free', help = 'Charges nothing in this store.' }
    end
    return {
        key = 'Shops.' .. kind, type = 'records', maxItems = 60, widget = 'mapPoints',
        marker = { sprite = blip.sprite or 1, colour = blip.color or 0, name = blip.label or label },
        label = label, help = help,
        fields = fields,
    }
end

local function prices(kind)
    local list = {}
    for _, g in ipairs(Appearance.Groups[kind]) do
        list[#list + 1] = { key = ('Prices.%s.%s'):format(kind, g.key), type = 'int', min = 0, max = 10000000, unit = '$',
                            label = g.label }
    end
    return list
end

local general = {
    { key = 'UseRange', type = 'number', min = 1.0, max = 10.0, step = 0.5, unit = 'm', label = 'Distance to use a store' },
    { key = 'AllowBank', type = 'bool', label = 'Accept bank payment', help = 'Off: cash only.' },
}
for _, kind in ipairs(Appearance.KINDS) do
    general[#general + 1] = { key = ('Blips.%s.sprite'):format(kind), type = 'int', min = 0, max = 900,
                              label = ('Map icon: %s'):format(Appearance.KindLabel[kind]), help = '0: no icon' }
    general[#general + 1] = { key = ('Blips.%s.color'):format(kind), type = 'int', min = 0, max = 85,
                              label = ('Icon color: %s'):format(Appearance.KindLabel[kind]) }
end

Whip.configPage({
    label = 'Appearance',
    groups = {
        { label = 'Stores', settings = {
            shops('clothing', 'Clothing Stores', 'Drag an icon to move it, click to rename or remove it, or add one where you stand.'),
            shops('barber', 'Barber Shops', 'Drag an icon to move it, click to rename or remove it, or add one where you stand.'),
            shops('surgery', 'Plastic Surgery Clinics', 'Surgery changes face, eyes, skin and sex. Never tattoos.'),
            shops('tattoo', 'Tattoo Studios', 'Get and remove tattoos. Drag an icon to move it, or add one where you stand.'),
        } },
        { label = 'Outfit Wardrobes', settings = {
            { key = 'Wardrobes', type = 'records', maxItems = 80, widget = 'mapPoints',
              marker = { sprite = 366, colour = 0, name = 'Wardrobe' },
              label = 'Wardrobes', help = 'One point per company. Anyone with a rank at the job puts on the company\'s outfits with 1 click.',
              fields = {
                  { key = 'coords', type = 'vec3', limits = WORLD, here = true, label = 'Where' },
                  { key = 'name', type = 'string', maxLen = 50, label = 'Name' },
                  { key = 'job', type = 'string', maxLen = 60, label = 'Job', help = 'The job\'s key (e.g. police).' },
                  { key = 'onDuty', type = 'bool', nullable = true, emptyLabel = 'no', label = 'On duty only' },
              } },
            { key = 'Wardrobe.maxOutfits', type = 'int', min = 1, max = 200, label = 'Outfits per company' },
        } },
        { label = 'Prices: Clothing', settings = prices('clothing') },
        { label = 'Prices: Barber', settings = prices('barber') },
        { label = 'Prices: Surgery', settings = prices('surgery') },
        { label = 'Prices: Tattoo', settings = (function()
            local list = prices('tattoo')
            for _, row in ipairs(list) do row.help = 'Each new tattoo on this body part (Admin Mode can give it another price).' end
            list[#list + 1] = { key = 'Prices.tattoo.remove', type = 'int', min = 0, max = 10000000, unit = '$',
                                label = 'Removal (per tattoo)' }
            return list
        end)() },
        { label = 'General', settings = general },
    },
})
