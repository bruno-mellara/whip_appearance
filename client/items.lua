local function notify(text, kind) Whip.core:Notify(text, kind or 'info') end

local function change(p, drawable, texture)
    local saved = Appearance.Client.savedLook()
    if not saved then return notify('You are not wearing your character\'s look right now.', 'error') end
    local ped = PlayerPedId()
    local look = Preview.complete(ped, saved)
    local store = p.kind == 'prop' and look.props or look.components
    store[tostring(p.slot)] = { drawable = drawable, texture = texture }
    Preview.apply(ped, look)
    TriggerServerEvent('whip_core:server:saveAppearance', look)
    Anims.now(p.key)
end

RegisterNetEvent('whip_appearance:client:wearPiece', function(p)
    if type(p) ~= 'table' or Appearance.Client.isOpen() then return end
    CreateThread(function()
        change(p, math.floor(tonumber(p.drawable) or 0), math.floor(tonumber(p.texture) or 0))
    end)
end)

RegisterNetEvent('whip_appearance:client:removePiece', function(p)
    if type(p) ~= 'table' or Appearance.Client.isOpen() then return end
    CreateThread(function()
        local ped = PlayerPedId()
        local slot = math.floor(tonumber(p.slot) or -1)
        local wearing = p.kind == 'prop' and GetPedPropIndex(ped, slot) or GetPedDrawableVariation(ped, slot)
        if wearing ~= tonumber(p.drawable) then return notify('You are not wearing this piece.', 'info') end
        if p.kind == 'prop' then
            change(p, -1, 0)
        else
            change(p, Preview.nothingFor(ped, slot), 0)
        end
    end)
end)
