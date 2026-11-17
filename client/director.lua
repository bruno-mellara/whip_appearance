local OPTIONS = {
    { id = 'whip_appearance.dmClothing', what = 'clothing', label = 'Open Clothing Store (free)', tint = 'violet' },
    { id = 'whip_appearance.dmBarber', what = 'barber', label = 'Open Barber Shop (free)', tint = 'violet' },
    { id = 'whip_appearance.dmSurgery', what = 'surgery', label = 'Open Plastic Surgery (free)', tint = 'violet' },
    { id = 'whip_appearance.dmTattoo', what = 'tattoo', label = 'Open Tattoo Studio (free)', tint = 'violet' },
    { id = 'whip_appearance.dmWardrobe', what = 'wardrobe', label = 'Open their company Wardrobe (free)', tint = 'violet' },
    { id = 'whip_appearance.dmRestore', what = 'restore', label = 'Restore saved look', tint = 'slate' },
}

for _, o in ipairs(OPTIONS) do
    Whip.objectViewerOption(o.id, {
        label = o.label,
        group = 'Appearance',
        tint = o.tint,
        kinds = { 'player' },
        whip = true,
        hint = 'The player chooses on their own screen; nothing is charged.',
        select = function(target)
            local id = tonumber(target and target.serverId)
            if not id then return end
            TriggerServerEvent('whip_appearance:dungeon', id, o.what)
        end,
    })
end

Whip.directorButton('whip_appearance.pickOutfit', {
    label = 'Pick in the store',
    kinds = { 'card' },
    where = 'page',
    takesOver = true,
    icon = 'store',
    hint = 'The clothing store opens on your character: build the outfit and click Save outfit. Nothing is paid or saved.',
    press = function(thing)
        local ok, why = Appearance.Client.pickOutfit(function(outfit)
            if outfit then
                local body = outfit.model == Appearance.MODELS.female and 'female' or 'male'
                local form = Whip.core:Input('Name this outfit', {
                    { label = 'Name', type = 'text', placeholder = 'e.g. Security guard', default = '' },
                })
                local name = type(form) == 'table' and type(form[1]) == 'string' and form[1]:gsub('[%c<>]', ''):sub(1, 30) or ''
                name = name:match('^%s*(.-)%s*$')
                if name == '' then name = 'Outfit' end
                outfit.name = name
                outfit.text = ('%s (%s body)'):format(name, body)
                local saved, err = thing:save(outfit)
                if saved then
                    Whip.core:Notify(('Outfit stored in the card (%s).'):format(
                        outfit.model == Appearance.MODELS.female and 'female body' or 'male body'), 'success')
                else
                    Whip.core:Notify('Could not store the outfit: ' .. tostring(err), 'error')
                end
            end
            thing:back()
        end)
        if not ok then
            Whip.core:Notify(why or 'The store did not open.', 'error')
            thing:back()
        end
    end,
})
