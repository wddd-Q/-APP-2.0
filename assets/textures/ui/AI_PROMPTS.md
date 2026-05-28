# 修真宗门 · 美术素材圣经

## 操作流程（3 步）

```
1. 选工具 → Midjourney（场景/立绘） / SDXL+ComfyUI（批量图标）
2. 复制下方 prompt → 生成 → 下载 PNG
3. 按指定路径命名保存 → 重启游戏自动生效
```

**风格锚定**：每段 prompt 都包含 `ancient Chinese cultivation fantasy art` 作为基调

---

## 一、全局风格定义

所有素材共用此风格约束。生图时追加到每个 prompt 末尾：

```
Master style: ancient Chinese xianxia fantasy, ink wash painting influence,
Song dynasty aesthetics, refined elegance, muted earthy palette with gold accents,
soft diffused lighting, subtle spiritual energy particles, no western elements,
no neon colors, no modern objects, no anime chibi style
```

**通用负向词（Negative Prompt）**：
```
text, watermark, signature, modern, western, neon, anime, 3D render,
photorealistic, ugly, blurry, low quality, deformed, extra limbs,
bright saturated colors, cartoon
```

---

## 二、UI 纹理（12 项）— 即插即用

**生成尺寸**：512x512 PNG（按钮为 512x128），9-slice 友好
**当前代码状态**：TextureGenerator 自动加载，已支持

### 2.1 面板背景 (panel_bg.png)
**保存至**: `assets/textures/ui/panels/panel_bg.png`
**Prompt**:
```
Seamless parchment paper texture, ancient Chinese cultivation scroll style,
dark brown aged paper, subtle fiber texture, warm earthy tones,
tileable 512x512, game UI background, flat even lighting, no text,
no obvious repeating patterns, muted colors, ancient Chinese fantasy art
```
**负向**: text, letters, bright colors, modern elements, 3D, shadows

### 2.2 面板标题栏 (panel_header.png)
**保存至**: `assets/textures/ui/panels/panel_header.png`
**Prompt**:
```
Horizontal bar texture, dark wood grain with gold trim, ancient Chinese
ornamental panel header, dark brown with subtle metallic gold edge,
512x128 tileable horizontally, game UI element, flat design,
ancient Chinese fantasy game art
```

### 2.3 按钮-普通态 (btn_normal.png)
**保存至**: `assets/textures/ui/buttons/btn_normal.png`
**Prompt**:
```
Game UI button, ancient Chinese wooden button, dark walnut wood texture
with subtle beveled gold border, rounded rectangle, warm brown tone,
512x128 horizontal, 9-slice friendly, solid center, flat top-down view,
ancient Chinese cultivation fantasy art style
```

### 2.4 按钮-悬停态 (btn_hover.png)
**保存至**: `assets/textures/ui/buttons/btn_hover.png`
**Prompt**:
```
Game UI button hover state, ancient Chinese style, lighter sandalwood texture,
glowing amber gold border, warm honey highlight, rounded rectangle,
512x128 horizontal, 9-slice friendly, solid center, subtle outer golden glow,
ancient Chinese cultivation fantasy art
```

### 2.5 按钮-按压态 (btn_pressed.png)
**保存至**: `assets/textures/ui/buttons/btn_pressed.png`
**Prompt**:
```
Game UI button pressed state, ancient Chinese style, dark ebony wood texture,
pressed inward sunken effect, darker than normal state, muted copper border,
512x128 horizontal, 9-slice friendly, solid center, ancient Chinese game art
```

### 2.6 主按钮-金 (btn_gold.png)
**保存至**: `assets/textures/ui/buttons/btn_gold.png`
**Prompt**:
```
Game UI primary action button, ancient Chinese cultivation style, golden amber
texture with ornate cloud-pattern border, bright amber and gold tones,
important action button, 512x128 horizontal, 9-slice friendly,
ornate corner decorations, ancient Chinese fantasy game UI
```

### 2.7 危险按钮-红 (btn_danger.png)
**保存至**: `assets/textures/ui/buttons/btn_danger.png`
**Prompt**:
```
Game UI danger button, ancient Chinese style, dark crimson lacquer texture,
subtle dark brown border, warning color, rounded rectangle,
512x128 horizontal, 9-slice friendly, ancient Chinese game art
```

### 2.8 装饰边框 (border_frame.png)
**保存至**: `assets/textures/ui/decorations/border_frame.png`
**Prompt**:
```
Ornate golden frame border, ancient Chinese palace window lattice style,
thin gold lines with cloud-hook corner ornaments, transparent center,
512x512, game UI border element, elegant refined, dark gold on transparent,
ancient Chinese cultivation fantasy art, 9-slice friendly
```

### 2.9 分隔线 (divider.png)
**保存至**: `assets/textures/ui/decorations/divider.png`
**Prompt**:
```
Horizontal ornamental divider, ancient Chinese style,
thin gold line with central diamond-shaped ruyi ornament,
512x16, game UI separator, elegant simple, transparent background,
ancient Chinese fantasy art
```

### 2.10 暗纹背景 (bg_main.png)
**保存至**: `assets/textures/bg/bg_main.png`
**Prompt**:
```
Dark atmospheric background texture, ancient Chinese cultivation world,
subtle ink wash mountain silhouette hints, very dark near-black with
subtle warm brown variations, seamless tileable 512x512, moody atmosphere,
no characters, no buildings, extremely subtle pattern, ancient Chinese art
```

### 2.11 宗门地形 (bg_sect.png)
**保存至**: `assets/textures/bg/bg_sect.png`
**Prompt**:
```
Top-down terrain texture, ancient Chinese mountain sect grounds,
green and brown earth tones, grass patches, winding dirt paths,
seamless tileable 512x512, game terrain background, top-down view,
flat even lighting, no buildings, ancient Chinese landscape style
```

### 2.12 云纹图案 (cloud_pattern.png)
**保存至**: `assets/textures/ui/decorations/cloud_pattern.png`
**Prompt**:
```
Chinese auspicious cloud pattern (xiangyun), dark transparent background,
subtle gold/amber colored stylized clouds, repeating seamless pattern,
512x512 tileable, game UI decoration, elegant subtle, transparent bg,
ancient Chinese fantasy ornamental pattern
```

---

## 三、场景背景（6 项）— 即插即用

**生成尺寸**：1024x768 或 1920x1080 PNG
**当前代码状态**：bg_main.png 和 bg_sect.png 已由 TextureGenerator 加载；其他场景需扩展代码支持（见第五节）

### 3.1 宗门山门全景 (bg_sect_panorama.png)
**保存至**: `assets/textures/bg/bg_sect_panorama.png`
**Prompt**:
```
Panoramic view of an ancient Chinese cultivation sect nestled in misty mountains,
traditional curved-roof halls ascending the mountain, stone stairways,
ancient pine trees, waterfall in distance, morning mist, golden sunrise light,
Song dynasty architecture, ink wash painting atmosphere, 1920x1080,
epic serene mood, ancient Chinese xianxia fantasy art
```

### 3.2 大殿内部 (bg_main_hall.png)
**保存至**: `assets/textures/bg/bg_main_hall.png`
**Prompt**:
```
Interior of ancient Chinese grand hall, tall wooden pillars with carved dragons,
incense burner with rising smoke, stone floor with Bagua pattern,
soft light from paper lanterns, solemn atmosphere, sect master's throne area,
1920x1080, ancient Chinese cultivation palace interior, warm amber lighting
```

### 3.3 炼丹房 (bg_alchemy_room.png)
**保存至**: `assets/textures/bg/bg_alchemy_room.png`
**Prompt**:
```
Ancient Chinese alchemy workshop interior, bronze cauldron furnace in center,
shelves of ceramic herb jars, scrolls hanging on walls, dim warm firelight,
steam and smoke, mystical atmosphere, 1920x1080, ancient Chinese fantasy art,
cozy workshop feel
```

### 3.4 藏经阁 (bg_scripture_pavilion.png)
**保存至**: `assets/textures/bg/bg_scripture_pavilion.png`
**Prompt**:
```
Ancient Chinese library interior, tall wooden shelves filled with bamboo scrolls
and silk books, soft light filtering through paper windows, quiet scholarly
atmosphere, floating dust particles in light beams, 1920x1080,
ancient Chinese cultivation fantasy art, peaceful contemplative mood
```

### 3.5 演武场 (bg_training_ground.png)
**保存至**: `assets/textures/bg/bg_training_ground.png`
**Prompt**:
```
Ancient Chinese martial arts training ground, stone courtyard with wooden
training dummies, weapon racks with swords and spears, overlooking mountain
vista, morning light, 1920x1080, ancient Chinese cultivation sect,
clear sky, inspiring atmosphere
```

### 3.6 灵脉洞府 (bg_spirit_cave.png)
**保存至**: `assets/textures/bg/bg_spirit_cave.png`
**Prompt**:
```
Ancient Chinese cultivation cave interior, glowing blue spirit stones embedded
in walls, underground crystal formations, shimmering spiritual energy flow,
mystical underground grotto, 1920x1080, ancient Chinese xianxia fantasy art,
ethereal blue ambient light, magical atmosphere
```

---

## 四、角色立绘（2 套×20 张）— 即插即用

**生成尺寸**：512x512 PNG，透明背景更佳
**当前代码状态**：DisciplePortrait 自动加载 `portraits/{弟子名}.png`
**批量技巧**：使用 Midjourney 的 "4 variations per generation" 模式，每张 prompt 微调描述获得不同面孔

### 4.1 男弟子头像 × 10

**保存至**: `assets/textures/portraits/{名字}.png`
**Prompt 模板**（替换 `{NAME}` 和 `{age}` 等变量）：
```
Male Chinese cultivator bust portrait, {age} years old, {realm_description},
ancient Chinese Hanfu robes, {hair_style}, {expression},
512x512 square, bust portrait facing forward, clean simple background,
ancient Chinese xianxia fantasy art, ink wash painting influence,
soft lighting, refined elegant, consistent art style
```

**10 组变量快速生成表**：

| # | 名字 | age | realm_description | hair_style | expression |
|---|------|-----|-------------------|------------|------------|
| 1 | 柳青阳 | 25 | young cultivator, Qi Refining robes | long black hair tied up | confident slight smile |
| 2 | 铁无涯 | 40 | middle-aged, Foundation Establishment robes | short beard, warrior bun | stern, experienced |
| 3 | 云清璇 | 22 | female cultivator, elegant Core Formation robes | flowing hair, jade hairpin | gentle, wise |
| 4 | 萧寒 | 30 | cold-looking cultivator, dark blue robes | sharp features, long hair | cold, aloof |
| 5 | 白鹤 | 60 | elderly cultivator, Nascent Soul grand robes | white hair, long beard | kind, sagely smile |
| 6 | 赤炎 | 28 | fiery cultivator, red-trimmed robes | wild red-brown hair | fierce, passionate |
| 7 | 林小月 | 18 | young female disciple, simple cloth robes | twin buns, innocent | bright, cheerful |
| 8 | 墨渊 | 35 | mysterious cultivator, black and purple robes | half-covered face, dark hair | mysterious, intense |
| 9 | 碧瑶仙子 | 26 | beautiful female cultivator, flowing silk robes | elaborate hair ornaments | graceful, serene |
| 10 | 石破天 | 32 | muscular cultivator, practical martial robes | short practical cut | straightforward, honest |

### 4.2 女弟子头像 × 10

**Prompt 模板**：
```
Female Chinese cultivator bust portrait, {age} years old, {realm_description},
ancient Chinese Hanfu robes, {hair_style}, {expression},
512x512 square, bust portrait facing forward, clean simple background,
ancient Chinese xianxia fantasy art, ink wash painting influence,
soft lighting, refined elegant, consistent art style
```

| # | 名字 | age | realm_description | hair_style | expression |
|---|------|-----|-------------------|------------|------------|
| 1 | 苏沐晴 | 20 | young female cultivator, light green robes | long braided hair | gentle, warm smile |
| 2 | 冷月 | 24 | female sword cultivator, white and blue robes | high ponytail with ribbon | cool, focused |
| 3 | 花千骨 | 19 | petite female disciple, pink-trimmed robes | flower hair ornaments | playful, lively |
| 4 | 洛清尘 | 28 | elegant female elder, golden-trimmed robes | elaborate phoenix hairpin | dignified, graceful |
| 5 | 薛灵儿 | 16 | youngest disciple, simple grey robes | short bob cut | curious, bright eyes |
| 6 | 冰心 | 35 | mature female cultivator, ice-blue robes | simple elegant updo | cold beauty, distant |
| 7 | 慕容雪 | 22 | noble-born cultivator, luxurious purple robes | jade crown with veil | proud, aristocratic |
| 8 | 沈凝霜 | 45 | senior female elder, dark green robes | silver-streaked hair | wise, maternal |
| 9 | 燕小七 | 17 | tomboyish disciple, practical brown robes | short messy hair | mischievous grin |
| 10 | 蝶舞 | 26 | dancer-turned-cultivator, flowing rainbow robes | butterfly hair ornaments | elegant, dreamy |

---

## 五、道具图标（20 项）— 需扩展代码

**生成尺寸**：128x128 或 256x256 PNG，透明背景
**代码状态**：当前项目无图标系统，需我后续添加 `ItemIcon` 组件

### 5.1 丹药类

| 文件名 | 名称 | Prompt 摘要 |
|--------|------|-------------|
| `pill_qi.png` | 聚气丹 | small round pill, soft blue-white glow, ceramic texture |
| `pill_foundation.png` | 筑基丹 | golden pill, swirling energy patterns, luminous aura |
| `pill_healing.png` | 回春丹 | green pill with leaf-like markings, healing energy glow |
| `pill_mana.png` | 回灵丹 | azure blue pill, water droplet shape, spiritual particles |
| `pill_breakthrough.png` | 破境丹 | radiant multicolor pill, energy rays, dramatic glow |

### 5.2 法宝/装备类

| 文件名 | 名称 | Prompt 摘要 |
|--------|------|-------------|
| `weapon_sword.png` | 飞剑 | elegant Chinese flying sword, jade-green blade, gold guard |
| `weapon_flywhisk.png` | 拂尘 | taoist fly-whisk, white horsehair, jade handle |
| `armor_robe.png` | 法袍 | folded cultivation robe, silk with gold cloud patterns |
| `talisman_paper.png` | 符纸 | yellow paper talisman, red cinnabar writing, mystical |
| `beast_seal.png` | 御兽印 | jade seal with mythical beast carving, spiritual glow |

### 5.3 材料类

| 文件名 | 名称 | Prompt 摘要 |
|--------|------|-------------|
| `mat_spirit_herb.png` | 灵草 | glowing blue herb with five leaves, spiritual energy wisps |
| `mat_iron_ore.png` | 寒铁 | raw dark blue-grey ore with metallic crystal flecks |
| `mat_jade.png` | 灵玉 | translucent green jade stone, inner light glow |
| `mat_beast_core.png` | 妖兽内丹 | spherical beast core, red-orange with swirling energy |
| `mat_fire_crystal.png` | 火灵石 | faceted red-orange crystal, inner fire glow |

### 5.4 功法/书籍类

| 文件名 | 名称 | Prompt 摘要 |
|--------|------|-------------|
| `book_technique.png` | 功法秘籍 | ancient Chinese silk-bound book, gold title strip |
| `book_scroll.png` | 竹简卷轴 | bamboo slip scroll, tied with silk cord, aged |
| `book_jade_slip.png` | 玉简 | rectangular jade tablet, glowing spiritual text |
| `map_treasure.png` | 藏宝图 | aged parchment treasure map, Chinese landscape drawings |
| `token_sect.png` | 宗门令 | bronze sect token, engraved with mountain motif |

---

## 六、粒子特效（8 项）— 需扩展代码

**生成尺寸**：256x256 或 512x512，带透明通道的序列帧（spritesheet）
**代码状态**：当前项目无粒子特效系统，需后续添加。可用作 UI 装饰

| 文件名 | 名称 | Prompt 摘要 |
|--------|------|-------------|
| `fx_cultivation.png` | 修炼灵气 | swirling blue-gold spiritual energy particles, spiral upward |
| `fx_breakthrough.png` | 突破光柱 | vertical golden light pillar, expanding shockwave rings |
| `fx_heal.png` | 治愈绿光 | soft green healing light particles, gentle rising motion |
| `fx_damage.png` | 受伤红光 | red energy flash, dispersing dark particles |
| `fx_teleport.png` | 传送阵 | Bagua circle formation, blue energy rising from edges |
| `fx_loot.png` | 获得物品 | golden sparkle burst, floating particles |
| `fx_levelup.png` | 境界提升 | golden dragon silhouette coiling upward, particle burst |
| `fx_danger_zone.png` | 危险区域 | pulsing dark red-violet miasma, ground-level haze |

---

## 七、工具对比与选择

| 特性 | Midjourney | SDXL+ComfyUI | DALL-E 3 |
|------|-----------|--------------|----------|
| 古风理解 | ★★★★★ 最佳 | ★★★★ 需调教 | ★★★☆☆ |
| 风格一致性 | ★★★☆☆ | ★★★★★ LoRA可控 | ★★☆☆☆ |
| 批量效率 | ★★★☆☆ | ★★★★★ 工作流 | ★★★☆☆ |
| 上手难度 | 极低 | 中等 | 极低 |
| 透明度支持 | ✗ | ✓ | ✗ |
| 月费 | $10-60 | 本地免费 | $20 |

### 推荐策略

- **场景 + 立绘** → **Midjourney**（画面美感最强，古风理解最好）
- **图标 + 纹理** → **SDXL + ComfyUI**（批量产出、风格统一靠 LoRA、支持透明背景）
- **不想折腾本地部署** → 海艺 AI（hailuoai.com，有国风模型，支持批量）

### Midjourney 保持一致风格的关键技巧

1. **用 `--cref`（角色参考）**：上传已有成功图片作为风格参考
2. **用 `--sref`（风格参考）**：锁定一种画面风格，所有图套用
3. **固定后缀**：每段 prompt 末尾加 `--ar 1:1 --s 250 --style raw`
4. **先做风格锚定图**：先花时间调出一张满意的主视觉，后续所有图用它做 `--sref`

---

## 八、建议生成顺序（按 ROI 从高到低）

```
第1批 ▸ UI 纹理 12 张（最大视觉影响，覆盖所有界面）
第2批 ▸ 弟子头像 20 张（角色是玩家最关注的元素）
第3批 ▸ 场景背景 6 张（氛围感拉升明显）
第4批 ▸ 道具图标 20 张（需先扩展代码支持图标系统）
第5批 ▸ 粒子特效 8 张（锦上添花）
```

**即插即用（无需改代码）**：第1批 + 第2批 = 32 张
**需我扩展代码支持**：第3-5批的部分项目

---

## 九、当前项目已支持的自动加载路径

```
assets/textures/ui/panels/          → panel_bg.png, panel_header.png
assets/textures/ui/buttons/         → btn_normal/hover/pressed/gold/danger.png
assets/textures/ui/decorations/     → border_frame.png, divider.png, cloud_pattern.png
assets/textures/bg/                 → bg_main.png, bg_sect.png
assets/textures/portraits/          → {弟子名}.png
```

只要把 PNG 按上述路径放好，重启游戏即生效。不需要改任何代码。
