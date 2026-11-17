local KIND_OPTIONS = {
    { value = 'clothing', label = 'Clothing Store' },
    { value = 'barber', label = 'Barber Shop' },
    { value = 'surgery', label = 'Plastic Surgery' },
    { value = 'tattoo', label = 'Tattoo Studio' },
}

local TEST_LOOK_MS = 3000

local opens = {}
local goals = {}
local worn = {}

local function playersOf(card, list)
    local out = {}
    for _, s in ipairs(type(list) == 'table' and list or {}) do
        local src = tonumber(s)
        if src and GetPlayerPed(src) ~= 0 then out[#out + 1] = src end
    end
    return out
end

local function inRun(goal, src)
    if goal.who[src] then return true end
    local run = Whip.core:GetScenarioRun(goal.runId, { tests = true })
    for _, p in ipairs(type(run) == 'table' and run.players or {}) do goal.who[tonumber(p.source)] = true end
    return goal.who[src] == true
end

AppearanceServer.onFinish(function(src, s, outcome, info)

    local o = s.callId and opens[s.callId]
    if o then
        o.pending[src] = nil
        if outcome == 'changed' then
            opens[s.callId] = nil
            for other in pairs(o.pending) do AppearanceServer.close(other, 'Another player already finished.') end
            o.card:record('changed', { source = src })
            Whip.answerCard(s.callId, 'changed', { source = src })
        elseif next(o.pending) == nil then
            opens[s.callId] = nil
            Whip.answerCard(s.callId, 'cancelled')
        end
    end

    if outcome ~= 'changed' then return end
    local done = {}
    for callId, g in pairs(goals) do
        if (g.kind == 'any' or g.kind == info.kind) and inRun(g, src) then done[#done + 1] = callId end
    end
    for _, callId in ipairs(done) do
        local g = goals[callId]
        goals[callId] = nil
        g.card:clearObjective()
        if g.timed then g.card:clock(0) end
        g.card:record('done', { source = src })
        Whip.answerCard(callId, 'done', { source = src })
    end
end)

local function restore(src)
    TriggerClientEvent('whip_appearance:client:restore', src)
end

local function endWorn(runId)
    local w = worn[runId]
    if not w then return end
    worn[runId] = nil
    for src in pairs(w.who) do restore(src) end
end

AddEventHandler('whip_core:run:ended', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or type(e.run) ~= 'table' then return end
    endWorn(e.run.id)
end)

AddEventHandler('whip_core:run:playerLeft', function(e)
    if GetInvokingResource() ~= 'whip_core' or type(e) ~= 'table' or type(e.run) ~= 'table' then return end
    local w, src = worn[e.run.id], tonumber(e.source)
    if w and src and w.who[src] then
        w.who[src] = nil
        restore(src)
    end
end)

CreateThread(function()
    while true do
        Wait(TEST_LOOK_MS)
        for runId, w in pairs(worn) do
            if w.test and not Whip.core:GetScenarioRun(runId, { tests = true }) then endWorn(runId) end
        end
    end
end)

Whip.card('whip_appearance.open', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Open Look Store',
    desc = 'Opens the clothing store, barber shop, surgery clinic or tattoo studio for players, wherever they are.',
    help = 'Continues on "Changed" when one of them pays and saves (the store closes for the others), or on "Gave up" when '
        .. 'everyone closes without buying. Anyone in a car gets out first. In a Test nothing is charged or saved.',
    outputs = { 'changed', 'cancelled', 'nobody' },
    labels = { changed = 'Changed', cancelled = 'Gave up', nobody = 'Nobody' },
    bad = { 'cancelled', 'nobody' },
    timeout = 900,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'For whom' },
        { key = 'kind', kind = 'select', label = 'Store', default = 'clothing', options = KIND_OPTIONS },
        { key = 'pays', kind = 'select', label = 'Who pays', default = 'player',
          options = { { value = 'player', label = 'The player (store prices)' }, { value = 'free', label = 'The house (free)' } } },
        { key = 'title', kind = 'text', label = 'Name on screen', maxLength = 50, hint = 'Empty: the store\'s name' },
    },
    run = function(card)
        local p = card.props
        local kind = Appearance.KIND_SET[p.kind] and p.kind or 'clothing'
        local o = { card = card, pending = {} }
        local title = (type(p.title) == 'string' and p.title ~= '') and p.title or Appearance.KindLabel[kind]
        for _, src in ipairs(playersOf(card, p.who)) do
            local ok, why = AppearanceServer.open(src, kind,
                { free = p.pays == 'free', test = card.test == true, title = title, callId = card.callId, by = 'director' })
            if ok then o.pending[src] = true else card:log('%s: %s', GetPlayerName(src) or src, tostring(why)) end
        end
        if next(o.pending) == nil then return 'nobody' end
        opens[card.callId] = o
        return nil
    end,
    onEnd = function(callId)
        local o = opens[callId]
        if not o then return end
        opens[callId] = nil
        for src in pairs(o.pending) do AppearanceServer.close(src, 'The store closed.') end
    end,
})

Whip.card('whip_appearance.goal', {
    category = 'goals',
    title = 'Goal: Change Look',
    desc = 'Continues when a player of the run buys in a clothing store, barber shop, clinic or tattoo studio (one kind, or any).',
    help = 'A purchase in a map store or in one opened by the Open Look Store card counts. With a time limit, '
        .. 'continues on "Out of time" if nobody buys before it.',
    outputs = { 'done', 'outOfTime' },
    labels = { done = 'Changed', outOfTime = 'Out of time' },
    bad = { 'outOfTime' },
    timeout = 3600,
    test = 'run',
    props = {
        { key = 'text', kind = 'text', label = 'Goal (on screen)', maxLength = 120,
          hint = 'Empty: "Change your look" / "Go to a clothing store"...' },
        { key = 'kind', kind = 'select', label = 'Where', default = 'any',
          options = { { value = 'any', label = 'Any look store' }, table.unpack(KIND_OPTIONS) } },
        { key = 'blip', kind = 'bool', label = 'Show stores of this kind on the GPS', default = false,
          hint = 'Marks the nearest store for each player.' },
        { key = 'seconds', kind = 'duration', label = 'Time limit', unit = 's', min = 0, max = 3600, default = 0,
          hint = '0: no limit' },
    },
    run = function(card)
        local p = card.props
        local kind = (p.kind == 'any' or Appearance.KIND_SET[p.kind]) and p.kind or 'any'
        local g = { card = card, kind = kind, runId = card.runId, who = {} }
        for _, s in ipairs(card.players or {}) do g.who[tonumber(s)] = true end

        local text = p.text
        if type(text) ~= 'string' or text == '' then
            text = ({ any = 'Change your look', clothing = 'Go to a clothing store',
                      barber = 'Go to a barber shop', surgery = 'Go to the plastic surgery clinic',
                      tattoo = 'Get a tattoo' })[kind]
        end
        card:objective(text)

        if p.blip == true then
            for src in pairs(g.who) do
                local ped = GetPlayerPed(src)
                local at = ped ~= 0 and GetEntityCoords(ped) or nil
                local best, bestD
                for _, k in ipairs(kind == 'any' and Appearance.KINDS or { kind }) do
                    for _, shop in ipairs(Config.Shops[k] or {}) do
                        local c = shop.coords
                        if at and c and c.x and shop.hideBlip ~= true then
                            local d = #(at - vector3(c.x, c.y, c.z))
                            if not bestD or d < bestD then best, bestD = vector3(c.x, c.y, c.z), d end
                        end
                    end
                end
                if best then Whip.core:SetPlayerWaypoint(src, best) end
            end
        end

        local seconds = tonumber(p.seconds) or 0
        if seconds > 0 then
            card:clock(seconds, text)
            g.timed = true
            g.endsAt = GetGameTimer() + math.floor(seconds * 1000)
            local callId = card.callId
            CreateThread(function()
                while goals[callId] == g do
                    Wait(500)
                    if goals[callId] == g and GetGameTimer() >= g.endsAt then
                        goals[callId] = nil
                        card:clearObjective()
                        card:clock(0)
                        Whip.answerCard(callId, 'outOfTime')
                    end
                end
            end)
        end
        goals[card.callId] = g
        return nil
    end,
    onEnd = function(callId) goals[callId] = nil end,
})

local function outfitFor(list, model)
    local fits = {}
    for _, o in ipairs(type(list) == 'table' and list or {}) do
        if type(o) == 'table' and o.model == model then fits[#fits + 1] = o end
    end
    if #fits == 0 then return nil end
    return fits[math.random(#fits)]
end

Whip.card('whip_appearance.wear', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Wear Outfit (disguise)',
    desc = 'Puts an outfit over the players\' look, without saving. It comes off by itself when the run ends.',
    help = 'Pick the outfits in the card itself ("Pick outfit in the store"): the store opens on your character and nothing is paid '
        .. 'or saved. An outfit made on a male body only fits male characters (and the same for female): '
        .. 'pick one of each to fit everyone. With several, each player gets a random one among those that fit.',
    outputs = { 'worn', 'nobody' },
    labels = { worn = 'Worn', nobody = 'Nobody' },
    bad = { 'nobody' },
    timeout = 15,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'Who wears it' },
        { key = 'outfits', kind = 'entries', label = 'Clothing', button = 'whip_appearance.pickOutfit', add = 'Pick outfit in the store',
          max = 8, hint = 'Each one is a full outfit picked in the store.' },
    },
    check = function(props)
        local list = type(props.outfits) == 'table' and props.outfits or {}
        if #list == 0 then return 'No outfit picked: use "Pick outfit in the store"', 'warning' end
        local m, f = false, false
        for _, o in ipairs(list) do
            if type(o) == 'table' and o.model == Appearance.MODELS.male then m = true end
            if type(o) == 'table' and o.model == Appearance.MODELS.female then f = true end
        end
        if not (m and f) then
            return ('There are only outfits for %s characters: the others get no disguise'):format(m and 'male' or 'female'), 'warning'
        end
        return nil
    end,
    run = function(card)
        local any = false
        for _, src in ipairs(playersOf(card, card.props.who)) do
            local look = Whip.core:GetPlayerMetadata(src, 'appearance')
            local outfit = type(look) == 'table' and outfitFor(card.props.outfits, look.model) or nil
            if outfit and not AppearanceServer.isOpen(src) then
                TriggerClientEvent('whip_appearance:client:wear', src, outfit)
                local w = worn[card.runId] or { test = card.test == true, who = {} }
                worn[card.runId] = w
                w.who[src] = true
                any = true
            else
                card:log('%s: no outfit fits this body (or they are in a store)', GetPlayerName(src) or src)
            end
        end
        return any and 'worn' or 'nobody'
    end,
})

Whip.card('whip_appearance.restore', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Restore Saved Look',
    desc = 'Removes a disguise: the players\' saved look comes back.',
    outputs = { 'done' },
    labels = { done = 'Done' },
    instant = true,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'Who' },
    },
    run = function(card)
        local w = worn[card.runId]
        for _, src in ipairs(playersOf(card, card.props.who)) do
            if w then w.who[src] = nil end
            if not AppearanceServer.isOpen(src) then restore(src) end
        end
        return 'done'
    end,
})

Whip.card('whip_appearance.wardrobe', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Open Outfit Wardrobe',
    desc = 'Opens a company\'s wardrobe for players, wherever they are: they put on an outfit with 1 click.',
    help = 'The job is its key (e.g. police). Opened by the Director, any player can wear any outfit of the '
        .. 'wardrobe (the minimum rank does not apply). In a Test the wardrobe opens the same: wearing saves the character\'s clothes.',
    outputs = { 'opened', 'nobody' },
    labels = { opened = 'Opened', nobody = 'Nobody' },
    bad = { 'nobody' },
    timeout = 15,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'For whom' },
        { key = 'job', kind = 'text', label = 'Job (key)', maxLength = 60, hint = 'e.g. police' },
        { key = 'title', kind = 'text', label = 'Name on screen', maxLength = 50, hint = 'Empty: the company\'s Wardrobe' },
    },
    check = function(props)
        if type(props.job) ~= 'string' or props.job == '' then return 'Pick the wardrobe\'s job', 'warning' end
        return nil
    end,
    run = function(card)
        local p = card.props
        local any = false
        for _, src in ipairs(playersOf(card, p.who)) do
            local ok, why = AppearanceWardrobe.openFor(src, tostring(p.job or ''),
                { title = (type(p.title) == 'string' and p.title ~= '') and p.title or nil })
            if ok then any = true else card:log('%s: %s', GetPlayerName(src) or src, tostring(why)) end
        end
        return any and 'opened' or 'nobody'
    end,
})

Whip.card('whip_appearance.uniform', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Wear Company Outfit',
    desc = 'Puts an outfit from a company wardrobe over the look, without saving. It comes off by itself when the run ends.',
    help = 'Good for disguises: a police, medic or courier uniform. The outfit must exist in the company\'s wardrobe '
        .. 'for the player\'s body (male / female). With an empty name, the first one that fits is used.',
    outputs = { 'worn', 'nobody' },
    labels = { worn = 'Worn', nobody = 'Nobody' },
    bad = { 'nobody' },
    timeout = 15,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'Who wears it' },
        { key = 'job', kind = 'text', label = 'Job (key)', maxLength = 60, hint = 'e.g. police' },
        { key = 'name', kind = 'text', label = 'Outfit name', maxLength = 40, hint = 'Empty: the first one that fits' },
    },
    check = function(props)
        if type(props.job) ~= 'string' or props.job == '' then return 'Pick the wardrobe\'s job', 'warning' end
        return nil
    end,
    run = function(card)
        local p = card.props
        local wanted = type(p.name) == 'string' and p.name:lower() or ''
        local any = false
        for _, src in ipairs(playersOf(card, p.who)) do
            local look = Whip.core:GetPlayerMetadata(src, 'appearance')
            local pick
            for _, o in ipairs(AppearanceWardrobe.outfitsOf(p.job)) do
                if type(look) == 'table' and o.model == look.model and (wanted == '' or o.name:lower() == wanted) then
                    pick = o
                    break
                end
            end
            if pick and not AppearanceServer.isOpen(src) then
                TriggerClientEvent('whip_appearance:client:wear', src, { model = pick.model, components = pick.components, props = pick.props })
                local w = worn[card.runId] or { test = card.test == true, who = {} }
                worn[card.runId] = w
                w.who[src] = true
                any = true
            else
                card:log('%s: no outfit (%s) of %s fits this body, or they are in a store', GetPlayerName(src) or src,
                    wanted ~= '' and wanted or 'any', tostring(p.job))
            end
        end
        return any and 'worn' or 'nobody'
    end,
})

local function onDungeon(source, _, target, what)
    if not (exports.whip_core:HasPermission(source, 'director.live') or exports.whip_core:HasDevTools(source)) then
        return false, 'Only a Dungeon Master can do that.'
    end
    if GetPlayerPed(target) == 0 then return false, 'That player is not on the server.' end
    if what == 'restore' then
        for _, w in pairs(worn) do w.who[target] = nil end
        restore(target)
        return
    end
    if what == 'wardrobe' then
        local job = exports.whip_core:GetPlayerJob(target)
        if type(job) ~= 'table' or not job.key then return false, 'That player is not on duty at a job.' end
        local ok, why = AppearanceWardrobe.openFor(target, job.key,
            { title = 'Wardrobe: ' .. tostring(job.name or job.key) .. ' (Dungeon Master)' })
        if not ok then return false, why end
        exports.whip_core:NotifyPlayer(source, ('%s wardrobe opened for %s.'):format(tostring(job.name or job.key),
            GetPlayerName(target) or target), 'success')
        return
    end
    local ok, why = AppearanceServer.open(target, what,
        { free = true, title = Appearance.KindLabel[what] .. ' (Dungeon Master)', by = 'dungeon' })
    if not ok then return false, why end
    exports.whip_core:NotifyPlayer(source, ('%s opened for %s.'):format(Appearance.KindLabel[what], GetPlayerName(target) or target), 'success')
end

Whip.register(function()
    exports.whip_core:SecureEvent('whip_appearance:dungeon', {
        rateLimit = 1000, burst = 3,
        params = {
            { 'target', 'id' },
            { 'what', 'enum', { 'clothing', 'barber', 'surgery', 'tattoo', 'wardrobe', 'restore' } },
        },
    }, onDungeon)
end)
