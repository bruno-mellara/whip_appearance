Config = {}

Config.UseRange = 2.5

Config.AllowBank = true

Config.Blips = {
    clothing = { sprite = 73,  color = 0,  label = 'Clothing Store' },
    barber   = { sprite = 71,  color = 0,  label = 'Barber Shop' },
    surgery  = { sprite = 403, color = 1,  label = 'Plastic Surgery' },
    tattoo   = { sprite = 75,  color = 0,  label = 'Tattoo Studio' },
}

Config.Shops = {
    clothing = {
        { name = 'Binco - Textile City',          coords = vector3(75.95, -1392.89, 29.38) },
        { name = 'Binco - Vespucci',              coords = vector3(-822.19, -1074.13, 11.33) },
        { name = 'Binco - Sinner Street',         coords = vector3(425.24, -806.01, 29.49) },
        { name = 'Suburban - Del Perro',          coords = vector3(-1192.94, -772.69, 17.33) },
        { name = 'Suburban - Hawick',             coords = vector3(125.77, -223.69, 54.56) },
        { name = 'Suburban - Harmony',            coords = vector3(615.18, 2762.93, 42.09) },
        { name = 'Suburban - Chumash',            coords = vector3(-3171.45, 1043.86, 20.86) },
        { name = 'Ponsonbys - Rockford Hills',    coords = vector3(-712.22, -155.35, 37.42) },
        { name = 'Ponsonbys - Burton',            coords = vector3(-162.66, -303.40, 39.73) },
        { name = 'Ponsonbys - Morningwood',       coords = vector3(-1450.71, -236.83, 49.81) },
        { name = 'Discount Store - Grapeseed',    coords = vector3(1693.32, 4823.48, 42.06) },
        { name = 'Discount Store - Paleto Bay',   coords = vector3(4.25, 6512.81, 31.88) },
        { name = 'Discount Store - Route 68',     coords = vector3(1196.79, 2709.56, 38.22) },
        { name = 'Discount Store - Zancudo',      coords = vector3(-1100.96, 2710.21, 19.11) },
    },
    barber = {
        { name = 'Herr Kutz - Davis',             coords = vector3(136.80, -1708.40, 29.29) },
        { name = 'Herr Kutz - Mirror Park',       coords = vector3(1212.80, -472.90, 66.21) },
        { name = 'Herr Kutz - Paleto Bay',        coords = vector3(-278.10, 6228.50, 31.70) },
        { name = 'Bob Mulet - Rockford Hills',    coords = vector3(-814.30, -183.80, 37.57) },
        { name = 'Beach Combover - Vespucci',     coords = vector3(-1282.60, -1116.80, 6.99) },
        { name = 'Hair on Hawick',                coords = vector3(-32.90, -152.30, 57.08) },
        { name = "O'Sheas - Sandy Shores",        coords = vector3(1931.50, 3729.70, 32.84) },
    },
    surgery = {

        { name = 'Plastic Surgery Clinic',  coords = vector3(-676.25, 311.18, 83.08) },
    },
    tattoo = {

        { name = 'Blazing Tattoo - Vinewood',     coords = vector3(322.10, 180.40, 103.59) },
        { name = 'Los Santos Tattoos - El Burro', coords = vector3(1322.60, -1651.90, 52.28) },
        { name = 'Ink Inc - Vespucci',            coords = vector3(-1153.60, -1425.60, 4.95) },
        { name = 'Ink Inc - Chumash',             coords = vector3(-3170.00, 1075.00, 20.83) },
        { name = 'Ink Inc - Sandy Shores',        coords = vector3(1864.60, 3747.70, 33.03) },
        { name = 'Ink Inc - Paleto Bay',          coords = vector3(-293.70, 6200.00, 31.49) },
    },
}

Config.Prices = {
    clothing = {
        c11 = 120,
        c8  = 60,
        c3  = 40,
        c4  = 90,
        c6  = 80,
        c1  = 50,
        c7  = 40,
        c5  = 70,
        c9  = 150,
        c10 = 40,
        p0  = 45,
        p1  = 40,
        p2  = 35,
        p6  = 60,
        p7  = 35,
    },
    barber = {
        hair      = 60,
        hairColor = 40,
        fade      = 30,
        beard     = 30,
        eyebrows  = 15,
        chestHair = 15,
        makeup    = 35,
        blush     = 20,
        lipstick  = 20,
    },
    surgery = {
        heritage = 2500,
        features = 1500,
        eyes     = 400,
        skin     = 800,
        sex      = 10000,
    },

    tattoo = {
        head   = 400,
        torso  = 600,
        larm   = 350,
        rarm   = 350,
        lleg   = 300,
        rleg   = 300,
        remove = 500,
    },
}

Config.Camera = {
    head  = { bone = 31086, dist = 0.80, z = 0.00, fov = 40.0 },
    torso = { bone = 24818, dist = 1.60, z = -0.05, fov = 45.0 },
    legs  = { bone = 46078, dist = 1.70, z = 0.05, fov = 45.0 },
    feet  = { bone = 14201, dist = 1.30, z = 0.15, fov = 45.0 },
    body  = { bone = 11816, dist = 2.80, z = 0.10, fov = 50.0 },
}

Config.Brands = {
    names = { binco = 'Binco', suburban = 'Suburban', ponsonbys = 'Ponsonbys', discount = 'Discount Store' },
    priority = { 'fancy', 'work', 'street', 'casual' },
    styles = {
        fancy  = { 'ponsonbys', 'suburban' },
        casual = { 'binco', 'suburban', 'discount' },
        street = { 'binco', 'discount' },
        work   = { 'discount', 'binco' },
    },
    keywords = {
        fancy  = { 'suit', 'tux', 'blazer', 'waistcoat', 'tie', 'bow tie', 'dress shirt', 'oxford', 'loafer', 'brogue',
                   'formal', 'evening', 'gown', 'cocktail', 'pencil', 'silk', 'cashmere', 'designer', 'luxury', 'trench',
                   'overcoat', 'peacoat', 'fedora', 'heels', 'pumps', 'stiletto', 'cufflink', 'pearl', 'diamond', 'gold',
                   'smart', 'sports coat', 'breasted', 'tailored', 'dinner', 'tuxedo', 'satin', 'velvet', 'mink', 'fur' },
        casual = { 'polo', 'shirt', 'chino', 'jacket', 'bomber', 'denim', 'leather', 'sweater', 'cardigan', 'khaki',
                   'blouse', 'skirt', 'dress', 'boots', 'jumper', 'button', 'casual', 'coat', 'vest' },
        street = { 'hoodie', 'hooded', 'tee', 't-shirt', 'tank', 'sneaker', 'trainer', 'jeans', 'cargo', 'jogger', 'sweatpants',
                   'track', 'baseball', 'cap', 'snapback', 'beanie', 'bandana', 'jersey', 'shorts', 'skate', 'graphic',
                   'sports', 'hi-top', 'high top', 'basketball', 'street' },
        work   = { 'work', 'overall', 'coverall', 'hi-vis', 'safety', 'flannel', 'sandal', 'flip', 'plain', 'utility', 'apron' },
    },

    collections = {
        business = 'fancy', executive = 'fancy', luxe = 'fancy', apt01 = 'fancy', vinewood = 'fancy',
        beach = 'street', hipster = 'street', lowrider = 'street', tuner = 'street', bikerdlc = 'street',
        stunt = 'street', sum = 'street', battle = 'street',
        gunrunning = 'work', smuggler = 'work', pilot = 'work', airraces = 'work', security = 'work',
    },
}

Config.MaskFix = {
    enabled = true,
    shrinkHeadAll = true,
    shrinkHead = { 108, 30, 35 },
    keepHead = {},
    keepFace = { 11, 114, 145, 148, 121 },
    checkMs = 500,
}

Config.CategoryDefaults = {
    c9  = { blocked = true },
    c10 = { blocked = true },
}

Config.Admin = {
    permission = 'whip_appearance.admin',
    itemWeight = 0.3,
}

Config.Wardrobes = {}

Config.Wardrobe = {
    maxOutfits = 60,
    managePermission = 'canManage',
}
