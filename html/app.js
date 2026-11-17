const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'whip_appearance';
const CORE = 'https://cfx-nui-whip_core/html/';
const $ = (id) => document.getElementById(id);
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
const money = (n) => '$' + Math.round(n || 0).toLocaleString('en-US');
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

async function post(name, data) {
    try {
        const r = await fetch(`https://${RES}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        });
        return await r.json();
    } catch (e) {
        return {};
    }
}

const S = {
    open: false,
    view: null,
    mode: 'shop',
    groups: [],
    look: null,
    savedModel: null,
    maxes: null,
    icons: null,
    pictures: null,
    fades: [],
    palettes: { hair: [], makeup: [] },
    quote: { lines: [], total: 0 },
    tab: null,
    sub: {},
    feature: 'brow',
    opened: null,
    busy: false,
    pad: false,
    focus: null,
    texCount: {},
    names: null,
};

const svg = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
const GLYPH = {
    none: svg('<circle cx="12" cy="12" r="8.5"/><path d="M6 6l12 12"/>'),
    hair: svg('<path d="M5 15v-3a7 7 0 0 1 14 0v3"/><path d="M5 12c1.5-.8 2.5-2.6 3-4.5"/><path d="M19 12c-1.5-.8-2.5-2.6-3-4.5"/>'),
    fade: svg('<path d="M4.5 12a7.5 7.5 0 0 1 15 0c0 4.7-3.4 8.5-7.5 8.5S4.5 16.7 4.5 12Z"/><path d="M6.4 10.6h.01M8.6 9.9h.01M15.4 9.9h.01M17.6 10.6h.01M6.2 13.2h.01M17.8 13.2h.01"/>'),
    beard: svg('<path d="M6 8v3c0 4.5 2.6 8 6 8s6-3.5 6-8V8"/><path d="M9 13v2.5"/><path d="M12 14v2.5"/><path d="M15 13v2.5"/>'),
    brow: svg('<path d="M4 10c2-2.4 5-2.4 7-.8"/><path d="M13 9.2c2-1.6 5-1.6 7 .8"/>'),
    chest: svg('<path d="M7 4c0 2-1 3.5-3 4.5V20h16V8.5c-2-1-3-2.5-3-4.5"/><path d="M10.5 11c.5 1 2.5 1 3 0"/>'),
    makeup: svg('<path d="M10 10h4v9a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-9Z"/><path d="M11 10V5.5c0-1 2-1 2 0V10"/>'),
    lips: svg('<path d="M4 12.5c2.5-.8 4-3 6-3 .8 0 1.4.8 2 .8s1.2-.8 2-.8c2 0 3.5 2.2 6 3"/><path d="M4 12.5c2.5 2.8 5 4 8 4s5.5-1.2 8-4"/>'),
    skin: svg('<circle cx="12" cy="12" r="8.5"/><path d="M9 9.2h.01M14.6 8h.01M15.5 13.5h.01M10 14.8h.01"/>'),
    face: svg('<circle cx="12" cy="12" r="8.5"/><path d="M9 10.2v1.2M15 10.2v1.2"/><path d="M9.5 15.2c1.6 1.2 3.4 1.2 5 0"/>'),
    eye: svg('<path d="M2.5 12S6.5 6.5 12 6.5 21.5 12 21.5 12 17.5 17.5 12 17.5 2.5 12 2.5 12Z"/><circle cx="12" cy="12" r="2.6"/>'),
    dna: svg('<path d="M8 3c0 5.5 8 6.5 8 9s-8 3.5-8 9"/><path d="M16 3c0 5.5-8 6.5-8 9s8 3.5 8 9"/><path d="M9 6.5h6M9 17.5h6"/>'),
    nose: svg('<path d="M12 5v7.5c0 2-1.8 2.2-2.6 3.4-.7 1 0 2.6 1.6 2.6h2c1.6 0 2.3-1.6 1.6-2.6-.8-1.2-2.6-1.4-2.6-3.4"/>'),
    cheek: svg('<path d="M5 8c0 7 3 11.5 7 11.5S19 15 19 8"/><path d="M8 12.5c.8 1 2 1.2 3 .6M16 12.5c-.8 1-2 1.2-3 .6"/>'),
    jaw: svg('<path d="M5 6v5c0 4.5 3.2 8 7 8s7-3.5 7-8V6"/><path d="M9 15.5c1.8 1.2 4.2 1.2 6 0"/>'),
    chin: svg('<path d="M7 11c0 4 2.2 7.5 5 7.5s5-3.5 5-7.5"/><path d="M10.2 15.8c1.1.9 2.5.9 3.6 0"/>'),
    neck: svg('<path d="M8 4c0 3.5-.5 6-2 8M16 4c0 3.5.5 6 2 8"/><path d="M6 20c1.5-3 2.5-4.5 6-4.5s4.5 1.5 6 4.5"/>'),
    male: svg('<circle cx="10" cy="14" r="5.5"/><path d="M14 10l6-6M15 4h5v5"/>'),
    female: svg('<circle cx="12" cy="9" r="5.5"/><path d="M12 14.5V21M9 18h6"/>'),
    mask: svg('<path d="M4 8c0-1.5 1-2.5 2.5-2.5h11C19 5.5 20 6.5 20 8v4c0 4-3.5 6.5-8 6.5S4 16 4 12V8Z"/><path d="M7.5 10.5h3M13.5 10.5h3"/>'),
    jacket: svg('<path d="M9 4 5 6l1 13h5V6.5L9 4Z"/><path d="M15 4l4 2-1 13h-5V6.5L15 4Z"/>'),
    tshirt: svg('<path d="M9 4 5 6.5 6.5 10 8 9.5V19h8V9.5l1.5.5L19 6.5 15 4a3 3 0 0 1-6 0Z"/>'),
    shirt: svg('<path d="M9 4 5 6.5 6.5 10 8 9.5V20h8V9.5l1.5.5L19 6.5 15 4c0 1.2-1.2 2-3 2s-3-.8-3-2Z"/>'),
    pants: svg('<path d="M7 4h10l1 16h-5l-1-9-1 9H6L7 4Z"/><path d="M7 8h10"/>'),
    shoe: svg('<path d="M4 15V9.5c2 .8 4 .8 5.5 0 1 2.2 3 3.7 6 4.3 2.5.5 4.5 1.5 4.5 3.2v1H4v-3Z"/><path d="M4 18h16"/>'),
    chain: svg('<path d="M5 6c1.5 3.5 4 5.5 7 5.5S17.5 9.5 19 6"/><path d="M12 11.5v2"/><path d="M12 13.5l-1.8 2.2L12 18l1.8-2.3L12 13.5Z"/>'),
    bag: svg('<path d="M7 8h10v11a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V8Z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>'),
    vest: svg('<path d="M8 4c0 1.5 1.6 2.5 4 2.5S16 5.5 16 4"/><path d="M8 4 6 8v12h12V8l-2-4"/><path d="M6 13h12"/>'),
    decal: svg('<path d="M9 4 5 6.5 6.5 10 8 9.5V20h8V9.5l1.5.5L19 6.5 15 4a3 3 0 0 1-6 0Z"/><path d="m12 11 1 2h2l-1.6 1.3.6 2.2-2-1.3-2 1.3.6-2.2L9 13h2l1-2Z"/>'),
    hat: svg('<path d="M5 14a7 7 0 0 1 14 0"/><path d="M3 14h18c0 1.2-1 2-2.5 2h-13C4 16 3 15.2 3 14Z"/>'),
    glasses: svg('<circle cx="7.5" cy="13" r="3.5"/><circle cx="16.5" cy="13" r="3.5"/><path d="M11 13h2"/>'),
    ear: svg('<path d="M9 9a4.5 4.5 0 0 1 9 0c0 2.5-2 3.2-2 5.5"/><circle cx="15" cy="17.5" r="2"/>'),
    watch: svg('<circle cx="12" cy="12" r="4.5"/><path d="M12 9.5V12l1.8 1"/><path d="M9.5 7.8 10 3h4l.5 4.8M9.5 16.2 10 21h4l.5-4.8"/>'),
    bracelet: svg('<path d="M5 12a7 7 0 0 1 14 0 7 7 0 0 1-14 0Z"/>'),
    tattoo: svg('<path d="M12 20c-4.2-3-7.5-6-7.5-10a4 4 0 0 1 7.5-2 4 4 0 0 1 7.5 2c0 4-3.3 7-7.5 10Z"/><path d="M9 11.5c1 .9 2 1.3 3 1.3s2-.4 3-1.3"/>'),
};

const META = {
    c11: { glyph: 'jacket', tab: 'Jackets', one: 'Jacket' }, c8: { glyph: 'tshirt', tab: 'Undershirts', one: 'Undershirt' },
    c3: { glyph: 'shirt', tab: 'Arms', one: 'Arms' }, c4: { glyph: 'pants', tab: 'Pants', one: 'Pants' },
    c6: { glyph: 'shoe', tab: 'Shoes', one: 'Shoes' }, c1: { glyph: 'mask', tab: 'Masks', one: 'Mask' },
    c7: { glyph: 'chain', tab: 'Accessories', one: 'Accessory' }, c5: { glyph: 'bag', tab: 'Bags', one: 'Bag' },
    c9: { glyph: 'vest', tab: 'Vests', one: 'Vest' }, c10: { glyph: 'decal', tab: 'Decals', one: 'Decal' },
    p0: { glyph: 'hat', tab: 'Hats', one: 'Hat' }, p1: { glyph: 'glasses', tab: 'Glasses', one: 'Glasses' },
    p2: { glyph: 'ear', tab: 'Earrings', one: 'Earring' }, p6: { glyph: 'watch', tab: 'Watches', one: 'Watch' },
    p7: { glyph: 'bracelet', tab: 'Bracelets', one: 'Bracelet' },
    hair: { glyph: 'hair', tab: 'Cut', one: 'Cut' }, hairColor: { glyph: 'hair', tab: 'Hair Color', one: 'Hair Color' },
    fade: { glyph: 'fade', tab: 'Fade', one: 'Fade' }, beard: { glyph: 'beard', tab: 'Beard', one: 'Beard' },
    eyebrows: { glyph: 'brow', tab: 'Eyebrows', one: 'Eyebrow' }, chestHair: { glyph: 'chest', tab: 'Chest Hair', one: 'Hair' },
    makeup: { glyph: 'makeup', tab: 'Makeup', one: 'Makeup' }, blush: { glyph: 'makeup', tab: 'Blush', one: 'Blush' },
    lipstick: { glyph: 'lips', tab: 'Lipstick', one: 'Lipstick' },
    sex: { glyph: 'dna', tab: 'Sex', one: 'Sex' }, heritage: { glyph: 'dna', tab: 'Heritage', one: 'Heritage' },
    features: { glyph: 'face', tab: 'Features', one: 'Feature' }, eyes: { glyph: 'eye', tab: 'Eyes', one: 'Eyes' },
    skin: { glyph: 'skin', tab: 'Skin', one: 'Skin' },
    outfits: { glyph: 'jacket', tab: 'Company', one: 'Outfit' },
    head: { glyph: 'tattoo', tab: 'Head', one: 'Tattoo' }, torso: { glyph: 'tattoo', tab: 'Torso', one: 'Tattoo' },
    larm: { glyph: 'tattoo', tab: 'Left Arm', one: 'Tattoo' }, rarm: { glyph: 'tattoo', tab: 'Right Arm', one: 'Tattoo' },
    lleg: { glyph: 'tattoo', tab: 'Left Leg', one: 'Tattoo' }, rleg: { glyph: 'tattoo', tab: 'Right Leg', one: 'Tattoo' },
};
const meta = (g) => META[g.key] || { glyph: 'face', tab: g.label, one: g.label };

const CLUSTERS = [
    { id: 'face', label: 'Face' },
    { id: 'hair', label: 'Hair and Beard' },
    { id: 'makeup', label: 'Makeup' },
    { id: 'clothing', label: 'Clothing' },
    { id: 'accessories', label: 'Accessories' },
    { id: 'tattoos', label: 'Tattoos' },
    { id: 'wardrobe', label: 'Outfits' },
];
function clusterOf(g) {
    switch (g.ui.type) {
        case 'component': return 'clothing';
        case 'prop': return 'accessories';
        case 'tattoo': return 'tattoos';
        case 'outfits': return 'wardrobe';
        case 'hair': case 'hairColor': case 'fade': return 'hair';
        case 'overlay': return ['makeup', 'blush', 'lipstick'].includes(g.ui.name) ? 'makeup' : 'hair';
        default: return 'face';
    }
}

const SAME_WAY = new Set([0, 4, 7, 9, 13, 14, 16, 17, 18]);
const fsign = (i) => (SAME_WAY.has(i) ? 1 : -1);
const FEATURES = [
    { id: 'brow', label: 'Eyebrow', glyph: 'brow', x: { i: 7, l: 'Depth', neg: 'Inward', pos: 'Outward' }, y: { i: 6, l: 'Height', neg: 'Low', pos: 'High' } },
    { id: 'noseShape', label: 'Nose Shape', glyph: 'nose', x: { i: 0, l: 'Width', neg: 'Thin', pos: 'Wide' }, y: { i: 1, l: 'Height', neg: 'Low', pos: 'High' } },
    { id: 'noseProfile', label: 'Nose Profile', glyph: 'nose', x: { i: 2, l: 'Length', neg: 'Short', pos: 'Long' }, y: { i: 3, l: 'Bridge', neg: 'Low', pos: 'High' } },
    { id: 'noseTip', label: 'Nose Tip', glyph: 'nose', x: { i: 5, l: 'Twist', neg: 'Left', pos: 'Right' }, y: { i: 4, l: 'Tip', neg: 'Raised', pos: 'Lowered' } },
    { id: 'cheekbones', label: 'Cheekbones', glyph: 'cheek', x: { i: 9, l: 'Width', neg: 'Narrow', pos: 'Wide' }, y: { i: 8, l: 'Height', neg: 'Low', pos: 'High' } },
    { id: 'jaw', label: 'Jaw', glyph: 'jaw', x: { i: 13, l: 'Width', neg: 'Narrow', pos: 'Wide' }, y: { i: 14, l: 'Shape', neg: 'Round', pos: 'Square' } },
    { id: 'chinProfile', label: 'Chin Profile', glyph: 'chin', x: { i: 16, l: 'Length', neg: 'Short', pos: 'Long' }, y: { i: 15, l: 'Height', neg: 'Low', pos: 'High' } },
    { id: 'chinShape', label: 'Chin Shape', glyph: 'chin', x: { i: 17, l: 'Width', neg: 'Narrow', pos: 'Wide' }, y: { i: 18, l: 'Dimple', neg: 'Smooth', pos: 'Deep' } },
    { id: 'eyeOpen', label: 'Eyes', glyph: 'eye', x: { i: 11, l: 'Opening', neg: 'Squinted', pos: 'Wide open' } },
    { id: 'cheeks', label: 'Cheeks', glyph: 'cheek', x: { i: 10, l: 'Volume', neg: 'Thin', pos: 'Full' } },
    { id: 'lips', label: 'Lips', glyph: 'lips', x: { i: 12, l: 'Thickness', neg: 'Thin', pos: 'Thick' } },
    { id: 'neck', label: 'Neck', glyph: 'neck', x: { i: 19, l: 'Thickness', neg: 'Thin', pos: 'Thick' } },
];

const EYES = [
    ['Green', '#41694c'], ['Emerald', '#218352'], ['Light blue', '#67a3c1'], ['Ocean blue', '#2e5f8a'],
    ['Light brown', '#8a6845'], ['Dark brown', '#503c2b'], ['Hazel', '#7a6b3f'], ['Dark gray', '#555a5e'],
    ['Light gray', '#9aa2a6'], ['Pink', '#c97b9c'], ['Yellow', '#c9b25c'], ['Purple', '#6f4f8f'],
    ['Blackout', '#1b1b1b'], ['Grayscale', '#6e6e6e'], ['Tequila Sunrise', '#c56a2b'], ['Atomic', '#7fd12e'],
    ['Warp', '#c22fb0'], ['ECola', '#a01f1f'], ['Space Ranger', '#2fc2b8'], ['Yin-Yang', '#e8e8e8'],
    ['Target', '#b03030'], ['Lizard', '#77a02f'], ['Dragon', '#c2842f'], ['Extraterrestrial', '#8fb0b5'],
    ['Goat', '#c2b48f'], ['Smiley', '#e0d048'], ['Possessed', '#e8e0d0'], ['Demon', '#8a1010'],
    ['Infected', '#a0b048'], ['Alien', '#485ab0'], ['Undead', '#b0a890'], ['Zombie', '#606848'],
];

const SLOT_DIR = {
    component: { 0: '00_head', 1: '01_masks', 2: '02_hair', 3: '03_arms_gloves', 4: '04_pants', 5: '05_bags',
                 6: '06_shoes', 7: '07_accessories', 8: '08_undershirts', 9: '09_vests_armour', 10: '10_decals', 11: '11_tops' },
    prop: { 0: 'p0_hats', 1: 'p1_glasses', 2: 'p2_ears', 6: 'p6_watches', 7: 'p7_bracelets' },
};

function itemOf(kind, slot, drawable) {
    const icons = S.icons;
    if (!icons || drawable < 0) return '';
    const list = (icons[kind === 'prop' ? 'props' : 'components'] || {})[String(slot)];
    return (list && list[drawable]) || '';
}

function picName(kind, slot, item, tex) {
    const g = S.icons && S.icons.gender;
    if (!g || !item || !SLOT_DIR[kind][slot]) return null;
    const tag = kind === 'prop' ? 'prop' + slot : String(slot);
    return `${g}_${tag}_${item}_${String(Math.max(0, tex | 0)).padStart(2, '0')}`;
}

function picUrl(kind, slot, item, tex) {
    const name = picName(kind, slot, item, tex);
    if (!name || typeof window.whipAssetUrl !== 'function') return null;
    return window.whipAssetUrl(`img/clothing/${S.icons.gender}/${SLOT_DIR[kind][slot]}/${name}.webp`) || null;
}

function picRef(kind, slot, item, tex) {
    const url = picUrl(kind, slot, item, tex);
    const m = url && /^https:\/\/cfx-nui-([\w-]+)\/(img\/clothing\/.+\.webp)$/.exec(url);
    return m ? { res: m[1], path: m[2] } : null;
}

function nameOf(key) {
    const n = key && S.names && S.names[key];
    return typeof n === 'string' ? n : '';
}

let namesLoading = false;
function loadNames() {
    if (S.names || namesLoading) return;
    if (window.WHIP_EDITOR_NAMES) { S.names = window.WHIP_EDITOR_NAMES; return; }
    namesLoading = true;
    const s = document.createElement('script');
    s.src = CORE + 'js/editor-names.js';
    s.onload = () => {
        namesLoading = false;
        S.names = window.WHIP_EDITOR_NAMES || null;
        if (!S.open || !S.names) return;
        const key = S.focus && S.focus.dataset.key;
        renderTab(true);
        if (key) focusAfterRender(key);
    };
    s.onerror = () => { namesLoading = false; s.remove(); };
    document.head.appendChild(s);
}

const rangeCache = new Map();
function parseRanges(text) {
    const set = new Set();
    for (const part of String(text).split(',')) {
        const m = /^(\d+)(?:-(\d+))?$/.exec(part);
        if (!m) continue;
        const from = Number(m[1]), to = m[2] != null ? Number(m[2]) : from;
        for (let i = from; i <= to && i - from < 1000; i++) set.add(i);
    }
    return set;
}
function hasPicture(kind, slot, drawable) {
    const group = kind === 'prop' ? 'props' : 'components';
    const listed = S.pictures && S.pictures[group];
    if (!listed) return true;
    const m = /^(.+)_(\d{3})$/.exec(itemOf(kind, slot, drawable));
    if (!m || m[1] === 'base') return true;
    const bySlot = listed[String(slot)];
    if (!bySlot || !bySlot[m[1]]) return true;
    const key = `${S.icons.gender}:${group}:${slot}:${m[1]}`;
    if (!rangeCache.has(key)) rangeCache.set(key, parseRanges(bySlot[m[1]]));
    return rangeCache.get(key).has(Number(m[2]));
}

function iconImg(src) {
    if (!src) return '';
    return `<img class="es-icon" src="${esc(src)}" alt="" loading="lazy" decoding="async" draggable="false">`;
}
document.addEventListener('load', (e) => {
    const t = e.target;
    if (t && t.classList && t.classList.contains('es-icon') && t.parentElement) t.parentElement.classList.add('has-icon');
}, true);
document.addEventListener('error', (e) => {
    const t = e.target;
    if (t && t.classList && t.classList.contains('es-icon')) t.remove();
}, true);

let dirty = false, loopOn = false;
function changed() {
    dirty = true;
    if (loopOn) return;
    loopOn = true;
    requestAnimationFrame(tick);
}
async function tick() {
    if (!dirty || !S.open) { loopOn = false; return; }
    dirty = false;
    const res = await post('change', { look: S.look });
    if (res && res.quote) { S.quote = res.quote; renderBill(); markChanged(); }
    requestAnimationFrame(tick);
}

function visibleGroups() {
    const sexChanged = S.look && S.savedModel && S.look.model !== S.savedModel;

    return S.groups.filter((g) => (!g.sexOnly || sexChanged) && catOpen(g));
}
const groupByKey = (key) => S.groups.find((g) => g.key === key);

function clustersShown() {
    const vis = visibleGroups();
    return CLUSTERS.filter((c) => vis.some((g) => clusterOf(g) === c.id));
}

function changedKeys() {
    const keys = new Set();
    for (const l of S.quote.lines || []) { keys.add(l.key); if (l.group) keys.add(l.group); }
    return keys;
}

function renderGroups() {
    const box = $('es-groups');
    const cur = groupByKey(S.tab);
    const active = cur ? clusterOf(cur) : null;
    box.innerHTML = '';
    for (const c of clustersShown()) {
        const b = document.createElement('button');
        b.className = 'es-group' + (c.id === active ? ' active' : '');
        b.textContent = c.label;
        b.dataset.nav = 'group';
        b.dataset.key = 'group:' + c.id;
        b.onclick = () => {
            const first = visibleGroups().find((g) => clusterOf(g) === c.id);
            if (first) selectTab(first.key);
        };
        box.appendChild(b);
    }
}

function renderRail() {
    const box = $('es-rail');
    const cur = groupByKey(S.tab);
    const cl = cur ? clusterOf(cur) : null;
    const keys = changedKeys();
    box.innerHTML = '';
    for (const g of visibleGroups().filter((x) => clusterOf(x) === cl)) {
        const b = document.createElement('button');
        b.className = 'es-tab' + (g.key === S.tab ? ' active' : '') + (keys.has(g.key) ? ' changed' : '');
        b.textContent = meta(g).tab;

        const ct = catTarget(g);
        const c = S.adminMode && ct ? catOf(ct.kind, ct.slot) : null;
        if (c && (c.blocked || c.restricted)) b.appendChild(el(`<sup class="es-tab-tag">${c.blocked ? 'block' : 'restr'}</sup>`));
        b.dataset.nav = 'tab';
        b.dataset.key = 'tab:' + g.key;
        b.onclick = () => selectTab(g.key);
        box.appendChild(b);
    }
}

function markChanged() {
    const keys = changedKeys();
    document.querySelectorAll('#es-rail .es-tab').forEach((b) => {
        b.classList.toggle('changed', keys.has(b.dataset.key.slice(4)));
    });
}

function selectTab(key) {
    if (!groupByKey(key)) return;
    S.tab = key;
    post('frame', { cam: groupByKey(key).cam });
    renderGroups();
    renderRail();
    renderTab(false);
    focusAfterRender('tab:' + key);
}

function stepTab(dir) {
    const list = [];
    for (const c of clustersShown()) for (const g of visibleGroups()) if (clusterOf(g) === c.id) list.push(g.key);
    const i = list.indexOf(S.tab);
    if (list.length) selectTab(list[(i + dir + list.length) % list.length]);
}

function renderSubtabs(list, current, onPick) {
    const box = $('es-subtabs');
    box.innerHTML = '';
    for (const s of list || []) {
        const b = document.createElement('button');
        b.className = 'es-subtab' + (s.key === current ? ' active' : '');
        b.textContent = s.label;
        b.dataset.nav = 'subtab';
        b.dataset.key = 'sub:' + s.key;
        b.onclick = () => onPick(s.key);
        box.appendChild(b);
    }
}

function el(html) {
    const t = document.createElement('template');
    t.innerHTML = html.trim();
    return t.content.firstElementChild;
}

function bandTop({ hero, title, sub, meta: metaText, body, small }) {
    const top = el('<div class="es-band-top"></div>');
    if (hero) top.appendChild(hero);
    const main = el(`<div class="es-band-main${hero ? '' : ' short'}"></div>`);
    main.appendChild(el(`<div class="es-band-title${small ? ' small' : ''}">${esc(title)}</div>`));
    if (sub) main.appendChild(el(`<div class="es-band-sub">${esc(sub)}</div>`));
    if (body) {
        const b = el('<div class="es-band-body"></div>');
        b.appendChild(body);
        main.appendChild(b);
    }
    if (metaText) main.appendChild(el(`<div class="es-band-meta">${metaText}</div>`));
    top.appendChild(main);
    return top;
}

function heroOf({ img, glyph, swatch }) {
    const h = el(`<div class="es-hero">${swatch ? `<div class="es-hero-swatch" style="background:${swatch}"></div>` : ''}`
        + `<div class="es-hero-art">${GLYPH[glyph] || ''}</div>${iconImg(img)}</div>`);
    if (swatch) h.querySelector('.es-hero-art').style.visibility = 'hidden';
    return h;
}

function priceMeta(g) {
    if (g.sexOnly) return 'Included in the sex change';
    if (S.view.free || S.view.test || S.mode === 'builder') return 'On the house';
    return `<b>${money(g.price)}</b> if changed`;
}

function slider(label, value, min, max, step, onSet, fmt) {
    const wrap = el(`<div><div class="es-label"><span>${esc(label)}</span><span class="es-val"></span></div>`
        + `<input class="es-range" type="range" min="${min}" max="${max}" step="${step}" data-nav="range"></div>`);
    const input = wrap.querySelector('input');
    const val = wrap.querySelector('.es-val');
    input.value = value;
    input.dataset.key = 'range:' + label;
    val.textContent = fmt ? fmt(value) : value;
    input.addEventListener('input', () => {
        const v = Number(input.value);
        val.textContent = fmt ? fmt(v) : v;
        onSet(v);
    });
    return wrap;
}

function swatches(label, colors, value, onSet) {
    const wrap = el(`<div><div class="es-label"><span>${esc(label)}</span><span class="es-val">#${value}</span></div>`
        + '<div class="es-swatches"></div></div>');
    const grid = wrap.querySelector('.es-swatches');
    colors.forEach((c, i) => {
        const b = document.createElement('button');
        b.className = 'es-swatch' + (i === value ? ' selected' : '');
        b.style.background = `rgb(${c[0]},${c[1]},${c[2]})`;
        b.dataset.nav = 'swatch';
        b.dataset.key = `sw:${label}:${i}`;
        b.onclick = () => {
            grid.querySelectorAll('.selected').forEach((x) => x.classList.remove('selected'));
            b.classList.add('selected');
            wrap.querySelector('.es-val').textContent = '#' + i;
            onSet(i);
        };
        grid.appendChild(b);
    });
    return wrap;
}

async function textureCount(kind, slot, drawable) {
    const key = `${kind}:${slot}:${drawable}`;
    if (S.texCount[key] !== undefined) return S.texCount[key];
    const res = await post('textures', { kind, id: slot, drawable });
    const n = Math.max(0, Number(res && res.count) || 0);
    S.texCount[key] = n;
    return n;
}

function textureRow(kind, slot, drawable, current, onPick, check, onBlocked) {
    const row = el('<div class="es-texrow"></div>');
    textureCount(kind, slot, drawable).then((n) => {
        const item = itemOf(kind, slot, drawable);
        let first = null, shown = 0, currentOk = false;
        for (let t = 0; t < n; t++) {
            const c = check ? check(t) : { show: true, tag: null };
            if (!c.show) continue;
            shown++;
            if (first === null) first = t;
            if (t === current) currentOk = true;
            const b = el(`<button class="es-tex${t === current ? ' selected' : ''}" data-nav="tex">`
                + `<span class="es-tex-num">${t + 1}</span>${iconImg(picUrl(kind, slot, item, t))}`
                + (c.tag ? `<span class="es-tex-tag">${esc(c.tag)}</span>` : '') + '</button>');
            b.dataset.key = `tex:${t}`;
            b.onclick = () => onPick(t);
            row.appendChild(b);
        }
        const meta = row.closest('.es-band-main') && row.closest('.es-band-main').querySelector('.es-count');
        if (meta) meta.textContent = shown === 1 ? '1 color' : `${shown} colors`;
        if (!currentOk && n > 0 && onBlocked) onBlocked(first);
    });
    return row;
}

function renderTab(keepScroll) {
    const g = groupByKey(S.tab);
    const band = $('es-band');
    const grid = $('es-grid');
    const scroll = grid.scrollTop;
    band.innerHTML = '';
    grid.innerHTML = '';
    $('es-subtabs').innerHTML = '';
    if (!g || !S.look) return;
    const build = TABS[g.ui.type];
    if (build) build(g, band, grid);
    renderAdmin();
    if (keepScroll) grid.scrollTop = scroll;
    else scrollToSelected();
}

function scrollToSelected() {
    const sel = $('es-grid').querySelector('.es-card.selected');
    if (sel) sel.scrollIntoView({ block: 'center' });
}

function card({ value, label, name, img, glyph, swatch, big, selected, wide, badge, dim, onPick }) {
    const named = !!name;
    const b = el(`<button class="es-card${selected ? ' selected' : ''}${named ? ' named' : ''}${wide ? ' wide' : ''}${dim ? ' dim' : ''}" data-nav="card">`
        + (swatch ? `<div class="es-card-swatch" style="background:${swatch}"></div>` : '')
        + (big ? `<div class="es-card-big">${esc(big)}</div>` : `<div class="es-card-art">${GLYPH[glyph] || ''}</div>`)
        + iconImg(img)
        + (badge ? `<div class="es-card-badge">${esc(badge)}</div>` : '')
        + `<div class="es-card-num${named ? ' name' : ''}">${esc(name || label)}</div></button>`);
    b.dataset.value = value;
    b.dataset.key = 'card:' + value;
    b.onclick = () => onPick(value);
    return b;
}

function selectCard(grid, value) {
    grid.querySelectorAll('.es-card.selected').forEach((x) => x.classList.remove('selected'));
    const c = grid.querySelector(`.es-card[data-value="${CSS.escape(String(value))}"]`);
    if (c) c.classList.add('selected');
}

function refreshBand() {
    const g = groupByKey(S.tab);
    if (!g) return;
    const keep = S.focus && S.focus.dataset && S.focus.dataset.key;
    const band = $('es-band');
    band.innerHTML = '';
    const b = BANDS[g.ui.type];
    if (b) b(g, band);
    renderAdmin();
    if (keep && S.pad && !document.body.contains(S.focus)) focusAfterRender(keep);
}

function pieceState(g) {
    const t = g.ui.type;
    if (t === 'hair') return { kind: 'component', slot: 2, get: () => ({ d: S.look.hair.style | 0, t: S.look.hair.texture | 0 }),
        set: (d, x) => { S.look.hair.style = d; S.look.hair.texture = x; }, none: false, max: S.maxes.hair | 0 };
    const kind = t === 'prop' ? 'prop' : 'component';
    const k = String(g.ui.id);
    const store = kind === 'prop' ? S.look.props : S.look.components;
    return {
        kind, slot: g.ui.id, none: kind === 'prop',
        max: (kind === 'prop' ? S.maxes.props[k] : S.maxes.components[k]) | 0,
        get: () => { const v = store[k] || {}; return { d: v.drawable ?? (kind === 'prop' ? -1 : 0), t: v.texture | 0 }; },
        set: (d, x) => { store[k] = { drawable: d, texture: x }; },
    };
}

function collectionLabel(item) {
    if (!item) return '';
    const c = item.replace(/_\d{3}$/, '');
    return c === 'base' ? 'Base game' : c.replace(/_/g, ' ');
}

function pieceBand(g, band) {
    const p = pieceState(g);
    const { d, t } = p.get();
    const m = meta(g);
    if (d < 0) {
        band.appendChild(bandTop({ hero: heroOf({ glyph: 'none' }), title: 'None', sub: `No ${m.one.toLowerCase()}`, meta: priceMeta(g) }));
        return;
    }
    const item = itemOf(p.kind, p.slot, d);
    const name = nameOf(picName(p.kind, p.slot, item, t));
    const clothing = g.ui.type === 'component' || g.ui.type === 'prop';
    const pickTex = (x) => { p.set(d, x); changed(); refreshBand(); refreshCardPicture(g); };

    const onBlocked = (first) => {
        if (first !== null) pickTex(first);
        else if (dropNotAllowed()) { refreshBand(); selectCard($('es-grid'), p.get().d); }
    };
    const body = textureRow(p.kind, p.slot, d, t, pickTex, clothing ? (x) => texCheck(p, d, x) : null,
        clothing && !S.adminMode ? onBlocked : null);
    band.appendChild(bandTop({
        hero: heroOf({ img: picUrl(p.kind, p.slot, item, t), glyph: m.glyph }),
        title: `${m.one} ${d}`, sub: name || collectionLabel(item),
        body, meta: `<span class="es-count"></span> · ${priceMeta(g)}`,
    }));
}

function refreshCardPicture(g) {
    const p = pieceState(g);
    const { d, t } = p.get();
    const c = $('es-grid').querySelector(`.es-card[data-value="${d}"]`);
    if (!c || d < 0) return;
    const url = picUrl(p.kind, p.slot, itemOf(p.kind, p.slot, d), t);
    const img = c.querySelector('.es-icon');
    if (url && img) img.src = url;
}

function pieceTab(g, band, grid) {
    const p = pieceState(g);
    const m = meta(g);
    const cur = p.get().d;
    const openedD = (() => {
        const o = S.opened;
        if (!o) return null;
        if (g.ui.type === 'hair') return o.hair && o.hair.style;
        const store = p.kind === 'prop' ? o.props : o.components;
        const v = store && store[String(p.slot)];
        return v ? v.drawable : null;
    })();
    pieceBand(g, band);
    const clothing = g.ui.type !== 'hair';
    const frag = document.createDocumentFragment();
    const pick = (d) => {
        p.set(d, 0);
        changed();
        selectCard(grid, d);
        refreshBand();
        if (clothing && d >= 0) post('pick', { key: g.key });
    };
    if (p.none) frag.appendChild(card({ value: -1, label: 'None', glyph: 'none', selected: cur < 0, onPick: pick }));
    for (let d = 0; d < p.max; d++) {

        const mine = d === openedD || (d === cur && (S.adminMode || !clothing));
        if (!mine && d !== cur && !hasPicture(p.kind, p.slot, d)) continue;
        const item = itemOf(p.kind, p.slot, d);
        const name = nameOf(picName(p.kind, p.slot, item, 0));

        let badge = null, dim = false;
        {
            const rule = ruleOf(p.kind, p.slot, d);
            const sells = clothing ? sellsHere(rule, name, item) : true;
            if (S.adminMode) {
                badge = rule && rule.blocked ? 'Blocked' : rule && rule.exclusive ? 'Exclusive' : rule && rule.restricted ? 'Restricted' : null;
                if (!sells) { dim = true; badge = badge || (S.view && S.view.catalog ? 'Not in catalog' : 'Other brand'); }
            } else {
                if (!mine && ((rule && !rule.allowed) || !sells)) continue;
                if (rule && rule.restricted && rule.allowed) badge = 'Restricted';
            }
        }
        const tex = d === cur ? p.get().t : 0;
        frag.appendChild(card({
            value: d, label: `${m.one} ${d}`, name, badge, dim,
            img: picUrl(p.kind, p.slot, item, tex), glyph: m.glyph, selected: d === cur, onPick: pick,
        }));
    }
    grid.appendChild(frag);
}

function genderNow() {
    return (S.icons && S.icons.gender) || (S.look && S.look.model === FEMALE ? 'female' : 'male');
}

function setRules(list, categories) {
    S.rules = new Map((Array.isArray(list) ? list : []).map((r) => [r.key, r]));
    S.cats = new Map((Array.isArray(categories) ? categories : []).map((r) => [r.key, r]));
}

function ruleOf(kind, slot, d) {
    return S.rules ? S.rules.get(`${genderNow()}:${kind}:${slot}:${d}:-1`) || null : null;
}

function texRuleOf(kind, slot, d, t) {
    return S.rules ? S.rules.get(`${genderNow()}:${kind}:${slot}:${d}:${t}`) || null : null;
}

function catOf(kind, slot) {
    return S.cats ? S.cats.get(`${kind}:${slot}`) || null : null;
}

function catOpen(g) {
    const ct = catTarget(g);
    if (S.adminMode || !ct) return true;
    const c = catOf(ct.kind, ct.slot);

    return !c || c.allowed || !!(S.view && S.view.catalog && c.isDefault);
}

function catTarget(g) {
    if (!g) return null;
    if (g.ui.type === 'component' || g.ui.type === 'prop') return { kind: g.ui.type, slot: g.ui.id };
    if (g.ui.type === 'tattoo') return { kind: 'tattoo', slot: g.ui.index };
    if (g.ui.cat && !g.sexOnly) return { kind: g.ui.cat, slot: g.ui.catSlot };
    return null;
}

const escRe = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
let kwCache = null;

function autoBrands(name, item) {
    const cfg = S.brandCfg;
    if (!cfg || !cfg.styles) return null;
    if (!kwCache) {
        kwCache = Object.entries(cfg.keywords || {}).map(([style, words]) =>
            [style, (Array.isArray(words) ? words : []).map((w) => new RegExp('\\b' + escRe(String(w).toLowerCase())))]);
    }

    let style = null;
    if (name) {
        const n = String(name).toLowerCase();
        const order = Array.isArray(cfg.priority) && cfg.priority.length ? cfg.priority : kwCache.map(([s]) => s);
        for (const s of order) {
            const hit = kwCache.find(([k]) => k === s);
            if (hit && hit[1].some((re) => re.test(n))) { style = s; break; }
        }
    }
    if (!style && item && cfg.collections) {
        const coll = String(item).replace(/_\d{3}$/, '').toLowerCase();
        for (const [part, s] of Object.entries(cfg.collections)) if (coll.includes(part)) { style = s; break; }
    }
    const brands = style && cfg.styles[style];
    return Array.isArray(brands) && brands.length ? [...brands] : null;
}

const isCatalog = (b) => typeof b === 'string' && b.startsWith('c:');

function catalogNames() {
    const out = {};
    for (const c of (S.view && S.view.catalogs) || []) out[c.key] = c.label;
    return out;
}

function sellsHere(rule, name, item, texRule) {
    if (S.mode === 'builder') return true;
    const own = (texRule && Array.isArray(texRule.brands)) ? texRule.brands
        : (rule && Array.isArray(rule.brands)) ? rule.brands : null;
    if (S.view && S.view.catalog) return !!own && own.includes(S.brand);
    if (own && own.length && own.every(isCatalog)) return false;
    if (!S.brand) return true;
    const brands = own || autoBrands(name, item);
    return !brands || brands.includes(S.brand);
}

function pieceOk(kind, slot, d, t) {
    const c = catOf(kind, slot);
    if (c && !c.allowed && !(S.view && S.view.catalog && c.isDefault)) return false;
    const m = ruleOf(kind, slot, d);
    if (m && !m.allowed) return false;
    const r = t == null ? null : texRuleOf(kind, slot, d, t);
    if (r && !r.allowed) return false;
    const item = itemOf(kind, slot, d);
    return sellsHere(m, nameOf(picName(kind, slot, item, 0)), item, r);
}

function texCheck(p, d, t) {
    const r = texRuleOf(p.kind, p.slot, d, t);
    const m = ruleOf(p.kind, p.slot, d);
    const item = itemOf(p.kind, p.slot, d);
    const sells = sellsHere(m, nameOf(picName(p.kind, p.slot, item, 0)), item, r);
    if (S.adminMode) {
        const tag = r ? (r.blocked ? 'B' : r.exclusive ? 'E' : r.restricted ? 'R' : 'M') : (!sells ? '×' : null);
        return { show: true, tag };
    }
    return { show: (!r || r.allowed) && sells, tag: null };
}

const BRAND_KEYS = ['binco', 'suburban', 'ponsonbys', 'discount'];

function accessFrom(r) {
    r = r || {};
    return {
        access: r.blocked ? 'blocked' : r.restricted ? 'restrict' : 'all',
        jobs: Array.isArray(r.jobs) ? [...r.jobs] : [],
        chars: Array.isArray(r.chars) ? r.chars.join(', ') : '',
        onDuty: !!r.onDuty,
    };
}

function draftFrom(rule, key, label) {
    const r = rule || {};
    return Object.assign(accessFrom(r), {
        key,
        brands: Array.isArray(r.brands) ? [...r.brands] : null,
        exclusive: !!r.exclusive,
        exLabel: r.itemLabel || label,
        item: r.item || null,
    });
}

function accessRule(dr) {
    return {
        blocked: dr.access === 'blocked',
        jobs: dr.access === 'restrict' ? dr.jobs : [],
        chars: dr.access === 'restrict' ? String(dr.chars).split(/[^0-9]+/).filter(Boolean).map(Number) : [],
        onDuty: dr.access === 'restrict' && dr.onDuty,
    };
}

function chip(label, on, onClick, key) {
    const b = el(`<button class="es-subtab${on ? ' active' : ''}" data-nav="chip">${esc(label)}</button>`);
    b.dataset.key = 'chip:' + (key || label);
    b.onclick = onClick;
    return b;
}

function textInput(value, placeholder, onInput, key) {
    const i = el(`<input class="es-input" type="text" data-nav="input" placeholder="${esc(placeholder)}">`);
    i.value = value || '';
    i.dataset.key = 'input:' + key;
    i.addEventListener('input', () => onInput(i.value));
    i.addEventListener('focus', () => post('typing', { on: true }));
    i.addEventListener('blur', () => post('typing', { on: false }));
    return i;
}

function accessEditor(box, dr, prefix, label, redraw) {
    box.appendChild(el(`<div class="es-label"><span>${esc(label)}</span></div>`));
    const row = el('<div class="es-chips"></div>');
    row.appendChild(chip('Everyone', dr.access === 'all', () => { dr.access = 'all'; redraw(); }, prefix + 'acc:all'));
    row.appendChild(chip('Restricted', dr.access === 'restrict', () => { dr.access = 'restrict'; redraw(); }, prefix + 'acc:restrict'));
    row.appendChild(chip('Blocked', dr.access === 'blocked', () => { dr.access = 'blocked'; redraw(); }, prefix + 'acc:blocked'));
    box.appendChild(row);
    if (dr.access !== 'restrict') return;
    box.appendChild(el('<div class="es-note">Jobs and gangs (anyone working at any of them):</div>'));
    const jobRow = el('<div class="es-chips"></div>');
    for (const j of S.view.jobs || []) {
        const on = dr.jobs.includes(j.key);
        jobRow.appendChild(chip(j.name || j.key, on, () => {
            dr.jobs = on ? dr.jobs.filter((x) => x !== j.key) : [...dr.jobs, j.key];
            redraw();
        }, prefix + 'job:' + j.key));
    }
    if (!(S.view.jobs || []).length) jobRow.appendChild(el('<span class="es-note">No jobs created yet.</span>'));
    box.appendChild(jobRow);
    const duty = el('<div class="es-chips"></div>');
    duty.appendChild(chip('On duty only', dr.onDuty, () => { dr.onDuty = !dr.onDuty; redraw(); }, prefix + 'duty'));
    box.appendChild(duty);
    box.appendChild(el('<div class="es-note">Characters (character IDs, comma separated):</div>'));
    box.appendChild(textInput(dr.chars, 'e.g. 12, 45', (v) => { dr.chars = v; }, prefix + 'chars'));
}

function adminButtons(box, saveLabel, onSave, clearLabel, canClear, onClear, key) {
    const act = el('<div class="es-chips es-admin-actions"></div>');
    const save = el(`<button class="es-btn primary" data-nav="btn">${esc(saveLabel)}</button>`);
    save.dataset.key = 'btn:' + key + 'save';
    save.onclick = onSave;
    const clear = el(`<button class="es-btn" data-nav="btn">${esc(clearLabel)}</button>`);
    clear.dataset.key = 'btn:' + key + 'clear';
    clear.disabled = !canClear;
    clear.onclick = onClear;
    act.append(save, clear);
    box.appendChild(act);
}

function ruleSummary(r) {
    if (!r) return null;
    if (r.blocked) return 'blocked';
    if (r.exclusive) return 'exclusive item';
    if (r.restricted) return 'restricted';
    if (Array.isArray(r.brands)) return 'chosen brands';
    return 'rule saved';
}

function renderAdmin() {
    const box = $('es-admin');
    box.innerHTML = '';
    const g = groupByKey(S.tab);
    const piece = g && (g.ui.type === 'component' || g.ui.type === 'prop' || g.ui.type === 'hair');
    if (S.adminMode && g && g.ui.type === 'tattoo') { tattooAdmin(box, g); return; }
    if (g && g.ui.type === 'outfits') { wardrobeAdmin(box); return; }
    const ct = catTarget(g);
    if (!S.adminMode || !ct) { box.classList.add('hidden'); return; }
    box.classList.remove('hidden');
    const hair = g.ui.type === 'hair';
    const p = piece ? pieceState(g) : null;
    const { d, t } = p ? p.get() : { d: -1, t: 0 };
    const m = meta(g);
    const redraw = () => { const k = S.focus && S.focus.dataset.key; renderAdmin(); if (k) focusAfterRender(k); };
    if (d < 0 && S.adminOpen === 'piece') S.adminOpen = null;
    box.classList.toggle('open', !!S.adminOpen);

    const c = catOf(ct.kind, ct.slot);
    const catStatus = !c ? 'free' : c.blocked ? 'blocked' : c.restricted ? 'restricted' : 'open';
    const modelRule = p && d >= 0 ? ruleOf(p.kind, p.slot, d) : null;
    const colorRule = p && d >= 0 && !hair ? texRuleOf(p.kind, p.slot, d, t) : null;
    const pieceStatus = ruleSummary(colorRule) ? `color ${t + 1} ${ruleSummary(colorRule)}` : (ruleSummary(modelRule) || 'no rule');

    const bar = el('<div class="es-admin-bar"><span class="es-admin-title">Admin</span></div>');
    const toggle = (label, which) => chip(label, S.adminOpen === which,
        () => { S.adminOpen = S.adminOpen === which ? null : which; redraw(); }, 'open:' + which);
    bar.appendChild(toggle(`${m.tab}: ${catStatus}${c && c.isDefault ? ' (default)' : ''}`, 'cat'));
    if (p && d >= 0) bar.appendChild(toggle(`${m.one} ${d}: ${pieceStatus}`, 'piece'));
    bar.appendChild(el(`<span class="es-admin-hint">${S.adminOpen ? 'click again to collapse' : 'click to edit'}</span>`));
    box.appendChild(bar);

    if (S.adminOpen === 'cat') {

        const ck = `${ct.kind}:${ct.slot}`;
        if (!S.catDraft || S.catDraft.key !== ck) S.catDraft = Object.assign(accessFrom(c), { key: ck });
        const status = !c ? 'free' : c.isDefault ? 'config default' : 'rule saved';
        box.appendChild(el(`<div class="es-admin-head"><span>Category</span><b>${esc(m.tab)}</b><em>${status} · both bodies</em></div>`));
        accessEditor(box, S.catDraft, 'cat:', ct.kind === 'component' || ct.kind === 'prop' ? 'Who can buy this category' : 'Who can change this here', redraw);
        adminButtons(box, 'Save category', () => adminCategorySave(false), 'Back to default', !!(c && c.saved),
            () => adminCategorySave(true), 'cat');
        return;
    }
    if (S.adminOpen !== 'piece' || !p) return;

    const texScope = !hair && S.scope === 'texture';
    const item = itemOf(p.kind, p.slot, d);
    const name = nameOf(picName(p.kind, p.slot, item, texScope ? t : 0));
    const rule = texScope ? colorRule : modelRule;
    const key = `${genderNow()}:${p.kind}:${p.slot}:${d}:${texScope ? t : -1}`;
    if (!S.draft || S.draft.key !== key) S.draft = draftFrom(rule, key, name || `${m.one} ${d}`);
    const dr = S.draft;

    box.appendChild(el(`<div class="es-admin-head"><span>Piece</span><b>${esc(m.one)} ${d}${texScope ? ` · color ${t + 1}` : ''}</b>`
        + `<em>${genderNow() === 'female' ? 'female body' : 'male body'}${rule ? ' · has a rule' : ''}</em></div>`));
    if (hair) {
        accessEditor(box, dr, 'piece:', 'Who can get this haircut', redraw);
        adminButtons(box, 'Save haircut rule', () => adminSave(false), 'Remove rule', !!rule, () => adminSave(true), 'piece');
        return;
    }
    const scopeRow = el('<div class="es-chips"></div>');
    scopeRow.appendChild(chip('Whole model (all colors)', !texScope, () => { S.scope = 'model'; S.draft = null; redraw(); }, 'scope:model'));
    scopeRow.appendChild(chip(`Only color ${t + 1}`, texScope, () => { S.scope = 'texture'; S.draft = null; redraw(); }, 'scope:texture'));
    box.appendChild(scopeRow);
    if (texScope) {
        box.appendChild(el('<div class="es-note">Change the color in the band above to set up another one. The model\'s rule '
            + 'also applies: the color must pass both.</div>'));
    }

    const auto = autoBrands(name, item);
    const names = Object.assign({}, (S.brandCfg && S.brandCfg.names) || {}, catalogNames());
    box.appendChild(el(`<div class="es-label"><span>Brands that sell it</span><span class="es-val">${
        dr.brands ? 'picked' : (texScope ? 'the model\'s' : 'automatic: ' + esc(auto ? auto.map((b) => names[b] || b).join(', ') : 'all'))}</span></div>`));
    const brandRow = el('<div class="es-chips"></div>');
    brandRow.appendChild(chip(texScope ? 'Same as model' : 'Automatic', !dr.brands, () => { dr.brands = null; redraw(); }, 'auto'));
    for (const b of [...BRAND_KEYS, ...Object.keys(catalogNames())]) {
        const on = dr.brands ? dr.brands.includes(b) : false;
        brandRow.appendChild(chip(names[b] || b, on, () => {
            const cur = dr.brands ? [...dr.brands] : [];
            dr.brands = on ? cur.filter((x) => x !== b) : [...cur, b];
            redraw();
        }, 'brand:' + b));
    }
    box.appendChild(brandRow);
    if (Object.keys(catalogNames()).length) {
        box.appendChild(el('<div class="es-note">Own catalogs (custom stores): a piece marked only with them leaves '
            + 'the regular stores. Also mark the brands to sell it in both.</div>'));
    }

    accessEditor(box, dr, 'piece:', texScope ? 'Who can buy this color' : 'Who can buy this model', redraw);

    box.appendChild(el('<div class="es-label"><span>Exclusive item</span>'
        + (dr.item ? `<span class="es-val">${esc(dr.item)}</span>` : '') + '</div>'));
    const exRow = el('<div class="es-chips"></div>');
    exRow.appendChild(chip(dr.exclusive ? 'Is an exclusive item' : 'Make it an exclusive item', dr.exclusive,
        () => { dr.exclusive = !dr.exclusive; redraw(); }, 'excl'));
    if (dr.item) exRow.appendChild(chip('Give me 1', false, () => post('adminGive', { item: dr.item }), 'give'));
    box.appendChild(exRow);
    if (dr.exclusive) {
        box.appendChild(textInput(dr.exLabel, 'Item name', (v) => { dr.exLabel = v; }, 'exlabel'));
        box.appendChild(el(`<div class="es-note">${texScope ? `Only color ${t + 1} leaves the store` : 'The model leaves the store (all colors)'}. `
            + `Whoever uses the item wears this piece in color ${t + 1}, and the item's picture is this color's. The item stays in the inventory; `
            + '"Take the piece off" in its menu removes it.</div>'));
    }

    adminButtons(box, texScope ? 'Save color rule' : 'Save model rule', () => adminSave(false),
        'Remove rule', !!rule, () => adminSave(true), 'piece');
}

async function adminSave(clear) {
    const g = groupByKey(S.tab);
    if (!g || !S.draft) return;
    const p = pieceState(g);
    const { d, t } = p.get();
    const dr = S.draft;
    const hair = g.ui.type === 'hair';
    const texScope = !hair && S.scope === 'texture';
    const name = nameOf(picName(p.kind, p.slot, itemOf(p.kind, p.slot, d), texScope ? t : 0));

    const rule = clear ? { brands: null } : hair ? accessRule(dr) : Object.assign(accessRule(dr), {
        brands: dr.brands,
        exclusive: dr.exclusive ? { label: dr.exLabel, texture: t, picture: picRef(p.kind, p.slot, itemOf(p.kind, p.slot, d), t) } : null,
    });
    const res = await post('adminSave', {
        piece: { gender: genderNow(), kind: p.kind, slot: p.slot, drawable: d, texture: texScope ? t : -1,
                 label: name || `${meta(g).one} ${d}` },
        rule,
    });
    if (res && res.ok) {
        setRules(res.rules, res.categories);
        S.draft = null;
        renderTab(true);
    }
}

async function adminCategorySave(reset) {
    const g = groupByKey(S.tab);
    const ct = catTarget(g);
    if (!ct || !S.catDraft) return;
    const res = await post('adminCategory', {
        category: { kind: ct.kind, slot: ct.slot },
        rule: reset ? { reset: true } : accessRule(S.catDraft),
    });
    if (res && res.ok) {
        setRules(res.rules, res.categories);
        S.catDraft = null;
        renderRail();
        renderTab(true);
    }
}

function dropNotAllowed() {
    if (!S.look || !S.opened) return false;
    if (S.view && S.view.kind === 'tattoo') return dropTattoosNotAllowed();
    let dropped = false;
    for (const g of S.groups) {
        if (g.ui.type === 'hair') {
            const style = S.look.hair.style | 0;
            const was = S.opened.hair ? S.opened.hair.style | 0 : style;
            const r = ruleOf('component', 2, style);
            if (style !== was && r && !r.allowed) {
                S.look.hair.style = was;
                S.look.hair.texture = S.opened.hair ? S.opened.hair.texture | 0 : 0;
                dropped = true;
            }
            continue;
        }
        if (g.ui.type !== 'component' && g.ui.type !== 'prop') continue;
        const p = pieceState(g);
        const { d, t } = p.get();
        const store = p.kind === 'prop' ? S.opened.props : S.opened.components;
        const was = (store && store[String(p.slot)]) || { drawable: p.kind === 'prop' ? -1 : 0, texture: 0 };
        if (d < 0 || (d === was.drawable && t === (was.texture | 0))) continue;
        if (!pieceOk(p.kind, p.slot, d, t)) {
            p.set(was.drawable, was.texture | 0);
            dropped = true;
        }
    }
    if (dropped) changed();
    return dropped;
}

function setAdminMode(on) {
    S.adminMode = !!on && !!(S.view && S.view.admin);
    S.draft = null;
    S.catDraft = null;
    S.adminOpen = null;
    S.tatSel = new Set();
    S.tatDraft = null;
    if (!S.adminMode) dropNotAllowed();
    const t = $('es-admin-toggle');
    t.classList.toggle('hidden', !(S.view && S.view.admin));
    t.classList.toggle('active', S.adminMode);
    if (!S.open) return;

    if (!visibleGroups().some((g) => g.key === S.tab)) {
        S.tab = (visibleGroups()[0] || {}).key;
        if (S.tab) post('frame', { cam: groupByKey(S.tab).cam });
    }
    renderGroups();
    renderRail();
    renderTab(true);
}
$('es-admin-toggle').onclick = () => setAdminMode(!S.adminMode);

function hairColorBand(g, band) {
    const c = S.palettes.hair[S.look.hair.color | 0] || [0, 0, 0];
    const body = el('<div class="es-cols"></div>');
    const a = el('<div class="es-col"></div>');
    const b = el('<div class="es-col"></div>');
    a.appendChild(swatches('Color', S.palettes.hair, S.look.hair.color | 0, (i) => { S.look.hair.color = i; changed(); refreshHero(); }));
    b.appendChild(swatches('Highlights', S.palettes.hair, S.look.hair.highlight | 0, (i) => { S.look.hair.highlight = i; changed(); }));
    body.append(a, b);
    band.appendChild(bandTop({ hero: heroOf({ swatch: `rgb(${c.join(',')})`, glyph: 'hair' }), title: 'Hair Color',
        sub: 'The color of the hair and highlights', meta: priceMeta(g) }));
    const wide = el('<div class="es-band-wide"></div>');
    wide.appendChild(body);
    band.appendChild(wide);
    function refreshHero() {
        const n = S.palettes.hair[S.look.hair.color | 0] || [0, 0, 0];
        const sw = band.querySelector('.es-hero-swatch');
        if (sw) sw.style.background = `rgb(${n.join(',')})`;
    }
}

function fadeIndex() {
    const f = S.look.hairFade;
    if (!f) return -1;
    return S.fades.findIndex((x) => x.collection === f.collection && x.overlay === f.overlay);
}
function fadeBand(g, band) {
    const i = fadeIndex();
    band.appendChild(bandTop({ hero: null, small: true, title: i < 0 ? 'No fade' : `Fade ${i + 1}`,
        sub: 'The shaved part under the cut. Some only show with short hair.', meta: priceMeta(g) }));
}
function fadeTab(g, band, grid) {
    fadeBand(g, band);
    const cur = fadeIndex();
    const pick = (v) => {
        S.look.hairFade = v < 0 ? null : { collection: S.fades[v].collection, overlay: S.fades[v].overlay };
        changed();
        selectCard(grid, v);
        refreshBand();
    };
    grid.appendChild(card({ value: -1, label: 'None', glyph: 'none', selected: cur < 0, onPick: pick }));
    S.fades.forEach((f, i) => grid.appendChild(card({ value: i, label: `Fade ${i + 1}`, glyph: 'fade', selected: i === cur, onPick: pick })));
}

function overlayOn(o) { return o && !(Number(o.opacity) === 0 || o.type === 255); }

function overlayBand(g, band, name, id, colorType, label) {
    const o = S.look.overlays[name] || (S.look.overlays[name] = { type: 0, opacity: 0 });
    if (!overlayOn(o)) {
        band.appendChild(bandTop({ hero: null, small: true, title: `${label}: none`, sub: 'Pick a style below.', meta: priceMeta(g) }));
        return;
    }
    const body = el('<div></div>');
    body.appendChild(slider('Intensity', o.opacity, 0.05, 1, 0.05, (v) => { o.opacity = v; changed(); }, (v) => `${Math.round(v * 100)}%`));
    if (colorType) {
        const pal = colorType === 1 ? S.palettes.hair : S.palettes.makeup;
        body.appendChild(swatches('Color', pal, o.color | 0, (i) => { o.color = i; o.color2 = i; changed(); }));
    }
    band.appendChild(bandTop({ hero: null, small: true, title: `${label} ${o.type}`,
        sub: nameOf(`overlay_${id}_${o.type}`), meta: priceMeta(g) }));
    const wide = el('<div class="es-band-wide"></div>');
    wide.appendChild(body);
    band.appendChild(wide);
}

function overlayGrid(g, grid, name, id, label, after) {
    const o = S.look.overlays[name] || (S.look.overlays[name] = { type: 0, opacity: 0 });
    const num = (S.maxes.overlays && S.maxes.overlays[name]) | 0;
    const glyph = (META[name] && META[name].glyph) || 'skin';
    const cur = overlayOn(o) ? o.type : -1;
    const pick = (v) => {
        if (v < 0) { o.type = 0; o.opacity = 0; } else { o.type = v; if (!Number(o.opacity)) o.opacity = 1; }
        changed();
        selectCard(grid, v);
        after();
    };
    grid.appendChild(card({ value: -1, label: 'None', glyph: 'none', selected: cur < 0, onPick: pick }));
    for (let v = 0; v < num; v++) {
        grid.appendChild(card({ value: v, label: `${label} ${v}`, name: nameOf(`overlay_${id}_${v}`), glyph, selected: v === cur, onPick: pick }));
    }
}

function overlayTab(g, band, grid) {
    const label = meta(g).one;
    overlayBand(g, band, g.ui.name, g.ui.id, g.ui.colorType, label);
    overlayGrid(g, grid, g.ui.name, g.ui.id, label, refreshBand);
}

function skinCurrent(g) {
    const list = g.ui.list;
    return list.find((o) => o.name === S.sub[g.key]) || list[0];
}
function skinBand(g, band) {
    const o = skinCurrent(g);
    overlayBand(g, band, o.name, o.id, null, o.label);
}
function skinTab(g, band, grid) {
    const o = skinCurrent(g);
    renderSubtabs(g.ui.list.map((x) => ({ key: x.name, label: x.label })), o.name, (k) => { S.sub[g.key] = k; renderTab(false); focusAfterRender('sub:' + k); });
    skinBand(g, band);
    overlayGrid(g, grid, o.name, o.id, o.label, refreshBand);
}

const PARENTS = 46;
function heritageWho(g) { return S.sub[g.key] === 'dad' ? 'dad' : 'mom'; }
function parentPic(n) { return picUrl('component', 0, 'base_' + String(n).padStart(3, '0'), 0); }

function heritageBand(g, band) {
    const hb = S.look.headBlend;
    const who = heritageWho(g);
    const n = hb[who] | 0;
    const body = el('<div></div>');
    body.appendChild(slider('Resemblance (mother ← → father)', hb.faceWeight, 0, 1, 0.01, (v) => { hb.faceWeight = v; changed(); }, (v) => Math.round(v * 100)));
    body.appendChild(slider('Skin tone (mother ← → father)', hb.skinWeight, 0, 1, 0.01, (v) => { hb.skinWeight = v; changed(); }, (v) => Math.round(v * 100)));
    band.appendChild(bandTop({
        hero: heroOf({ img: parentPic(n), glyph: 'face' }),
        title: `${who === 'dad' ? 'Father' : 'Mother'} ${n}`, sub: nameOf('parent_' + n), body, meta: priceMeta(g),
    }));
}

function heritageTab(g, band, grid) {
    const who = heritageWho(g);
    renderSubtabs([{ key: 'mom', label: 'Mother' }, { key: 'dad', label: 'Father' }], who, (k) => { S.sub[g.key] = k; renderTab(false); focusAfterRender('sub:' + k); });
    heritageBand(g, band);
    const cur = S.look.headBlend[who] | 0;
    const pick = (v) => { S.look.headBlend[who] = v; changed(); selectCard(grid, v); refreshBand(); };
    for (let n = 0; n < PARENTS; n++) {
        grid.appendChild(card({ value: n, label: String(n), name: nameOf('parent_' + n), img: parentPic(n), glyph: 'face', selected: n === cur, onPick: pick }));
    }
}

function featureBand(g, band) {
    const f = FEATURES.find((x) => x.id === S.feature) || FEATURES[0];
    const ff = S.look.faceFeatures;
    const shown = (ax) => fsign(ax.i) * (Number(ff[ax.i]) || 0);
    const setAx = (ax, v) => { ff[ax.i] = clamp(fsign(ax.i) * v, -1, 1); };
    const sliders = el('<div></div>');
    const axes = f.y ? [f.x, f.y] : [f.x];
    for (const ax of axes) {
        sliders.appendChild(slider(`${ax.l} (${ax.neg} ← → ${ax.pos})`, shown(ax), -1, 1, 0.02, (v) => { setAx(ax, v); changed(); movePadDot(); },
            (v) => (v > 0 ? '+' : '') + Math.round(v * 100)));
    }
    let padBox = null;
    if (f.y) {
        padBox = el(`<div class="es-padwrap"><div class="es-pad">
            <svg viewBox="0 0 100 100"><line x1="33.3" y1="-4" x2="33.3" y2="104"/><line x1="66.6" y1="-4" x2="66.6" y2="104"/>
            <line x1="-4" y1="33.3" x2="104" y2="33.3"/><line x1="-4" y1="66.6" x2="104" y2="66.6"/></svg>
            <span class="es-pad-axis es-pad-n">${esc(f.y.pos)}</span><span class="es-pad-axis es-pad-s">${esc(f.y.neg)}</span>
            <span class="es-pad-axis es-pad-w">${esc(f.x.neg)}</span><span class="es-pad-axis es-pad-e">${esc(f.x.pos)}</span>
            <div class="es-pad-dot"></div></div></div>`);
        const pad = padBox.querySelector('.es-pad');
        let drag = false;
        const apply = (ev) => {
            const r = pad.getBoundingClientRect();
            const x = clamp(((ev.clientX - r.left) / r.width) * 2 - 1, -1, 1);
            const y = clamp(1 - ((ev.clientY - r.top) / r.height) * 2, -1, 1);
            setAx(f.x, x);
            setAx(f.y, y);
            changed();
            movePadDot();

            const ins = sliders.querySelectorAll('input'), vals = sliders.querySelectorAll('.es-val');
            [f.x, f.y].forEach((ax, i) => {
                ins[i].value = shown(ax);
                vals[i].textContent = (shown(ax) > 0 ? '+' : '') + Math.round(shown(ax) * 100);
            });
        };
        pad.addEventListener('pointerdown', (ev) => { drag = true; pad.setPointerCapture(ev.pointerId); apply(ev); });
        pad.addEventListener('pointermove', (ev) => { if (drag) apply(ev); });
        pad.addEventListener('pointerup', () => { drag = false; });
    }
    function movePadDot() {
        if (!padBox) return;
        const dot = padBox.querySelector('.es-pad-dot');
        dot.style.left = ((shown(f.x) + 1) / 2 * 100) + '%';
        dot.style.top = ((1 - shown(f.y)) / 2 * 100) + '%';
    }
    let body;
    if (padBox) {
        body = el('<div class="es-cols"></div>');
        const a = el('<div class="es-col"></div>'), b = el('<div class="es-col"></div>');
        a.appendChild(padBox); b.appendChild(sliders);
        body.append(a, b);
    } else {
        body = sliders;
    }
    band.appendChild(bandTop({ hero: null, small: true, title: f.label, sub: 'Drag the dot or use the sliders.', meta: priceMeta(g) }));
    const wide = el('<div class="es-band-wide"></div>');
    wide.appendChild(body);
    band.appendChild(wide);
    movePadDot();
}

function featuresTab(g, band, grid) {
    featureBand(g, band);
    const pick = (v) => { S.feature = v; selectCard(grid, v); refreshBand(); };
    for (const f of FEATURES) grid.appendChild(card({ value: f.id, label: f.label, glyph: f.glyph, selected: f.id === S.feature, onPick: pick }));
}

function eyesBand(g, band) {
    const e = EYES[S.look.eyeColor | 0] || EYES[0];
    band.appendChild(bandTop({ hero: null, small: true, title: `Eyes: ${e[0]}`, sub: 'The card color is approximate; check it on the character.', meta: priceMeta(g) }));
}
function eyesTab(g, band, grid) {
    eyesBand(g, band);
    const pick = (v) => { S.look.eyeColor = v; changed(); selectCard(grid, v); refreshBand(); };
    EYES.forEach((e, i) => grid.appendChild(card({ value: i, label: e[0], swatch: e[1], selected: i === (S.look.eyeColor | 0), onPick: pick })));
}

const tatKey = (t) => (t && typeof t.collection === 'string' && typeof t.overlay === 'string')
    ? (t.collection + '/' + t.overlay).toLowerCase() : null;

function setTattooList(list) {
    S.tattooList = list || null;
    S.tatIndex = new Map();
    for (const [zone, arr] of Object.entries(S.tattooList || {})) {
        (Array.isArray(arr) ? arr : []).forEach((t, i) => S.tatIndex.set(t.key, { t, zone, i }));
    }
}
function setTatRules(list) {
    S.tatRules = new Map((Array.isArray(list) ? list : []).map((r) => [r.key, r]));
}
const tatRule = (key) => (S.tatRules && S.tatRules.get(key)) || null;
const tatList = (g) => (S.tattooList && Array.isArray(S.tattooList[g.ui.zone]) ? S.tattooList[g.ui.zone] : []);
const tatOnSet = () => new Set((S.look.tattoos || []).map(tatKey).filter(Boolean));
const tatHadSet = () => new Set(((S.opened && S.opened.tattoos) || []).map(tatKey).filter(Boolean));
const tatName = (t, i) => t.name || `Tattoo ${i + 1}`;
const TAT_ZONE_INDEX = { head: 1, torso: 2, larm: 3, rarm: 4, lleg: 5, rleg: 6 };
const TAT_MAX = 40;

function tatPic(t) {
    if (!t || typeof window.whipAssetUrl !== 'function') return null;
    return window.whipAssetUrl('img/tattoos/' + String(t.overlay).toLowerCase() + '.webp') || null;
}

function tatPrice(g, key) {
    const r = tatRule(key);
    return r && typeof r.price === 'number' ? r.price : (g.price | 0);
}

function tatOk(key, zone) {
    const c = catOf('tattoo', TAT_ZONE_INDEX[zone]);
    if (c && !c.allowed) return false;
    const r = tatRule(key);
    return !r || r.allowed !== false;
}

const TAT_SIDE = { front: 0, chest: 0, stomach: 0, back: 180, left: -90, right: 90, frontleft: -45, frontright: 45 };
function tatAngle(zone, facing) {
    if (zone === 'head' || zone === 'torso') return TAT_SIDE[facing] ?? 0;
    const base = zone[0] === 'l' ? -90 : 90;
    if (facing === 'front') return base / 2;
    if (facing === 'back') return base * 1.5;
    if (facing === 'left' || facing === 'right') return TAT_SIDE[facing];
    return zone.endsWith('leg') ? base / 3 : base;
}

function faceTattoo(zone, t) {
    post('faceSide', { deg: tatAngle(zone, t ? t.facing : '') });
}

const VIEW_LABEL = { clothes: 'Hide clothes', head: 'Remove head props', torso: 'Hide clothes' };

async function setView(key, on) {
    const res = await post('view', { key, on });
    S.hide = res && res.hide && typeof res.hide === 'object' ? res.hide : { ...S.hide, [key]: on };
    renderView();
    focusAfterRender('chip:view:' + key);
}

function renderView() {
    const box = $('es-view');
    box.innerHTML = '';
    const views = Array.isArray(S.views) ? S.views : [];
    for (const key of views) {
        box.appendChild(chip(VIEW_LABEL[key] || key, !!(S.hide && S.hide[key]), () => setView(key, !(S.hide && S.hide[key])), 'view:' + key));
    }
    box.classList.toggle('hidden', views.length === 0);
}

const FACING_LABEL = { front: 'Front', back: 'Back', left: 'Left side', right: 'Right side', frontleft: 'Front, left',
    frontright: 'Front, right', chest: 'Chest', stomach: 'Stomach' };

function tattooBand(g, band) {
    const list = tatList(g);
    const on = tatOnSet();
    const had = tatHadSet();
    const inZone = list.filter((t) => on.has(t.key)).length;
    const total = on.size;
    const focus = S.tatFocus && S.tatIndex && S.tatIndex.get(S.tatFocus);
    const removal = S.removePrice | 0;
    const freeNow = free();

    const tools = el('<div class="es-chips es-tat-tools"></div>');
    if (inZone > 0 && !S.adminMode) {
        tools.appendChild(chip('Remove all from this part', false, () => {
            const keys = new Set(list.map((t) => t.key));
            S.look.tattoos = S.look.tattoos.filter((t) => !keys.has(tatKey(t)));
            changed();
            renderTab(true);
        }, 'clearzone'));
    }

    const counts = `${inZone} on this part · ${total} of ${TAT_MAX} on the body`;
    if (focus && focus.zone === g.ui.zone) {
        const t = focus.t;
        const isOn = on.has(t.key), wasOn = had.has(t.key);
        let state;
        if (freeNow) state = isOn ? 'On the body' : 'On the house';
        else if (isOn && wasOn) state = `You already have it · remove: <b>${money(removal)}</b>`;
        else if (isOn) state = `New · <b>${money(tatPrice(g, t.key))}</b>`;
        else if (wasOn) state = `Removed · <b>${money(removal)}</b>`;
        else state = `<b>${money(tatPrice(g, t.key))}</b> to get`;
        band.appendChild(bandTop({
            hero: heroOf({ img: tatPic(t), glyph: 'tattoo' }),
            title: tatName(t, focus.i), sub: [FACING_LABEL[t.facing], counts].filter(Boolean).join(' · '),
            body: tools, meta: state,
        }));
        return;
    }
    band.appendChild(bandTop({
        hero: heroOf({ glyph: 'tattoo' }), title: `Tattoos: ${meta(g).tab}`, sub: counts, body: tools,
        meta: freeNow ? 'On the house' : `Each one from <b>${money(g.price)}</b> · removal <b>${money(removal)}</b>`,
    }));
}

function tattooTab(g, band, grid) {
    const sub = S.sub[g.key] === 'mine' ? 'mine' : 'all';
    const list = tatList(g);
    const on = tatOnSet();
    const had = tatHadSet();
    const mineCount = list.filter((t) => on.has(t.key) || had.has(t.key)).length;
    renderSubtabs([{ key: 'all', label: 'Catalog' }, { key: 'mine', label: `On the body (${mineCount})` }], sub,
        (k) => { S.sub[g.key] = k; renderTab(false); focusAfterRender('sub:' + k); });
    tattooBand(g, band);
    if (!S.tattooList) {
        grid.appendChild(el('<div class="es-note">The tattoos did not load (only on the game\'s character bodies).</div>'));
        return;
    }
    const frag = document.createDocumentFragment();
    let shown = 0;
    list.forEach((t, i) => {
        const isOn = on.has(t.key), wasOn = had.has(t.key);
        if (sub === 'mine' && !isOn && !wasOn) return;
        const r = tatRule(t.key);
        let badge = null, dim = false;
        if (S.adminMode) {
            badge = r && r.blocked ? 'Blocked' : r && r.restricted ? 'Restricted' : null;
            dim = !!(r && r.blocked);
        } else {

            if (!isOn && !wasOn && !tatOk(t.key, g.ui.zone)) return;
            if (r && r.restricted) badge = 'Restricted';
            if (wasOn && !isOn) badge = 'Removed';
        }
        shown++;
        const c = card({ value: t.key, label: tatName(t, i), name: tatName(t, i), img: tatPic(t), glyph: 'tattoo',
            selected: isOn, badge, dim, onPick: (k) => pickTattoo(g, k) });
        if (S.adminMode && S.tatSel.has(t.key)) c.classList.add('picked');
        if (!free() && !isOn && !wasOn) {
            const own = r && typeof r.price === 'number';
            c.appendChild(el(`<div class="es-card-price${own ? ' on' : ''}">${money(tatPrice(g, t.key))}</div>`));
        }
        frag.appendChild(c);
    });
    if (!shown) {
        grid.appendChild(el(`<div class="es-note">${sub === 'mine' ? 'No tattoos on this part.' : 'No tattoos available on this part.'}</div>`));
    }
    grid.appendChild(frag);
}

function pickTattoo(g, key) {
    const info = S.tatIndex && S.tatIndex.get(key);
    if (!info) return;
    S.tatFocus = key;
    faceTattoo(g.ui.zone, info.t);
    const grid = $('es-grid');
    const c = grid.querySelector(`.es-card[data-value="${CSS.escape(key)}"]`);
    if (S.adminMode) {
        if (S.tatSel.has(key)) S.tatSel.delete(key); else S.tatSel.add(key);
        S.tatStatusText = null;
        if (c) c.classList.toggle('picked', S.tatSel.has(key));
        S.tatDraft = null;
        if (!S.adminOpen) S.adminOpen = 'tats';
        refreshBand();
        return;
    }
    const on = tatOnSet();
    if (on.has(key)) {
        S.look.tattoos = S.look.tattoos.filter((t) => tatKey(t) !== key);
    } else {
        if (on.size >= TAT_MAX) {
            const m = $('es-band').querySelector('.es-band-meta');
            if (m) m.innerHTML = `<b>At most ${TAT_MAX} tattoos.</b> Remove one to get another.`;
            return;
        }
        S.look.tattoos = [...S.look.tattoos, { collection: info.t.collection, overlay: info.t.overlay }];
    }
    if (c) c.classList.toggle('selected', !on.has(key));
    changed();
    refreshBand();
}

function dropTattoosNotAllowed() {
    const had = tatHadSet();
    const before = S.look.tattoos.length;
    S.look.tattoos = S.look.tattoos.filter((t) => {
        const k = tatKey(t);
        const info = S.tatIndex && S.tatIndex.get(k);
        return had.has(k) || (info && tatOk(k, info.zone));
    });
    if (S.look.tattoos.length === before) return false;
    changed();
    return true;
}

function tattooAdmin(box, g) {
    box.classList.remove('hidden');
    const redraw = () => { const k = S.focus && S.focus.dataset.key; renderAdmin(); if (k) focusAfterRender(k); };
    box.classList.toggle('open', !!S.adminOpen);
    const index = g.ui.index;
    const c = catOf('tattoo', index);
    const catStatus = !c ? 'free' : c.blocked ? 'blocked' : c.restricted ? 'restricted' : 'open';
    const n = S.tatSel.size;

    const bar = el('<div class="es-admin-bar"><span class="es-admin-title">Admin</span></div>');
    const toggle = (label, which) => chip(label, S.adminOpen === which,
        () => { S.adminOpen = S.adminOpen === which ? null : which; redraw(); }, 'open:' + which);
    bar.appendChild(toggle(`${meta(g).tab}: ${catStatus}`, 'cat'));
    bar.appendChild(toggle(n ? `Batch: ${n} picked` : 'Batch: none', 'tats'));
    bar.appendChild(el(`<span class="es-admin-hint">${S.adminOpen ? 'click again to collapse' : 'click the cards to pick'}</span>`));
    box.appendChild(bar);

    if (S.adminOpen === 'cat') {
        const ck = `tattoo:${index}`;
        if (!S.catDraft || S.catDraft.key !== ck) S.catDraft = Object.assign(accessFrom(c), { key: ck });
        box.appendChild(el(`<div class="es-admin-head"><span>Body part</span><b>${esc(g.label)}</b>`
            + `<em>${c && c.saved ? 'rule saved' : 'free'} · both bodies</em></div>`));
        accessEditor(box, S.catDraft, 'cat:', 'Who can get tattoos on this part', redraw);
        adminButtons(box, 'Save part', () => adminCategorySave(false), 'Open to everyone', !!(c && c.saved),
            () => adminCategorySave(true), 'cat');
        return;
    }
    if (S.adminOpen !== 'tats') return;

    const pickRow = el('<div class="es-chips"></div>');
    pickRow.appendChild(chip('Pick all from this part', false, () => {
        for (const t of tatList(g)) S.tatSel.add(t.key);
        S.tatDraft = null;
        renderTab(true);
    }, 'tsel:all'));
    pickRow.appendChild(chip('Clear the selection', false, () => { S.tatSel.clear(); S.tatDraft = null; renderTab(true); }, 'tsel:none'));
    box.appendChild(pickRow);
    if (!n) {
        box.appendChild(el('<div class="es-note">Click tattoos in the grid (from any part) to build a batch. '
            + 'The batch gets the same price and the same access: a single price for one, or a batch price for several.</div>'));
        return;
    }
    const keys = [...S.tatSel];
    if (!S.tatDraft) {

        const first = tatRule(keys[0]);
        const sig = (r) => (r ? JSON.stringify([r.price ?? null, !!r.blocked, !!r.restricted, r.jobs || [], r.chars || [], !!r.onDuty]) : 'none');
        const sameRule = keys.every((k) => sig(tatRule(k)) === sig(first));
        const r = sameRule ? first : null;
        S.tatDraft = Object.assign(accessFrom(r), { price: r && typeof r.price === 'number' ? String(r.price) : '' });
    }
    const dr = S.tatDraft;
    const withRule = keys.filter((k) => tatRule(k)).length;
    box.appendChild(el(`<div class="es-admin-head"><span>Batch</span><b>${n} tattoo(s)</b>`
        + `<em>${withRule ? `${withRule} already with a rule` : 'no rule'}</em></div>`));
    box.appendChild(el('<div class="es-label"><span>Price of each</span><span class="es-val">empty: the body part\'s</span></div>'));
    box.appendChild(textInput(dr.price, 'e.g. 750', (v) => { dr.price = v; }, 'tatprice'));
    accessEditor(box, dr, 'tat:', 'Who can get these tattoos', redraw);
    adminButtons(box, `Save on ${n}`, () => adminTattooSave(false), 'Remove rule', withRule > 0, () => adminTattooSave(true), 'tats');
    const status = el('<div class="es-note es-tat-status"></div>');
    status.textContent = S.tatStatusText || '';
    box.appendChild(status);
}

function tatStatus(text) {
    S.tatStatusText = text;
    const n = $('es-admin').querySelector('.es-tat-status');
    if (n) n.textContent = text || '';
}

async function adminTattooSave(reset) {
    const dr = S.tatDraft;
    const keys = [...S.tatSel];
    if (!keys.length) { tatStatus('Pick at least one tattoo in the grid.'); return; }
    if (!dr && !reset) { tatStatus('Open the batch again and try once more.'); return; }
    let rule;
    if (reset) rule = { reset: true };
    else {
        const txt = String(dr.price || '').trim();

        const digits = txt.split(',')[0].replace(/[^0-9]/g, '');
        const price = txt === '' ? null : Number(digits);
        if (txt !== '' && (digits === '' || !Number.isFinite(price))) { tatStatus('Invalid price: use numbers only (e.g. 750).'); return; }
        rule = Object.assign(accessRule(dr), { price });
    }
    tatStatus('Saving…');
    const res = await Promise.race([
        post('adminTattoos', { keys, rule }),
        new Promise((r) => setTimeout(() => r({ ok: false, why: 'The game did not answer (see F8).' }), 15000)),
    ]);
    if (res && res.ok) {
        setTatRules(res.tattoos);
        S.tatDraft = null;
        if (res.quote) { S.quote = res.quote; renderBill(); }
        S.tatStatusText = reset ? 'Rule removed.' : 'Saved.';
        renderTab(true);
    } else {
        tatStatus('Not saved: ' + ((res && res.why) || 'no answer from the game (see F8).'));
    }
}

function isWardrobe() { return !!(S.view && S.view.kind === 'wardrobe' && S.w); }
const wOutfits = () => (S.w && Array.isArray(S.w.outfits) ? S.w.outfits : []).filter((o) => o.model === S.look.model);
const wOutfit = (id) => (S.w && Array.isArray(S.w.outfits) ? S.w.outfits : []).find((o) => o.id === id) || null;

function wRoleName(level) {
    if (!level) return 'All ranks';
    const r = ((S.w && S.w.roles) || []).find((x) => x.level === level);
    return r ? r.name : `Level ${level}`;
}

function wPic(o) {
    for (const slot of [11, 8]) {
        const v = o.components && o.components[String(slot)];
        if (v && v.drawable >= 0) {
            const url = picUrl('component', slot, itemOf('component', slot, v.drawable), v.texture | 0);
            if (url) return url;
        }
    }
    return null;
}

let wHoverTimer = null;

function wHover(id) {
    if (!isWardrobe() || S.busy) return;
    S.wHover = id || null;
    clearTimeout(wHoverTimer);
    wHoverTimer = setTimeout(() => post('wardrobePreview', { id: S.wHover || 0 }), 180);
    refreshBand();
    renderBill();
}

function wardrobeBand(g, band) {
    const o = wOutfit(S.wHover || S.wSel);
    if (o) {
        let state;
        if (S.wOpen) state = 'Managing: click to pick';
        else state = o.allowed ? 'Click to wear · free' : 'Your rank cannot wear this outfit';
        band.appendChild(bandTop({
            hero: heroOf({ img: wPic(o), glyph: 'jacket' }), title: o.name,
            sub: S.w.custom ? `${S.w.jobName} · this mission` : `${S.w.jobName} · ${o.minLevel ? 'from ' + wRoleName(o.minLevel) : 'all ranks'}`,
            meta: state,
        }));
        return;
    }
    const n = wOutfits().length;
    band.appendChild(bandTop({
        hero: heroOf({ glyph: 'jacket' }), title: S.w.custom ? S.w.jobName : `Wardrobe: ${S.w.jobName}`,
        sub: n === 1 ? '1 outfit for your body' : `${n} outfits for your body`,
        meta: S.w.hasOwn ? 'You are in an outfit: <b>Back to my clothes</b> gives yours back.'
            : 'Click an outfit to wear it. Your clothes are kept.',
    }));
}

function wardrobeTab(g, band, grid) {
    wardrobeBand(g, band);
    const list = wOutfits();
    if (!list.length) {
        grid.appendChild(el(`<div class="es-note">No outfits for your body in this wardrobe yet.${
            S.w.canManage ? ' Create one in <b>Manage outfits</b>, below.' : ''}</div>`));
        return;
    }
    for (const o of list) {
        const c = card({
            value: o.id, label: o.name, name: o.name, img: wPic(o), glyph: 'jacket',
            selected: S.wOpen ? o.id === S.wSel : false,
            badge: !o.allowed ? 'Rank' : (o.minLevel ? wRoleName(o.minLevel) + '+' : null), dim: !o.allowed,
            onPick: (id) => pickOutfitCard(Number(id)),
        });
        c.addEventListener('mouseenter', () => wHover(o.id));
        grid.appendChild(c);
    }
    grid.onmouseleave = () => { if (!S.wOpen) wHover(0); };
}

function pickOutfitCard(id) {
    const o = wOutfit(id);
    if (!o) return;
    if (S.wOpen) {
        S.wSel = id;
        S.wEdit = null;
        S.wConfirmDelete = false;
        S.wStatus = null;
        wHover(id);
        selectCard($('es-grid'), id);
        renderAdmin();
        return;
    }
    if (!o.allowed) {
        const m = $('es-band').querySelector('.es-band-meta');
        if (m) m.innerHTML = '<b>Your rank cannot wear this outfit.</b>';
        return;
    }
    wardrobeWear(id);
}

function wardrobeBill() {
    const o = wOutfit(S.wHover || S.wSel);
    $('es-lines').innerHTML = `<div class="es-bill-line"><span>${esc(o ? o.name : 'Pick an outfit')}</span><span></span></div>`;
    $('es-total').textContent = 'Free';
    renderButtons();
}

function wardrobeButtons(add) {
    add('Close', '', 'b', cancel, S.busy);
    add('Back to my clothes', S.w.hasOwn ? 'primary' : '', 'x', wardrobeRestore, S.busy || !S.w.hasOwn);
}

async function wardrobeWear(id) {
    if (S.busy || !id) return;
    S.busy = true;
    renderButtons();
    const res = await post('wardrobeWear', { id });
    if (!res || !res.ok) { S.busy = false; renderButtons(); }
}

async function wardrobeRestore() {
    if (S.busy || !S.w.hasOwn) return;
    S.busy = true;
    renderButtons();
    const res = await post('wardrobeRestore', {});
    if (!res || !res.ok) { S.busy = false; renderButtons(); }
}

function wStatus(text) {
    S.wStatus = text;
    const n = $('es-admin').querySelector('.es-w-status');
    if (n) n.textContent = text || '';
}

function wardrobeAdmin(box) {
    if (!S.w.canManage) { box.classList.add('hidden'); return; }
    box.classList.remove('hidden');
    box.classList.toggle('open', !!S.wOpen);
    const redraw = () => { const k = S.focus && S.focus.dataset.key; renderAdmin(); if (k) focusAfterRender(k); };

    const bar = el('<div class="es-admin-bar"><span class="es-admin-title">Management</span></div>');
    bar.appendChild(chip(S.wOpen ? 'Managing outfits' : 'Manage outfits', !!S.wOpen, () => {
        S.wOpen = !S.wOpen;
        S.wEdit = null;
        S.wSel = null;
        S.wStatus = null;
        renderTab(true);
    }, 'w:open'));
    bar.appendChild(el(`<span class="es-admin-hint">${S.wOpen ? 'click an outfit to edit · again to collapse'
        : `${(S.w.outfits || []).length} of ${S.w.max} outfits`}</span>`));
    box.appendChild(bar);
    if (!S.wOpen) return;

    const newRow = el('<div class="es-chips"></div>');
    newRow.appendChild(chip('New: build in the store', false, () => post('wardrobeBuild', {}), 'w:build'));
    newRow.appendChild(chip('New: the clothes I am wearing', S.wEdit && S.wEdit.source === 'worn', () => {
        S.wEdit = { id: 0, source: 'worn', name: '', minLevel: 0 };
        S.wStatus = null;
        redraw();
    }, 'w:worn'));
    box.appendChild(newRow);

    const sel = wOutfit(S.wSel);
    if (!S.wEdit && sel) {
        box.appendChild(el(`<div class="es-admin-head"><span>Outfit</span><b>${esc(sel.name)}</b><em>${esc(wRoleName(sel.minLevel))}</em></div>`));
        const row = el('<div class="es-chips"></div>');
        row.appendChild(chip('Edit name and rank', false, () => {
            S.wEdit = { id: sel.id, source: 'existing', name: sel.name, minLevel: sel.minLevel || 0 };
            redraw();
        }, 'w:edit'));
        row.appendChild(chip('Replace with the clothes I am wearing', false, () => {
            S.wEdit = { id: sel.id, source: 'worn', name: sel.name, minLevel: sel.minLevel || 0 };
            redraw();
        }, 'w:reworn'));
        row.appendChild(chip(S.wConfirmDelete ? 'Confirm: delete' : 'Delete', !!S.wConfirmDelete, () => {
            if (!S.wConfirmDelete) { S.wConfirmDelete = true; redraw(); return; }
            wardrobeDelete(sel.id);
        }, 'w:delete'));
        box.appendChild(row);
    } else if (!S.wEdit) {
        box.appendChild(el('<div class="es-note">Click an outfit in the grid to edit or delete it, or create a new one above. '
            + 'An outfit built on a male body only shows for male characters (and the same for female).</div>'));
    }

    if (S.wEdit) {
        const ed = S.wEdit;
        const what = ed.source === 'draft' ? 'New (built in the store)' : ed.source === 'worn'
            ? (ed.id ? 'Replace with the worn clothes' : 'New (the worn clothes)') : 'Edit';
        box.appendChild(el(`<div class="es-admin-head"><span>Outfit</span><b>${esc(what)}</b><em>${esc(S.w.jobName)}</em></div>`));
        box.appendChild(el('<div class="es-label"><span>Name</span></div>'));
        box.appendChild(textInput(ed.name, 'e.g. Patrol, Formal, Mechanic', (v) => { ed.name = v; }, 'wname'));
        box.appendChild(el('<div class="es-label"><span>Who can wear it</span></div>'));
        const roles = el('<div class="es-chips"></div>');
        roles.appendChild(chip('All ranks', !ed.minLevel, () => { ed.minLevel = 0; redraw(); }, 'w:lvl:0'));
        for (const r of S.w.roles || []) {
            if (!r.level) continue;
            roles.appendChild(chip(`${r.name}+`, ed.minLevel === r.level, () => { ed.minLevel = r.level; redraw(); }, 'w:lvl:' + r.level));
        }
        box.appendChild(roles);
        adminButtons(box, 'Save outfit', () => wardrobeSave(), 'Cancel', true, () => {
            if (ed.source === 'draft') post('wardrobePreview', { id: 0 });
            S.wEdit = null; S.wStatus = null; redraw();
        }, 'w');
    }
    const st = el('<div class="es-note es-w-status"></div>');
    st.textContent = S.wStatus || '';
    box.appendChild(st);
}

async function wardrobeSave() {
    const ed = S.wEdit;
    if (!ed) return;
    if (!String(ed.name || '').trim()) { wStatus('Give the outfit a name.'); return; }
    wStatus('Saving…');
    const res = await post('wardrobeSave', { id: ed.id || 0, name: ed.name, minLevel: ed.minLevel || 0, source: ed.source });
    if (res && res.ok) {
        S.w.outfits = res.outfits || S.w.outfits;
        S.wSel = res.id || null;
        S.wEdit = null;
        S.wStatus = 'Saved.';
        renderTab(true);
        renderBill();
    } else {
        wStatus('Not saved: ' + ((res && res.why) || 'see the notice on screen.'));
    }
}

async function wardrobeDelete(id) {
    const res = await post('wardrobeDelete', { id });
    S.wConfirmDelete = false;
    if (res && res.ok) {
        S.w.outfits = res.outfits || [];
        S.wSel = null;
        S.wHover = null;
        S.wStatus = 'Outfit deleted.';
        renderTab(true);
        renderBill();
    } else {
        renderAdmin();
    }
}

function wardrobeDraftArrived() {
    if (!isWardrobe()) return;
    S.wOpen = true;
    S.wEdit = { id: 0, source: 'draft', name: '', minLevel: 0 };
    S.wStatus = 'Give it a name and save. (Cancel discards the built clothes.)';
    renderTab(true);
    focusAfterRender('input:wname');
}

const FEMALE = 'mp_f_freemode_01';
function sexBand(g, band) {
    band.appendChild(bandTop({ hero: null, small: true, title: 'Sex',
        sub: 'Changes the whole body. The new body\'s clothes and hair are picked right here, at no extra cost '
            + '(the Clothing, Hair and Accessories tabs show up). Tattoos that do not exist on the new body are lost.',
        meta: priceMeta(g) }));
}
function sexTab(g, band, grid) {
    sexBand(g, band);
    const female = S.look.model === FEMALE;
    const pick = (v) => setSex(v === 'female');
    grid.appendChild(card({ value: 'male', label: 'Male', big: 'Male', selected: !female, wide: true, onPick: pick }));
    grid.appendChild(card({ value: 'female', label: 'Female', big: 'Female', selected: female, wide: true, onPick: pick }));
}

async function setSex(female) {
    if (S.busy) return;
    if ((S.look.model === FEMALE) === female) return;
    S.busy = true;
    renderButtons();
    const res = await post('sex', { female });
    S.busy = false;
    if (res && res.reload) load(res.reload);
    renderAll();
    focusAfterRender('card:' + (female ? 'female' : 'male'));
}

const TABS = {
    outfits: wardrobeTab,
    tattoo: tattooTab,
    component: pieceTab, prop: pieceTab, hair: pieceTab,
    hairColor: (g, band) => hairColorBand(g, band),
    fade: fadeTab, overlay: overlayTab, overlays: skinTab,
    heritage: heritageTab, features: featuresTab, eyes: eyesTab, sex: sexTab,
};
const BANDS = {
    outfits: wardrobeBand,
    tattoo: tattooBand,
    component: pieceBand, prop: pieceBand, hair: pieceBand, hairColor: hairColorBand, fade: fadeBand,
    overlay: (g, band) => overlayBand(g, band, g.ui.name, g.ui.id, g.ui.colorType, meta(g).one),
    overlays: skinBand, heritage: heritageBand, features: featureBand, eyes: eyesBand, sex: sexBand,
};

function free() { return S.view.free || S.view.test || S.mode === 'builder'; }

function renderBill() {
    if (isWardrobe()) { wardrobeBill(); return; }
    const lines = S.quote.lines || [];
    $('es-lines').innerHTML = lines.length
        ? lines.map((l) => `<div class="es-bill-line"><span>${esc(l.label)}</span><span>${free() ? '—' : money(l.price)}</span></div>`).join('')
        : '<div class="es-bill-line"><span>Nothing changed yet</span><span></span></div>';
    $('es-total').textContent = free() ? 'Free' : money(S.quote.total);
    renderButtons();
}

function padGlyphImg(name) {
    return S.pad ? `<img class="es-glyph" src="${CORE}img/pad/${name}.svg" alt="">` : '';
}

function renderButtons() {
    const box = $('es-buttons');
    box.innerHTML = '';
    const none = (S.quote.lines || []).length === 0;
    const add = (label, cls, glyph, fn, disabled) => {
        const b = el(`<button class="es-btn ${cls}" data-nav="btn">${padGlyphImg(glyph)}<span>${esc(label)}</span></button>`);
        b.dataset.key = 'btn:' + label;
        b.disabled = !!disabled;
        b.onclick = fn;
        box.appendChild(b);
    };
    if (isWardrobe()) { wardrobeButtons(add); return; }
    add('Cancel', '', 'b', cancel, S.busy);
    if (S.mode === 'builder') add('Save outfit', 'primary', 'y', () => buy('cash'), S.busy);
    else if (free()) add('Confirm', 'primary', 'y', () => buy('cash'), S.busy || none);
    else {
        if (S.view.allowBank) add('Pay by bank', '', 'x', () => buy('bank'), S.busy || none);
        add(`Pay ${money(S.quote.total)}`, 'primary', 'y', () => buy('cash'), S.busy || none);
    }
}

async function buy(method) {
    if (S.busy) return;
    if (isWardrobe()) { if (method === 'bank') wardrobeRestore(); else wardrobeWear(); return; }
    if (S.mode !== 'builder' && (S.quote.lines || []).length === 0) return;
    S.busy = true;
    renderButtons();
    const res = await post('buy', { method });
    if (!res || res.ok === false) { S.busy = false; renderButtons(); }
}

function confirmOpen() { return !$('es-confirm').classList.contains('hidden'); }
function cancel() {
    if (S.busy) return;
    if (confirmOpen()) return;
    if ((S.quote.lines || []).length > 0 && S.mode !== 'builder') {
        $('es-confirm').classList.remove('hidden');
        if (S.pad) setFocus($('es-confirm-no'));
        return;
    }
    post('cancel');
}
$('es-confirm-no').onclick = () => { $('es-confirm').classList.add('hidden'); if (S.pad) focusAfterRender('btn:Cancel'); };
$('es-confirm-yes').onclick = () => { $('es-confirm').classList.add('hidden'); post('cancel'); };

function renderHints() {
    const box = $('es-hints');
    if (S.pad) {
        const h = (g, t) => `<span class="es-hint">${g.map((x) => padGlyphImg(x)).join('')}<span>${t}</span></span>`;
        box.innerHTML = h(['lb', 'rb'], 'Category') + h(['dpad'], 'Navigate') + h(['a'], 'Pick')
            + h(['rs'], 'Turn / height') + h(['lt', 'rt'], 'Zoom') + h(['b'], 'Cancel');
    } else {
        const k = (key, t) => `<span class="es-hint"><span class="es-key">${key}</span><span>${t}</span></span>`;
        box.innerHTML = k('Drag', 'Turn / height') + k('Wheel', 'Zoom') + k('Q / E', 'Turn') + k('Esc', 'Cancel');
    }
}

function navItems() {
    const scope = confirmOpen() ? $('es-confirm') : $('es');
    return [...scope.querySelectorAll('[data-nav]')].filter((x) => {
        if (x.disabled) return false;
        if (!confirmOpen() && $('es-confirm').contains(x)) return false;
        const r = x.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
    });
}

function setFocus(target) {
    if (S.focus && S.focus !== target) S.focus.classList.remove('pad-focus');
    S.focus = target || null;
    if (!target) return;
    if (S.pad) target.classList.add('pad-focus');
    target.scrollIntoView({ block: 'nearest', inline: 'nearest' });

    if (S.pad && isWardrobe() && !S.wOpen && target.dataset.nav === 'card') wHover(Number(target.dataset.value));
}

function focusAfterRender(key) {
    if (!S.pad) return;
    const items = navItems();
    const byKey = key && items.find((x) => x.dataset.key === key);
    const sel = $('es-grid').querySelector('.es-card.selected');
    const tab = $('es-rail').querySelector('.es-tab.active');
    setFocus(byKey || sel || tab || items[0]);
}

function liveFocus(items) {
    if (S.focus && document.body.contains(S.focus) && items.includes(S.focus)) return S.focus;
    const key = S.focus && S.focus.dataset && S.focus.dataset.key;
    const again = key && items.find((x) => x.dataset.key === key);
    if (again) { setFocus(again); return again; }
    return null;
}

function moveFocus(dir) {
    const items = navItems();
    if (!items.length) return;
    if (!liveFocus(items)) { focusAfterRender(); return; }
    const a = S.focus.getBoundingClientRect();
    const ax = a.left + a.width / 2, ay = a.top + a.height / 2;
    let best = null, bestScore = Infinity;
    for (const it of items) {
        if (it === S.focus) continue;
        const b = it.getBoundingClientRect();
        const bx = b.left + b.width / 2, by = b.top + b.height / 2;
        const dx = bx - ax, dy = by - ay;
        let main, side;
        if (dir === 'right') { main = dx; side = dy; }
        else if (dir === 'left') { main = -dx; side = dy; }
        else if (dir === 'down') { main = dy; side = dx; }
        else { main = -dy; side = dx; }
        if (main <= 2) continue;
        const score = main + Math.abs(side) * 2.2;
        if (score < bestScore) { bestScore = score; best = it; }
    }
    if (best) setFocus(best);
}

function nudgeRange(input, dir, rep) {
    const step = Number(input.step) || 0.01;
    const mult = rep && rep > 4 ? 5 : 1;
    const v = clamp(Number(input.value) + dir * step * mult, Number(input.min), Number(input.max));
    input.value = v;
    input.dispatchEvent(new Event('input'));
}

function onPad(cmd, rep) {
    if (!S.open) return;
    if (cmd === 'b') {
        if (confirmOpen()) { $('es-confirm-no').click(); return; }
        cancel();
        return;
    }
    if (confirmOpen()) {
        if (cmd === 'a' && S.focus) S.focus.click();
        else if (cmd === 'left' || cmd === 'right') moveFocus(cmd);
        return;
    }
    if (cmd === 'lb') { stepTab(-1); return; }
    if (cmd === 'rb') { stepTab(1); return; }
    if (cmd === 'y') { buy('cash'); return; }
    if (cmd === 'x') { if (isWardrobe() || (S.view.allowBank && !free())) buy('bank'); return; }
    const cur = liveFocus(navItems());
    if (cmd === 'a') {
        if (cur && cur.tagName === 'INPUT' && cur.type === 'text') cur.focus();
        else if (cur && cur.dataset.nav !== 'range') cur.click();
        return;
    }
    if (['up', 'down', 'left', 'right'].includes(cmd)) {
        if (cur && cur.dataset.nav === 'range' && (cmd === 'left' || cmd === 'right')) {
            nudgeRange(cur, cmd === 'right' ? 1 : -1, rep);
            return;
        }
        moveFocus(cmd);
    }
}

function setPad(on) {
    S.pad = !!on;
    $('es').classList.toggle('es-pad-on', S.pad);
    renderHints();
    renderButtons();
    if (S.pad) focusAfterRender(S.focus && S.focus.dataset.key);
    else if (S.focus) S.focus.classList.remove('pad-focus');
}

(function stage() {
    const st = $('es-stage');
    let drag = false, ax = 0, ay = 0, sending = false;
    st.addEventListener('pointerdown', (e) => { drag = true; st.classList.add('dragging'); st.setPointerCapture(e.pointerId); });
    st.addEventListener('pointerup', () => { drag = false; st.classList.remove('dragging'); });
    st.addEventListener('pointermove', (e) => {
        if (!drag) return;
        ax += e.movementX;
        ay += e.movementY;
        if (sending) return;
        sending = true;
        requestAnimationFrame(async () => {
            const dx = ax * 0.4, dy = -ay * 0.004;
            ax = 0; ay = 0;
            await post('orbit', { dx, dy });
            sending = false;
        });
    });
    st.addEventListener('wheel', (e) => { post('zoom', { delta: e.deltaY > 0 ? 0.15 : -0.15 }); });
})();

window.addEventListener('keydown', (e) => {
    if (!S.open) return;

    if (e.target && e.target.tagName === 'INPUT' && e.target.type === 'text') {
        if (e.key === 'Escape') e.target.blur();
        return;
    }
    if (e.key === 'Escape' || e.key === 'Backspace') {
        if (confirmOpen()) $('es-confirm-no').click();
        else cancel();
    } else if (e.key === 'q' || e.key === 'Q') post('turn', { deg: -20 });
    else if (e.key === 'e' || e.key === 'E') post('turn', { deg: 20 });
});

function fitScale() {
    const ui = Math.min(window.innerHeight / 1440, window.innerWidth / 2560);
    $('es').style.setProperty('--es-zoom', String(ui * 1.5));
}
window.addEventListener('resize', fitScale);

function normalize(a) {
    for (const k of ['components', 'props', 'overlays', 'hair', 'headBlend']) {
        if (!a[k] || Array.isArray(a[k])) a[k] = {};
    }
    const hb = a.headBlend;
    hb.mom = hb.mom | 0; hb.dad = hb.dad | 0; hb.grandparent = hb.grandparent | 0;
    hb.faceWeight = typeof hb.faceWeight === 'number' ? hb.faceWeight : 0.5;
    hb.skinWeight = typeof hb.skinWeight === 'number' ? hb.skinWeight : 0.5;
    hb.thirdWeight = typeof hb.thirdWeight === 'number' ? hb.thirdWeight : 0;
    const ff = Array.isArray(a.faceFeatures) ? a.faceFeatures : [];
    a.faceFeatures = Array.from({ length: 20 }, (_, i) => Number(ff[i]) || 0);
    if (!a.hairFade || typeof a.hairFade.collection !== 'string') a.hairFade = null;
    a.tattoos = Array.isArray(a.tattoos) ? a.tattoos.filter((t) => tatKey(t)) : [];
    return a;
}

function load(d) {
    if (d.look) S.look = normalize(d.look);
    if (d.savedModel) S.savedModel = d.savedModel;
    if (d.maxes) S.maxes = d.maxes;
    if (d.fades) S.fades = Array.isArray(d.fades) ? d.fades : [];
    if ('icons' in d) S.icons = d.icons || null;
    if ('pictures' in d) S.pictures = d.pictures || null;
    if (d.quote) S.quote = d.quote;
    if ('tattooList' in d) setTattooList(d.tattooList);
    if ('hide' in d) S.hide = d.hide && typeof d.hide === 'object' && !Array.isArray(d.hide) ? d.hide : {};
    if ('views' in d) S.views = Array.isArray(d.views) ? d.views : [];
    if (typeof d.removePrice === 'number') S.removePrice = d.removePrice;
    S.texCount = {};
    if (!visibleGroups().some((g) => g.key === S.tab)) S.tab = (visibleGroups()[0] || {}).key;
}

function renderAll() {
    renderGroups();
    renderRail();
    renderView();
    renderTab(false);
    renderBill();
    renderHints();
}

window.addEventListener('message', (ev) => {
    const d = ev.data || {};
    if (d.action === 'open') {
        fitScale();
        S.open = true;
        S.busy = false;
        S.view = d.view;
        S.mode = d.mode || 'shop';
        S.groups = d.groups || [];
        S.palettes = d.palettes || { hair: [], makeup: [] };
        S.tab = null;
        S.sub = {};
        S.feature = 'brow';
        S.focus = null;
        S.brand = S.view.brand || null;
        S.brandCfg = d.brands || null;
        kwCache = null;
        setRules(S.view.rules, S.view.categories);
        setTatRules(S.view.tattoos);
        S.w = S.view.wardrobe || null;
        S.wSel = null;
        S.wEdit = null;
        S.wOpen = false;
        S.tatFocus = null;
        S.scope = 'model';
        S.adminMode = false;
        load(d);
        S.opened = JSON.parse(JSON.stringify(S.look));
        setAdminMode(false);
        $('es-title').textContent = S.view.title || '';
        const kindLabel = { clothing: 'Clothing Store', barber: 'Barber Shop', surgery: 'Plastic Surgery', tattoo: 'Tattoo Studio',
            wardrobe: 'Outfit Wardrobe' }[S.view.kind] || '';
        $('es-sub').innerHTML = esc(S.mode === 'builder' ? 'Director: pick outfit' : kindLabel)
            + (S.view.test ? ' <span class="es-badge">Test: nothing is saved</span>'
                : free() ? ' <span class="es-badge">On the house</span>' : '');
        $('es-confirm').classList.add('hidden');
        $('es').classList.remove('hidden');
        loadNames();
        renderAll();
        if (S.tab) post('frame', { cam: groupByKey(S.tab).cam });
        setPad(d.pad);
    } else if (d.action === 'close') {
        S.open = false;
        $('es').classList.add('hidden');
    } else if (d.action === 'quote') {
        if (d.quote) S.quote = d.quote;
        if (d.groups) S.groups = d.groups;
        if (typeof d.removePrice === 'number') S.removePrice = d.removePrice;
        renderAll();
    } else if (d.action === 'result') {
        S.busy = false;
        renderButtons();
    } else if (d.action === 'wardrobeDraft') {
        wardrobeDraftArrived();
    } else if (d.action === 'pad') {
        if (d.down !== false) onPad(d.cmd, d.rep);
    } else if (d.action === 'padDevice') {
        setPad(d.pad);
    }
});
