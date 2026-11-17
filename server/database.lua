AppearanceDB = {}

local ready = false

local TABLES = {
    { name = 'whip_appearance_rules', legacy = 'estilo_rules', sql = [[
        CREATE TABLE IF NOT EXISTS `whip_appearance_rules` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `gender` VARCHAR(6) NOT NULL,
          `kind` VARCHAR(10) NOT NULL,
          `slot` TINYINT UNSIGNED NOT NULL,
          `drawable` SMALLINT UNSIGNED NOT NULL,
          `texture` SMALLINT NOT NULL DEFAULT -1,
          `data` TEXT NOT NULL,
          `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          UNIQUE KEY `piece_tex` (`gender`, `kind`, `slot`, `drawable`, `texture`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    { name = 'whip_appearance_categories', legacy = 'estilo_categories', sql = [[
        CREATE TABLE IF NOT EXISTS `whip_appearance_categories` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `kind` VARCHAR(10) NOT NULL,
          `slot` TINYINT UNSIGNED NOT NULL,
          `data` TEXT NOT NULL,
          `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          UNIQUE KEY `category` (`kind`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    { name = 'whip_appearance_tattoo_rules', legacy = 'estilo_tattoo_rules', sql = [[
        CREATE TABLE IF NOT EXISTS `whip_appearance_tattoo_rules` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `tattoo` VARCHAR(140) NOT NULL,
          `data` TEXT NOT NULL,
          `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          UNIQUE KEY `tattoo` (`tattoo`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    { name = 'whip_appearance_outfits', legacy = 'estilo_outfits', sql = [[
        CREATE TABLE IF NOT EXISTS `whip_appearance_outfits` (
          `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
          `job` VARCHAR(60) NOT NULL,
          `name` VARCHAR(40) NOT NULL,
          `model` VARCHAR(30) NOT NULL,
          `minLevel` INT NOT NULL DEFAULT 0,
          `data` TEXT NOT NULL,
          `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `job` (`job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
    { name = 'whip_appearance_own', legacy = 'estilo_own', sql = [[
        CREATE TABLE IF NOT EXISTS `whip_appearance_own` (
          `charId` INT UNSIGNED NOT NULL,
          `outfit` TEXT NOT NULL,
          `updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`charId`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]] },
}

AppearanceDB.tables = {}
for _, t in ipairs(TABLES) do AppearanceDB.tables[t.name:gsub('^whip_appearance_', '')] = t.name end

local function exists(name)
    local n = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { name })
    return (tonumber(n) or 0) > 0
end

local function setup()
    for _, t in ipairs(TABLES) do
        if t.legacy and not exists(t.name) and exists(t.legacy) then
            MySQL.query.await(('RENAME TABLE `%s` TO `%s`'):format(t.legacy, t.name))
            print(('[whip_appearance] table %s renamed to %s'):format(t.legacy, t.name))
        end
        MySQL.query.await(t.sql)
    end
end

MySQL.ready(function()
    local ok, err = pcall(setup)
    if not ok then
        print(('^1[whip_appearance] database setup failed: %s^0'):format(tostring(err)))
        return
    end
    ready = true
end)

function AppearanceDB.wait(timeoutMs)
    local limit = GetGameTimer() + (timeoutMs or 30000)
    while not ready do
        if GetGameTimer() > limit then return false end
        Wait(100)
    end
    return true
end
