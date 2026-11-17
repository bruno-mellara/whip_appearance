local KIND_OPTIONS = {
    { value = 'clothing', label = 'Clothing Store' },
    { value = 'barber', label = 'Barber Shop' },
    { value = 'surgery', label = 'Plastic Surgery' },
    { value = 'tattoo', label = 'Tattoo Studio' },
}

local TEST_LOOK_MS = 3000

local OUTFIT_POLL_MS = 1000

local opens = {}
local goals = {}
local worn = {}
local outfitGoals = {}
local runOutfits = {}

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

local function disguiseOf(src)
    for _, w in pairs(worn) do
        if type(w.who[src]) == 'table' then return w.who[src] end
    end
    return nil
end

local function putOn(card, src, outfit, keep, waitSave)
    if keep and not card.test then
        local player = Whip.core:GetPlayer(src)
        local saved = AppearanceServer.savedLook(src)
        if type(player) ~= 'table' or not saved then return false end
        local ok, final = Whip.core:SanitizeAppearance(Appearance.wear(saved, outfit))
        if not ok then return false end
        for _, w in pairs(worn) do w.who[src] = nil end
        if waitSave then return AppearanceServer.saveLook(src, player.session, final) == true end
        CreateThread(function()
            if not AppearanceServer.saveLook(src, player.session, final) then
                print(('[whip_appearance] director: could not save the outfit of %s'):format(GetPlayerName(src) or src))
            end
        end)
        return true
    end
    local now = disguiseOf(src)
    local shown = now and Appearance.wear(now, outfit) or outfit
    TriggerClientEvent('whip_appearance:client:wear', src, shown)
    for _, w in pairs(worn) do w.who[src] = nil end
    local w = worn[card.runId] or { test = card.test == true, who = {} }
    worn[card.runId] = w
    w.who[src] = shown
    return true
end

local function lookOf(src)
    local look = Whip.core:GetPlayerMetadata(src, 'appearance')
    if type(look) ~= 'table' then return nil end
    local d = disguiseOf(src)
    return d and Appearance.wear(look, d) or look
end

local function targetsOf(p, runId)
    if p.from == 'run' then return runOutfits[runId] or {} end
    if p.from == 'company' then
        local wanted = type(p.name) == 'string' and p.name:lower() or ''
        local list = {}
        for _, o in ipairs(AppearanceWardrobe.outfitsOf(tostring(p.job or '')) or {}) do
            if wanted == '' or tostring(o.name):lower() == wanted then list[#list + 1] = o end
        end
        return list
    end
    return type(p.outfits) == 'table' and p.outfits or {}
end

local function wearing(src, targets, p)
    local look = lookOf(src)
    if not look then return false end
    local opts = { all = p.pieces == 'all', colors = p.colors == true }
    for _, o in ipairs(targets) do
        if type(o) == 'table' and Appearance.outfitMatches(look, o, opts) then return true end
    end
    return false
end

local function outfitCheck(props)
    if props.from == 'run' then return nil end
    if props.from == 'company' then
        if type(props.job) ~= 'string' or props.job == '' then return 'Type the job of the wardrobe', 'warning' end
        return nil
    end
    local list = type(props.outfits) == 'table' and props.outfits or {}
    if #list == 0 then return 'No outfit picked: use "Pick outfit in the store"', 'warning' end
    return nil
end

local function withOutfit(before, after)
    local out = {}
    for _, f in ipairs(before) do out[#out + 1] = f end
    for _, f in ipairs({
        { key = 'from', kind = 'select', label = 'Which outfit', default = 'picked',
          options = { { value = 'picked', label = 'Picked in this card' },
                      { value = 'run', label = 'Any outfit of this mission\'s wardrobes' },
                      { value = 'company', label = 'From a company wardrobe (job)' } } },
        { key = 'outfits', kind = 'entries', label = 'Outfits (picked)', button = 'whip_appearance.pickOutfit', add = 'Pick outfit in the store',
          max = 8, hint = 'Any one of them counts. An outfit only fits the body it was made on: pick one of each to fit everyone.' },
        { key = 'job', kind = 'text', label = 'Wardrobe job (key)', maxLength = 60, hint = 'From a company wardrobe: e.g. police' },
        { key = 'name', kind = 'text', label = 'Outfit name', maxLength = 40, hint = 'From a company wardrobe. Empty: any of its outfits' },
        { key = 'pieces', kind = 'select', label = 'What must match', default = 'main',
          options = { { value = 'main', label = 'Main pieces (jacket, undershirt, pants, shoes)' },
                      { value = 'all', label = 'Every piece (masks, hats, accessories too)' } } },
        { key = 'colors', kind = 'bool', label = 'Colors must match too', default = false },
    }) do out[#out + 1] = f end
    for _, f in ipairs(after or {}) do out[#out + 1] = f end
    return out
end

local function runPlayers(runId)
    local run = Whip.core:GetScenarioRun(runId, { tests = true })
    local out = {}
    for _, p in ipairs(type(run) == 'table' and run.players or {}) do
        local src = tonumber(p.source)
        if src and GetPlayerPed(src) ~= 0 then out[#out + 1] = src end
    end
    return out, type(run) == 'table'
end

local function finishOutfitGoal(callId, g, out, src)
    outfitGoals[callId] = nil
    g.card:clearObjective()
    if g.timed then g.card:clock(0) end
    if out == 'done' then g.card:record('done', { source = src }) end
    Whip.answerCard(callId, out, src and { source = src } or nil)
end

CreateThread(function()
    while true do
        Wait(OUTFIT_POLL_MS)
        for callId, g in pairs(outfitGoals) do
            if g.endsAt and GetGameTimer() >= g.endsAt then
                finishOutfitGoal(callId, g, 'outOfTime')
            else
                local list, alive = runPlayers(g.runId)
                if alive and #list > 0 then
                    local targets = targetsOf(g.props, g.runId)
                    local first, all = nil, true
                    for _, src in ipairs(list) do
                        if wearing(src, targets, g.props) then first = first or src else all = false end
                    end
                    if outfitGoals[callId] == g and first and (g.props.need ~= 'all' or all) then
                        finishOutfitGoal(callId, g, 'done', first)
                    end
                end
            end
        end
    end
end)

local function endWorn(runId)
    runOutfits[runId] = nil
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
    title = 'Wear Outfit',
    desc = 'Puts an outfit picked in the card on the players: as a disguise that comes off when the run ends, or kept as their clothes.',
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
        { key = 'keep', kind = 'bool', label = 'Keep it (save as the character\'s clothes)', default = false,
          hint = 'Off: a disguise that comes off when the run ends. On: saved like clothes bought in a store. In a Test it is always a disguise.' },
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
            if outfit and not AppearanceServer.isOpen(src) and putOn(card, src, outfit, card.props.keep == true) then
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
    desc = 'Opens a wardrobe for players, wherever they are: they put on an outfit with 1 click. Its outfits are made in '
        .. 'the card for this mission, or come from a company.',
    help = 'Outfits made in this card belong only to this mission: no job needed. Each one gets a name when you pick it. '
        .. 'Without "Keep it" an outfit is a disguise that comes off when the run ends; "Back to my clothes" takes it off. '
        .. 'Goal: Wear an Outfit and Is Wearing Outfit? can check them with "Any outfit of this mission\'s wardrobes". '
        .. 'From a company, the job is its key (e.g. police) and the minimum rank does not apply; wearing saves the clothes.',
    outputs = { 'opened', 'nobody' },
    labels = { opened = 'Opened', nobody = 'Nobody' },
    bad = { 'nobody' },
    timeout = 15,
    test = 'run',
    props = {
        { key = 'who', kind = 'players', label = 'For whom' },
        { key = 'from', kind = 'select', label = 'Outfits', default = 'picked',
          options = { { value = 'picked', label = 'Made in this card (this mission only)' },
                      { value = 'company', label = 'A company wardrobe (job)' } } },
        { key = 'outfits', kind = 'entries', label = 'Outfits (this mission)', button = 'whip_appearance.pickOutfit',
          add = 'Pick outfit in the store', max = 12,
          hint = 'Each one gets a name. An outfit fits only the body it was made on: make male and female versions.' },
        { key = 'keep', kind = 'bool', label = 'Keep it (save as the character\'s clothes)', default = false,
          hint = 'Off: a disguise that comes off when the run ends. On: saved like clothes bought in a store. In a Test it is always a disguise.' },
        { key = 'job', kind = 'text', label = 'Job (key)', maxLength = 60, hint = 'A company wardrobe: e.g. police' },
        { key = 'title', kind = 'text', label = 'Name on screen', maxLength = 50, hint = 'Empty: "Wardrobe" or the company\'s' },
    },
    check = function(props)
        if props.from == 'company' then
            if type(props.job) ~= 'string' or props.job == '' then return 'Pick the wardrobe\'s job', 'warning' end
            return nil
        end
        local list = type(props.outfits) == 'table' and props.outfits or {}
        if #list == 0 and (type(props.job) ~= 'string' or props.job == '') then
            return 'No outfit made: use "Pick outfit in the store"', 'warning'
        end
        return nil
    end,
    run = function(card)
        local p = card.props
        local list = type(p.outfits) == 'table' and p.outfits or {}
        local custom = p.from ~= 'company' and (#list > 0 or type(p.job) ~= 'string' or p.job == '')
        local title = (type(p.title) == 'string' and p.title ~= '') and p.title or nil
        local any = false
        if custom then
            local mine = runOutfits[card.runId] or {}
            runOutfits[card.runId] = mine
            for _, o in ipairs(list) do mine[#mine + 1] = o end
        end
        local keep = p.keep == true
        local runCard = { runId = card.runId, test = card.test == true }
        for _, src in ipairs(playersOf(card, p.who)) do
            local ok, why
            if custom then
                ok, why = AppearanceWardrobe.openCustom(src, {
                    title = title or 'Wardrobe', outfits = list, hasOwn = disguiseOf(src) ~= nil,
                    onWear = function(who, outfit) return putOn(runCard, who, outfit, keep, true) end,
                    onRestore = function(who, player)
                        for _, w in pairs(worn) do w.who[who] = nil end
                        local saved = AppearanceServer.savedLook(who)
                        if not saved then return false end
                        return AppearanceServer.saveLook(who, player.session, saved) == true
                    end,
                })
            else
                ok, why = AppearanceWardrobe.openFor(src, tostring(p.job or ''), { title = title })
            end
            if ok then any = true else card:log('%s: %s', GetPlayerName(src) or src, tostring(why)) end
        end
        return any and 'opened' or 'nobody'
    end,
})

Whip.card('whip_appearance.uniform', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Wear Company Outfit',
    desc = 'Puts an outfit from a company wardrobe on the players: as a disguise that comes off when the run ends, or kept as their clothes.',
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
        { key = 'keep', kind = 'bool', label = 'Keep it (save as the character\'s clothes)', default = false,
          hint = 'Off: a disguise that comes off when the run ends. On: saved like clothes from the wardrobe. In a Test it is always a disguise.' },
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
            if pick and not AppearanceServer.isOpen(src)
                and putOn(card, src, { model = pick.model, components = pick.components, props = pick.props }, p.keep == true) then
                any = true
            else
                card:log('%s: no outfit (%s) of %s fits this body, or they are in a store', GetPlayerName(src) or src,
                    wanted ~= '' and wanted or 'any', tostring(p.job))
            end
        end
        return any and 'worn' or 'nobody'
    end,
})

Whip.card('whip_appearance.goalOutfit', {
    category = 'goals',
    title = 'Goal: Wear an Outfit',
    desc = 'Continues when a player of the run (or all of them) is wearing the outfit set in this card.',
    help = 'Set the outfit in the card: pick it in the store, or name an outfit of a company wardrobe. The goal checks the '
        .. 'clothes the player is wearing: bought in a store, put on at a wardrobe or with an exclusive item, or put on by '
        .. 'a Wear Outfit card. With a time limit, continues on "Out of time" if it is not worn before it.',
    outputs = { 'done', 'outOfTime' },
    labels = { done = 'Wearing it', outOfTime = 'Out of time' },
    bad = { 'outOfTime' },
    timeout = 3600,
    test = 'run',
    props = withOutfit({
        { key = 'text', kind = 'text', label = 'Goal (on screen)', maxLength = 120, hint = 'Empty: "Put on the outfit"' },
        { key = 'need', kind = 'select', label = 'Who must wear it', default = 'any',
          options = { { value = 'any', label = 'Any player of the run' }, { value = 'all', label = 'Every player of the run' } } },
    }, {
        { key = 'gps', kind = 'select', label = 'GPS', default = 'none',
          options = { { value = 'none', label = 'No GPS' }, { value = 'store', label = 'Nearest clothing store' },
                      { value = 'wardrobe', label = 'The company\'s wardrobe' } } },
        { key = 'seconds', kind = 'duration', label = 'Time limit', unit = 's', min = 0, max = 3600, default = 0, hint = '0: no limit' },
    }),
    check = function(props)
        local why, level = outfitCheck(props)
        if why then return why, level end
        if props.gps == 'wardrobe' and props.from ~= 'company' then
            return 'The wardrobe GPS needs an outfit from a company wardrobe', 'warning'
        end
        return nil
    end,
    run = function(card)
        local p = card.props
        local g = { card = card, runId = card.runId, props = p }
        local text = (type(p.text) == 'string' and p.text ~= '') and p.text or 'Put on the outfit'
        card:objective(text)

        if p.gps == 'store' or p.gps == 'wardrobe' then
            local spots = {}
            if p.gps == 'store' then
                for _, shop in ipairs(Config.Shops.clothing or {}) do
                    local c = shop.coords
                    if c and c.x and shop.hideBlip ~= true and not shop.jobs then spots[#spots + 1] = vector3(c.x, c.y, c.z) end
                end
            else
                local job = tostring(p.job or ''):lower()
                for _, wd in ipairs(Config.Wardrobes or {}) do
                    local c = wd.coords
                    if c and c.x and tostring(wd.job or ''):lower() == job then spots[#spots + 1] = vector3(c.x, c.y, c.z) end
                end
            end
            local list = runPlayers(card.runId)
            for _, src in ipairs(list) do
                local ped = GetPlayerPed(src)
                local at = ped ~= 0 and GetEntityCoords(ped) or nil
                local best, bestD
                for _, v in ipairs(spots) do
                    local d = at and #(at - v)
                    if d and (not bestD or d < bestD) then best, bestD = v, d end
                end
                if best then Whip.core:SetPlayerWaypoint(src, best) end
            end
        end

        local seconds = tonumber(p.seconds) or 0
        if seconds > 0 then
            card:clock(seconds, text)
            g.timed = true
            g.endsAt = GetGameTimer() + math.floor(seconds * 1000)
        end
        outfitGoals[card.callId] = g
        return nil
    end,
    onEnd = function(callId) outfitGoals[callId] = nil end,
})

Whip.card('whip_appearance.isWearing', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Is Wearing Outfit?',
    desc = 'Goes Yes when the players are wearing the outfit set in this card, otherwise No: the guard lets the uniform in.',
    help = 'Checks the clothes worn right now, disguises from the Wear Outfit cards included.',
    outputs = { 'yes', 'no' },
    labels = { yes = 'Yes', no = 'No' },
    instant = true,
    test = 'run',
    props = withOutfit({
        { key = 'who', kind = 'players', label = 'Who' },
        { key = 'need', kind = 'select', label = 'Yes when', default = 'any',
          options = { { value = 'any', label = 'Any of them wears it' }, { value = 'all', label = 'All of them wear it' } } },
    }),
    check = function(props) return outfitCheck(props) end,
    run = function(card)
        local p = card.props
        local targets = targetsOf(p, card.runId)
        local list = playersOf(card, p.who)
        if #list == 0 then return 'no' end
        local first, all = nil, true
        for _, src in ipairs(list) do
            if wearing(src, targets, p) then first = first or src else all = false end
        end
        if p.need == 'all' then return all and 'yes' or 'no' end
        return first and 'yes' or 'no'
    end,
})

local TAKE_OFF = {
    { key = 'mask', label = 'Mask', path = { 'components', '1' }, none = 0 },
    { key = 'hat', label = 'Hat or cap', path = { 'props', '0' }, none = -1 },
    { key = 'glasses', label = 'Glasses', path = { 'props', '1' }, none = -1 },
    { key = 'earrings', label = 'Earrings', path = { 'props', '2' }, none = -1 },
    { key = 'vest', label = 'Vest', path = { 'components', '9' }, none = 0 },
    { key = 'bag', label = 'Bag or backpack', path = { 'components', '5' }, none = 0 },
    { key = 'accessories', label = 'Accessories (chains, ties)', path = { 'components', '7' }, none = 0 },
    { key = 'watch', label = 'Watch', path = { 'props', '6' }, none = -1 },
    { key = 'bracelet', label = 'Bracelet', path = { 'props', '7' }, none = -1 },
}

local function takeOffProps()
    local out = { { key = 'who', kind = 'players', label = 'Who' } }
    for _, t in ipairs(TAKE_OFF) do
        out[#out + 1] = { key = t.key, kind = 'bool', label = t.label, default = t.key == 'mask' or t.key == 'hat' or t.key == 'glasses' }
    end
    out[#out + 1] = { key = 'keep', kind = 'bool', label = 'Keep it (save as the character\'s clothes)', default = false,
                      hint = 'Off: the pieces come back when the run ends. On: they are taken off the saved clothes. In a Test they always come back.' }
    return out
end

Whip.card('whip_appearance.takeOff', {
    categoryTitle = 'Appearance', color = 'violet', icon = 'store',
    title = 'Take Off Pieces',
    desc = 'Takes the chosen pieces off the players: mask, hat, glasses, vest, bag...',
    help = 'Good for an arrest, a checkpoint or a dress code. Without "Keep it", the pieces come back when the run ends '
        .. '(or with Restore Saved Look).',
    outputs = { 'done', 'nobody' },
    labels = { done = 'Done', nobody = 'Nobody' },
    bad = { 'nobody' },
    timeout = 15,
    test = 'run',
    props = takeOffProps(),
    check = function(props)
        for _, t in ipairs(TAKE_OFF) do if props[t.key] == true then return nil end end
        return 'Pick at least one piece to take off', 'warning'
    end,
    run = function(card)
        local p = card.props
        local outfit = { components = {}, props = {} }
        local any = false
        for _, t in ipairs(TAKE_OFF) do
            if p[t.key] == true then outfit[t.path[1]][t.path[2]] = { drawable = t.none, texture = 0 } end
        end
        for _, src in ipairs(playersOf(card, p.who)) do
            if not AppearanceServer.isOpen(src) and putOn(card, src, outfit, p.keep == true) then
                any = true
            else
                card:log('%s: in a store, or the look could not be read', GetPlayerName(src) or src)
            end
        end
        return any and 'done' or 'nobody'
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
