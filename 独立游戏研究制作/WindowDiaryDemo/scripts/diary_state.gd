extends Node
## Local-only state for the playable Window Diary demonstration.
signal changed

const SAVE_VERSION: int = 2
const DAY: float = 86400.0
const MAX_OFFLINE_DAYS: int = 30
const KEEPSAKE_VISITS: int = 5
const ATTRACTION_DEFS: Dictionary = {
 "seeds": {"name":"谷物食盘", "description":"在食盘里留一小撮谷物，让熟悉的枝头来客多一点停留的理由。"},
 "fruit": {"name":"果实小篮", "description":"一只盛着小果实的篮子，让爱探看的小邻居更容易注意到窗边。"},
 "flowers": {"name":"花草角", "description":"把花盆和绿叶摆在一起，为喜欢花叶与水光的访客留出安静角落。"},
 "lantern": {"name":"暖光小灯", "description":"一盏柔和的小灯，让暮色与月夜里的访客更愿意在附近停留。"}
}
const NORMAL_IDS: Array[String] = ["sparrow", "tit", "robin", "butterfly", "squirrel", "woodpecker", "swallow", "magpie", "white_eye", "hedgehog", "cat", "bat", "dragonfly", "ladybug"]
const RARE_IDS: Array[String] = ["ufo", "meteor", "supernova", "owl", "luna_moth", "jewel_beetle", "fireflies", "aurora", "star_whale", "time_ripple", "tree_spirit", "kingfisher", "egret", "stag_beetle", "lanterns", "ghost_train", "moon_gate", "signal_echo", "aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const ENTRY_DEFS: Dictionary = {
 "sparrow": {
  "name": "麻雀",
  "type": "阳台来客",
  "rarity": "常见",
  "category": "birds",
  "habitat": "低枝与喂鸟食盘",
  "behavior": "张望、停歇、啄食",
  "condition": "晴日、听雨、夕照、落雪、晨雾、风雨、晨曦时，留意低枝与喂鸟食盘。",
  "description": "先在树枝上张望，再落到食盘旁。熟悉的身影，也有新的小动作。",
  "hint": "看看树枝和喂鸟食盘。",
  "color": "bba184",
  "weather_ids": [
   0,
   1,
   3,
   4,
   5,
   6,
   7
  ],
  "personality": "热心又有点警觉",
  "attraction_id": "seeds",
  "preference": "喜欢谷物食盘旁的熟悉角落。",
  "keepsake_name": "一根小羽毛",
  "keepsake_description": "灰褐色的小羽毛落在食盘边，像一声轻轻的谢谢。"
 },
 "tit": {
  "name": "山雀",
  "type": "树梢来客",
  "rarity": "常见",
  "category": "birds",
  "habitat": "树冠边缘的高枝",
  "behavior": "停歇、梳羽、靠近食盘",
  "condition": "晴日、听雨、夕照、落雪、晨雾、风雨、晨曦时，留意树冠边缘的高枝。",
  "description": "轻巧地在枝头停歇，偶尔歪着头，好像也在观察这扇窗。",
  "hint": "留意树冠边缘的小小身影。",
  "color": "b5c9a1",
  "weather_ids": [
   0,
   1,
   3,
   4,
   5,
   6,
   7
  ],
  "personality": "轻巧的好奇心",
  "attraction_id": "seeds",
  "preference": "偏爱能停一下再探看的谷物食盘。",
  "keepsake_name": "细枝书签",
  "keepsake_description": "一小截细枝恰好可以夹在书里，留下树梢的气息。"
 },
 "robin": {
  "name": "知更鸟",
  "type": "树梢来客",
  "rarity": "特别",
  "category": "birds",
  "habitat": "低枝与树影之间",
  "behavior": "张望、等待、来访",
  "condition": "晴日、听雨、夕照、落雪、晨雾、风雨、晨曦时，留意低枝与树影之间。",
  "description": "温暖的橙色胸羽，为安静的树影添了一点颜色。",
  "hint": "安静等待枝头的新访客。",
  "color": "df9b73",
  "weather_ids": [
   0,
   1,
   3,
   4,
   5,
   6,
   7
  ],
  "personality": "慢热的邻居",
  "attraction_id": "flowers",
  "preference": "喜欢花草角旁安静的低枝。",
  "keepsake_name": "暖色落羽",
  "keepsake_description": "一片带着暖色的小羽毛，把那次相遇留了下来。"
 },
 "butterfly": {
  "name": "白蝶",
  "type": "花边来客",
  "rarity": "常见",
  "category": "insects",
  "habitat": "阳台花盆周围",
  "behavior": "绕花飞行、缓慢盘旋",
  "condition": "晴日、夕照、晨曦时，留意阳台花盆周围。",
  "description": "绕过一片叶子，再轻轻停在花边。雨停之后，阳台慢慢热闹起来。",
  "hint": "晴天的花盆边，也许会有翅膀轻轻闪动。",
  "color": "eee3ba",
  "weather_ids": [
   0,
   3,
   7
  ],
  "personality": "随风散步",
  "attraction_id": "flowers",
  "preference": "偏爱花草角的叶片与花朵。",
  "keepsake_name": "花瓣信笺",
  "keepsake_description": "一片完整的小花瓣，边缘像被轻轻吻过。"
 },
 "squirrel": {
  "name": "松鼠",
  "type": "树干来客",
  "rarity": "特别",
  "category": "animals",
  "habitat": "树干、分叉枝与食盘附近",
  "behavior": "攀爬、跃枝、抱着果实啃食、甩尾张望",
  "condition": "晴日、夕照、晨曦时，留意树干、分叉枝与食盘附近。",
  "description": "它沿树干爬到枝头，抱住一颗果实，啃两口又抬头看看窗边。蓬松的尾巴轻轻摆动，像是在向你打招呼。",
  "hint": "晴日的树干上，可能有一条蓬松尾巴。",
  "color": "b88b62",
  "weather_ids": [
   0,
   3,
   7
  ],
  "personality": "忙里偷闲",
  "attraction_id": "fruit",
  "preference": "常在果实小篮附近多停一会儿。",
  "keepsake_name": "光亮的小果壳",
  "keepsake_description": "半枚干净的果壳留在盆沿，里面恰好盛住一滴光。"
 },
 "woodpecker": {
  "name": "啄木鸟",
  "type": "树干来客",
  "rarity": "特别",
  "category": "birds",
  "habitat": "树干侧面与高枝",
  "behavior": "贴树停歇、轻敲树干、停下来侧头听",
  "condition": "晴日、夕照、晨曦时，留意树干侧面与高枝。",
  "description": "几下轻敲之后，它停下来侧过头。树干仿佛成了小小的节拍器，给窗边的安静添了一点节奏。",
  "hint": "树干旁的红色小点，会不会正在轻敲？",
  "color": "c47c67",
  "weather_ids": [
   0,
   3,
   7
  ],
  "personality": "认真打拍子",
  "attraction_id": "seeds",
  "preference": "喜欢谷物食盘附近可以落脚的树干。",
  "keepsake_name": "敲出节奏的树皮",
  "keepsake_description": "一小片树皮带着浅浅纹路，像写了一行短乐谱。"
 },
 "owl": {
  "name": "林鸮",
  "type": "夜间树梢来客",
  "rarity": "稀有",
  "category": "birds",
  "habitat": "月色下的高枝与树冠边缘",
  "behavior": "落枝、眨眼、转头张望、舒展双翼",
  "condition": "月夜时，留意月色下的高枝与树冠边缘。",
  "description": "它在高枝上眨眨眼，再慢慢转头，好像也想知道窗内的人在读什么。夜色里，多了一位安静的邻居。",
  "hint": "夜深后，高枝上可能有一双安静的眼睛。",
  "color": "b6aaa0",
  "weather_ids": [
   2
  ],
  "personality": "安静的夜读者",
  "attraction_id": "lantern",
  "preference": "偏爱暖光小灯映不到的高枝边缘。",
  "keepsake_name": "月色软羽",
  "keepsake_description": "一片柔软的羽毛，像夹住了一小段月色。"
 },
 "luna_moth": {
  "name": "月蛾",
  "type": "夜间花边来客",
  "rarity": "稀有",
  "category": "insects",
  "habitat": "月夜的花盆与树叶之间",
  "behavior": "缓慢振翅、绕叶盘旋、短暂停落",
  "condition": "月夜时，留意月夜的花盆与树叶之间。",
  "description": "浅绿色翅影绕过叶尖，像一张被风翻动的小纸片。它在月光与树影之间盘旋，把夜晚飞得很慢。",
  "hint": "月光里的浅绿色翅膀，和白天的蝶不一样。",
  "color": "b8d0ac",
  "weather_ids": [
   2
  ],
  "personality": "慢慢绕路",
  "attraction_id": "lantern",
  "preference": "常在暖光小灯附近的叶影间盘旋。",
  "keepsake_name": "浅绿叶签",
  "keepsake_description": "一片淡绿色小叶，形状让人想起舒展的翅膀。"
 },
 "jewel_beetle": {
  "name": "宝石甲虫",
  "type": "雨中树干来客",
  "rarity": "稀有",
  "category": "insects",
  "habitat": "树干背雨的一侧与叶片下方",
  "behavior": "沿树皮爬行、停步探触角、甲壳泛光",
  "condition": "听雨、晨雾时，留意树干背雨的一侧与叶片下方。",
  "description": "它在树皮间慢慢爬，转身时甲壳闪过宝石般的颜色。雨声很大，这一小点青绿却悄无声息。",
  "hint": "雨幕之外，树干背面也藏着小小的颜色。",
  "color": "70b7ab",
  "weather_ids": [
   1,
   5
  ],
  "personality": "不声张的亮色",
  "attraction_id": "fruit",
  "preference": "喜欢果实小篮附近的粗糙树皮。",
  "keepsake_name": "青绿石子",
  "keepsake_description": "一颗有青绿色纹路的小石子，转动时会闪一下。"
 },
 "fireflies": {
  "name": "萤火虫群",
  "type": "夜间叶间来客",
  "rarity": "稀有",
  "category": "insects",
  "habitat": "夜色中的树叶、花盆与阳台外侧",
  "behavior": "低低盘旋、错落明灭、聚散成小群",
  "condition": "月夜时，留意夜色中的树叶、花盆与阳台外侧。",
  "description": "几枚小灯在叶片间一明一暗，轻轻散开又聚拢。像一封没有文字的信，只在夜色里读得清楚。",
  "hint": "树叶附近的光，有时会自己慢慢移动。",
  "color": "d4d896",
  "weather_ids": [
   2
  ],
  "personality": "结伴的小灯",
  "attraction_id": "flowers",
  "preference": "偏爱花草角附近的柔暗叶影。",
  "keepsake_name": "微光草穗",
  "keepsake_description": "一根细草穗留在窗沿，想起它就像又看见几枚小灯。"
 },
 "ufo": {
  "name": "不明飞行物",
  "type": "天空奇遇",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "雪山上方的天空",
  "behavior": "掠过、停顿、留下光斑",
  "condition": "晴日、听雨、月夜、夕照、落雪、晨雾、风雨、晨曦时，留意雪山上方的天空。",
  "description": "一道不寻常的光划过窗外。树上的鸟安静了一瞬，河面留下淡淡光斑。",
  "hint": "有些奇遇会被日记悄悄记下。",
  "color": "9acbcd",
  "weather_ids": [
   0,
   1,
   2,
   3,
   4,
   5,
   6,
   7
  ]
 },
 "meteor": {
  "name": "流星",
  "type": "天空奇遇",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "开阔的夜空",
  "behavior": "划过、渐隐",
  "condition": "月夜时，留意开阔的夜空。",
  "description": "一条短暂的光线划过天际。愿望可以慢慢想，这一刻已经留下来了。",
  "hint": "天空里也有值得收藏的瞬间。",
  "color": "e6c589",
  "weather_ids": [
   2
  ]
 },
 "supernova": {
  "name": "远方的新星",
  "type": "天空奇遇",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "远处的星空",
  "behavior": "星点渐亮、光晕渐隐",
  "condition": "月夜时，留意远处的星空。",
  "description": "远处的星点渐渐亮起，给熟悉的夜空添了一圈温柔的光。也许这份遥远的问候，已经走了很长的路。",
  "hint": "偶尔，熟悉的天空会多一点不同。",
  "color": "c4b5e3",
  "weather_ids": [
   2
  ]
 },
 "aurora": {
  "name": "极光",
  "type": "夜空奇遇",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "雪山上方的夜空",
  "behavior": "光带舒展、缓慢起伏、映亮远山",
  "condition": "月夜时，留意雪山上方的夜空。",
  "description": "淡绿与浅紫的光带在雪山上舒展，像夜空轻轻掀开了一道帘。山和河都跟着安静地亮了一点。",
  "hint": "月夜里，雪山上方的天空可能像帘子一样轻动。",
  "color": "8ac9b2",
  "weather_ids": [
   2
  ]
 },
 "star_whale": {
  "name": "星鲸",
  "type": "幻想天空奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "雪山与星空之间",
  "behavior": "游过星海、摆尾、洒落星屑、渐渐隐去",
  "condition": "月夜时，留意雪山与星空之间。",
  "description": "一条由星光组成的鲸缓缓游过雪山，把尾鳍摆成一小片银河，然后消失在更深的蓝色里。",
  "hint": "有时，星空看起来像一片可以游泳的海。",
  "color": "a6b9dc",
  "weather_ids": [
   2
  ]
 },
 "time_ripple": {
  "name": "时间涟漪",
  "type": "幻想空间奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "树影与河流之间的空气",
  "behavior": "光环展开、波纹错位、余影缓慢散开",
  "condition": "晴日、月夜、夕照、晨雾时，留意树影与河流之间的空气。",
  "description": "窗外短暂浮起一圈圈光纹，像水面上的涟漪走进空气。熟悉的山影轻轻晃动，仿佛这一刻愿意多停留一会儿。",
  "hint": "没有雨的时候，空气里也可能泛起涟漪。",
  "color": "b8aad4",
  "weather_ids": [
   0,
   2,
   3,
   5
  ]
 },
 "tree_spirit": {
  "name": "树灵",
  "type": "幻想林间奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "老树的枝杈与叶影之间",
  "behavior": "微光聚拢、探头、轻轻摇摆、散成叶光",
  "condition": "晴日、月夜、夕照、晨雾、晨曦时，留意老树的枝杈与叶影之间。",
  "description": "叶影里聚起一小团光，好奇地探出头，又像怕打扰你一样躲回树枝，最后散成几颗细小的亮点。",
  "hint": "树上偶尔会来一位不属于鸟类的小邻居。",
  "color": "bed3a2",
  "weather_ids": [
   0,
   2,
   3,
   5,
   7
  ]
 },
 "scene_sun": {
  "name": "晴日树影",
  "type": "晴日风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "窗台、树冠与河流",
  "behavior": "树影轻摇、水面闪光",
  "condition": "选择晴日，安静观察约八秒。",
  "description": "日光落在花盆和窗台上，河水有细小的亮光。远处雪山清晰，树上的来客也慢慢活跃起来。",
  "hint": "在晴光里停留一会儿。",
  "color": "d9c792",
  "weather_ids": [
   0
  ]
 },
 "scene_rain": {
  "name": "雨幕中的河谷",
  "type": "雨天风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "窗外雨幕与远山",
  "behavior": "雨丝落下、薄雾掩山、涟漪扩散",
  "condition": "选择听雨，安静观察约八秒。",
  "description": "云层压低，远山藏进水汽。窗外的雨声和河水混在一起，近处的叶子与屋檐变得更清楚。",
  "hint": "让雨声陪你看一会儿窗外。",
  "color": "829ea6",
  "weather_ids": [
   1
  ]
 },
 "scene_night": {
  "name": "星夜暖窗",
  "type": "夜间风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "邻窗、夜空与河面",
  "behavior": "窗灯亮起、星光微动、月色倒映",
  "condition": "选择月夜，安静观察约八秒。",
  "description": "远处山脊沉入蓝色，邻窗透出一盏暖灯。树枝安静下来，河面留下夜色与光的倒影。",
  "hint": "在夜色中停留，看看哪扇窗亮着。",
  "color": "8b9bc3",
  "weather_ids": [
   2
  ]
 },
 "scene_dusk": {
  "name": "暮色归舟",
  "type": "黄昏风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "雪山、屋顶与河湾",
  "behavior": "暖光渐低、长影移动、河面染色",
  "condition": "选择夕照，安静观察约八秒。",
  "description": "最后一束暖光停在屋顶和雪山上。河面从蓝色转向柔和的金色，整个小城慢慢安静下来。",
  "hint": "在黄昏里留住一小段暖光。",
  "color": "d6a582",
  "weather_ids": [
   3
  ]
 },
 "scene_snow": {
  "name": "初雪静窗",
  "type": "雪天风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "树枝、屋顶与窗外河谷",
  "behavior": "雪花飘落、积雪覆枝、雾气变淡",
  "condition": "选择落雪，安静观察约八秒。",
  "description": "一层薄雪盖住树枝和屋顶，远近的声音都轻了下来。窗边仍有暖意，偶尔的来客让冬日更有生气。",
  "hint": "在落雪的窗边停留一会儿。",
  "color": "b7c8ce",
  "weather_ids": [
   4
  ]
 },
 "kingfisher": {
  "name": "翠鸟",
  "type": "水边来客",
  "rarity": "稀有",
  "category": "birds",
  "habitat": "河岸低枝与水面上方",
  "behavior": "俯身张望、贴水掠过、回枝停歇",
  "description": "一抹蓝色贴着水面掠过，又轻轻落回低枝。河面恢复平静之后，它还在耐心地等。",
  "hint": "晨光里的河岸，也许藏着一小片蓝。",
  "color": "579ea9",
  "weather_ids": [
   0,
   5,
   7
  ],
  "condition": "晴日、晨雾、晨曦时，留意河岸低枝与水面上方。",
  "personality": "耐心等一瞬",
  "attraction_id": "flowers",
  "preference": "喜欢花草角外侧能望向河面的枝头。",
  "keepsake_name": "水色小石",
  "keepsake_description": "一枚光滑的浅蓝石子，仿佛刚从河光里取出来。"
 },
 "swallow": {
  "name": "燕子",
  "type": "空中来客",
  "rarity": "常见",
  "category": "birds",
  "habitat": "屋檐、河湾与开阔天空",
  "behavior": "振翅、滑翔、划出弧线",
  "description": "细细的翅尖划过屋檐，把天空缝成一条轻快的弧线。转眼间，它又绕回来了。",
  "hint": "晴空与夕光里，留意屋檐上方的剪影。",
  "color": "697c91",
  "weather_ids": [
   0,
   3
  ],
  "condition": "晴日、夕照时，留意屋檐、河湾与开阔天空。",
  "personality": "轻快的远行者",
  "attraction_id": "seeds",
  "preference": "常从谷物食盘上方的开阔处掠过。",
  "keepsake_name": "弧线细草",
  "keepsake_description": "一根弯弯的细草，像它划过天空时留下的路线。"
 },
 "magpie": {
  "name": "喜鹊",
  "type": "树梢来客",
  "rarity": "特别",
  "category": "birds",
  "habitat": "高枝与阳台栏杆",
  "behavior": "落枝、翘尾、左右探看",
  "description": "它落下时尾巴轻轻一翘，随后左右看看，像在检查这条街今天有没有新鲜事。",
  "hint": "枝头黑白相间的来客，常带着一点好奇。",
  "color": "637c89",
  "weather_ids": [
   0,
   3,
   7
  ],
  "condition": "晴日、夕照、晨曦时，留意高枝与阳台栏杆。",
  "personality": "街角观察员",
  "attraction_id": "fruit",
  "preference": "对果实小篮旁的新鲜摆设格外好奇。",
  "keepsake_name": "银亮小圆片",
  "keepsake_description": "一枚被磨得光亮的小圆片，映出一小块天空。"
 },
 "white_eye": {
  "name": "绣眼鸟",
  "type": "花果来客",
  "rarity": "特别",
  "category": "birds",
  "habitat": "花盆边缘与细枝",
  "behavior": "歪头、跳枝、探看果实",
  "description": "小小的白眼圈在绿叶间一闪。它沿细枝跳近，又在果子旁停住，像是在认真挑选。",
  "hint": "果篮旁的细枝上，也许有一圈小小的白。",
  "color": "a3b878",
  "weather_ids": [
   0,
   3,
   7
  ],
  "condition": "晴日、夕照、晨曦时，留意花盆边缘与细枝。",
  "personality": "挑挑拣拣",
  "attraction_id": "fruit",
  "preference": "偏爱果实小篮和旁边的细枝。",
  "keepsake_name": "果香叶片",
  "keepsake_description": "一片小叶托着淡淡果香，边缘有个漂亮的弧度。"
 },
 "egret": {
  "name": "白鹭",
  "type": "水岸来客",
  "rarity": "稀有",
  "category": "birds",
  "habitat": "浅水岸边与河湾",
  "behavior": "缓步、停驻、展翅掠水",
  "description": "白色的身影把脚步放得很轻。它在水边停了好一会儿，连倒影都像睡着了。",
  "hint": "晨雾散开时，看看水岸的白色身影。",
  "color": "d5e2db",
  "weather_ids": [
   0,
   5,
   7
  ],
  "condition": "晴日、晨雾、晨曦时，留意浅水岸边与河湾。",
  "personality": "把脚步放轻",
  "attraction_id": "flowers",
  "preference": "喜欢从花草角望出去的清静水岸。",
  "keepsake_name": "白色细羽",
  "keepsake_description": "一根细白羽毛，轻得像水面上的一笔留白。"
 },
 "hedgehog": {
  "name": "刺猬",
  "type": "晚间小邻居",
  "rarity": "特别",
  "category": "animals",
  "habitat": "树根、花盆与阳台外沿",
  "behavior": "探头、慢走、嗅闻、短暂停步",
  "description": "小鼻子先从花盆后面出现，接着是一团慢慢移动的小刺。它走走停停，似乎每片叶子都值得闻一闻。",
  "hint": "夕照后，花盆后面的叶子可能会轻轻动。",
  "color": "ad987e",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜、夕照时，留意树根、花盆与阳台外沿。",
  "personality": "谨慎的小夜游",
  "attraction_id": "fruit",
  "preference": "对果实小篮周围的落叶角落很感兴趣。",
  "keepsake_name": "卷卷落叶",
  "keepsake_description": "一片卷成小船的落叶，静静停在花盆后面。"
 },
 "cat": {
  "name": "窗边猫",
  "type": "邻里来客",
  "rarity": "特别",
  "category": "animals",
  "habitat": "屋檐、阳台角落与窗外台阶",
  "behavior": "踱步、伸懒腰、眯眼、摆尾",
  "description": "它选好一处安静角落，慢慢伸了个懒腰。你继续读书，它继续看窗外，谁也不必急着说话。",
  "hint": "傍晚的暖光里，可能多了一条懒洋洋的尾巴。",
  "color": "c9b59b",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜、夕照时，留意屋檐、阳台角落与窗外台阶。",
  "personality": "自在的陪读员",
  "attraction_id": "lantern",
  "preference": "偏爱暖光小灯旁的一小块安静地面。",
  "keepsake_name": "柔软线团",
  "keepsake_description": "一小团松松的线，像是认真挑过才放在窗边。"
 },
 "bat": {
  "name": "蝙蝠",
  "type": "暮夜来客",
  "rarity": "特别",
  "category": "animals",
  "habitat": "屋檐与河湾上方",
  "behavior": "振翅、折返、贴檐飞行",
  "description": "一个小小的轮廓从屋檐下飞出，在暮色里轻巧地折返。夜晚的天空，也有自己的忙碌。",
  "hint": "夕照转暗的时候，抬头看看屋檐。",
  "color": "8c82a1",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜、夕照时，留意屋檐与河湾上方。",
  "personality": "暮色里的折返",
  "attraction_id": "lantern",
  "preference": "常从暖光小灯外侧的屋檐附近经过。",
  "keepsake_name": "深蓝小石",
  "keepsake_description": "一颗深蓝色小石子，像凝住了屋檐下的暮色。"
 },
 "dragonfly": {
  "name": "蜻蜓",
  "type": "水畔小客",
  "rarity": "常见",
  "category": "insects",
  "habitat": "水面、花盆与细枝尖端",
  "behavior": "悬停、轻点水面、短促转向",
  "description": "它在水面上方悬停，翅膀像两片透明的小窗。忽然一个转身，又停在了另一束光里。",
  "hint": "晴光下的水面，有时会停着一架小小的透明飞机。",
  "color": "8bbfc0",
  "weather_ids": [
   0,
   3,
   7
  ],
  "condition": "晴日、夕照、晨曦时，留意水面、花盆与细枝尖端。",
  "personality": "悬停的旅行家",
  "attraction_id": "flowers",
  "preference": "喜欢花草角与水面之间开阔的位置。",
  "keepsake_name": "透明叶脉",
  "keepsake_description": "一片只剩细细叶脉的小叶，轻得像透明的翅膀。"
 },
 "ladybug": {
  "name": "瓢虫",
  "type": "叶上小客",
  "rarity": "常见",
  "category": "insects",
  "habitat": "花叶、窗台与盆沿",
  "behavior": "爬叶、探触角、停在叶尖",
  "description": "红色小圆点爬过叶脉，走到叶尖后停下来。对于它，一片叶子也许就是一座小山。",
  "hint": "花盆里那枚会移动的红点，很值得靠近看看。",
  "color": "c88574",
  "weather_ids": [
   0,
   3,
   7
  ],
  "condition": "晴日、夕照、晨曦时，留意花叶、窗台与盆沿。",
  "personality": "认真走完一片叶",
  "attraction_id": "flowers",
  "preference": "偏爱花草角里可以慢慢爬的宽叶。",
  "keepsake_name": "圆点种子",
  "keepsake_description": "一粒带着小斑点的种子，安稳地躺在盆沿。"
 },
 "stag_beetle": {
  "name": "锹甲",
  "type": "暮夜树干来客",
  "rarity": "稀有",
  "category": "insects",
  "habitat": "树皮、枝杈与果篮旁",
  "behavior": "攀爬、触角轻探、停步张望",
  "description": "它沿树皮缓慢攀上来，头前的弧线像一副小小的枝杈。暮色再深一点，也不妨碍它慢慢走。",
  "hint": "夕照与月夜里，树干上可能有一位戴着枝杈的访客。",
  "color": "9e8e76",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜、夕照时，留意树皮、枝杈与果篮旁。",
  "personality": "慢慢攀高",
  "attraction_id": "fruit",
  "preference": "喜欢果实小篮附近的树干与枝杈。",
  "keepsake_name": "分叉小枝",
  "keepsake_description": "一截漂亮的分叉细枝，像它送来的一幅小剪影。"
 },
 "lanterns": {
  "name": "河灯",
  "type": "水面奇遇",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "河湾与缓缓流动的水面",
  "behavior": "漂流、摇曳、倒影拉长",
  "description": "几盏小灯顺着河水慢慢远去，暖色的倒影被波纹揉开。也许每一盏，都装着一句还没说完的话。",
  "hint": "夕照或月夜里，看看河面是否多了几盏暖灯。",
  "color": "d5b67d",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜、夕照时，留意河湾与缓缓流动的水面。"
 },
 "ghost_train": {
  "name": "雾中列车",
  "type": "幻想远景奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "远山前的雾带与河岸",
  "behavior": "车窗依次亮起、穿雾、渐隐",
  "description": "一串暖窗从雾里经过，却听不到远行的喧哗。等你再看清远山，列车已经驶进另一段故事。",
  "hint": "晨雾或风雨里，远处的灯会不会排成一列？",
  "color": "b6c6c3",
  "weather_ids": [
   5,
   6
  ],
  "condition": "晨雾、风雨时，留意远山前的雾带与河岸。"
 },
 "moon_gate": {
  "name": "月亮门",
  "type": "幻想天空奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "河谷上方与月色深处",
  "behavior": "光环凝聚、门影展开、缓慢淡去",
  "description": "月光在空气里合成一道圆门。门后仍是熟悉的山，却好像多了一条只在梦里走过的小路。",
  "hint": "月夜或晨雾里，留意河谷上方不寻常的圆。",
  "color": "c8c6dd",
  "weather_ids": [
   2,
   5
  ],
  "condition": "月夜、晨雾时，留意河谷上方与月色深处。"
 },
 "signal_echo": {
  "name": "信号回声",
  "type": "幻想塔影奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "远处灯塔与开阔水面",
  "behavior": "塔灯闪烁、光波扩散、水面回应",
  "description": "塔顶的灯多闪了几下，水面随后浮起一圈淡光。像是很远的地方，终于收到了窗边的一声问候。",
  "hint": "雨雾、风雨与月夜中，试着数一数远处塔灯的节奏。",
  "color": "a5c9c5",
  "weather_ids": [
   1,
   2,
   5,
   6
  ],
  "condition": "听雨、月夜、晨雾、风雨时，留意远处灯塔与开阔水面。"
 },
 "scene_fog": {
  "name": "晨雾",
  "type": "雾中风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "宽阔水面、远塔与河岸",
  "behavior": "薄雾漂移、塔灯明灭、水岸渐隐",
  "description": "雾把远山与河岸轻轻折起来，只留下宽阔的水面。远处那一点灯光，让距离有了温柔的形状。",
  "hint": "让晨雾陪你停留一会儿。",
  "color": "b7c9c6",
  "weather_ids": [
   5
  ],
  "condition": "选择晨雾，安静观察约八秒。"
 },
 "scene_storm": {
  "name": "风雨",
  "type": "风雨风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "外窗、树冠与远处水面",
  "behavior": "雨丝倾斜、枝叶摆动、塔灯穿雾",
  "description": "雨斜斜地穿过窗外，树冠跟着风轻轻弯下。远处的塔灯仍按自己的节奏亮着，窗内因此更安稳。",
  "hint": "风雨越过河面时，找找远处没有熄灭的灯。",
  "color": "7f939f",
  "weather_ids": [
   6
  ],
  "condition": "选择风雨，安静观察约八秒。"
 },
 "scene_dawn": {
  "name": "晨曦",
  "type": "清晨风景",
  "rarity": "风景",
  "category": "scenery",
  "habitat": "窗台、宽阔河面与山脊",
  "behavior": "光线铺开、水面泛金、来客苏醒",
  "description": "第一层暖光越过山脊，在水上铺成一条细长的路。花盆和食盘先亮起来，新的一天从窗边慢慢开始。",
  "hint": "在晨曦里留住今天的第一束光。",
  "color": "e0c8a0",
  "weather_ids": [
   7
  ],
  "condition": "选择晨曦，安静观察约八秒。"
 },
 "aurora_crown": {
  "name": "极光冠冕",
  "type": "天空奇观",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "雪山上方与夜空深处",
  "behavior": "光柱汇聚、冠环展开、丝带垂落",
  "weather_ids": [
   2
  ],
  "condition": "月夜时，等待雪山上方的光带向天空中央汇聚。",
  "description": "细长的光柱在高处相遇，慢慢展开一顶没有重量的冠冕。山脊安静地伏在下面，像是夜空临时借走了所有颜色。",
  "hint": "平缓的极光之外，还有一种会向天顶聚拢的光。",
  "color": "a9d1bd"
 },
 "ember_clouds": {
  "name": "绯霞漫天",
  "type": "暮色奇观",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "山脊、晚云与开阔水面",
  "behavior": "云层渐红、霞光铺展、余晖映水",
  "weather_ids": [
   3
  ],
  "condition": "夕照时，留意山脊上方逐渐染红的云层。",
  "description": "一层绯红从云边慢慢铺开，像有人把一封温暖的信展开在天上。水面接住余晖，又把它揉成细碎的金。",
  "hint": "夕照里的云，有时会比往常多停留一抹红。",
  "color": "d99b8c"
 },
 "meteor_shower": {
  "name": "流星雨",
  "type": "夜空奇观",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "开阔夜空与远山上方",
  "behavior": "光迹交错、接连掠过、余光渐隐",
  "weather_ids": [
   2
  ],
  "condition": "月夜时，等待几道光迹接连划过远山上方。",
  "description": "第一道光掠过之后，第二道、第三道也赶来了。还没想好愿望，夜空已经替窗边留下了满满一页。",
  "hint": "一颗流星之后，也许还有下一颗。",
  "color": "e3d4b7"
 },
 "deep_one": {
  "name": "潮下旧神",
  "type": "幻想水域奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "夜色、晨雾或风雨中的远处深水",
  "behavior": "水雾退开、古老剪影升起、触腕缓展、沉回暗潮",
  "weather_ids": [
   2,
   5,
   6
  ],
  "condition": "月夜、晨雾或风雨中，留意远处水面缓缓升起的巨大轮廓。",
  "description": "远水忽然变得很静，一道古老的轮廓从雾里升起，弯曲的触腕像几段陌生的岸线。它停留片刻，又把秘密带回了潮下。",
  "hint": "最远处的深水里，有时会多出一块不属于山的影子。",
  "color": "788e93"
 },
 "sunken_city": {
  "name": "沉城浮影",
  "type": "幻想水域奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "晨雾或月夜中的河湾远水",
  "behavior": "楼影浮现、塔尖微亮、倒影错位、缓缓沉没",
  "weather_ids": [
   5,
   2
  ],
  "condition": "晨雾或月夜时，观察远水里逐渐清晰的陌生楼影。",
  "description": "雾下浮出一座没有在岸上见过的城，细小的塔尖亮了又暗。等一阵波纹经过，街道与窗灯就都沉回水中。",
  "hint": "河里有时会映出一座岸上没有的城。",
  "color": "9cb4bd"
 },
 "sky_jellyfish": {
  "name": "星海水母",
  "type": "幻想天空奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "月夜的远山与星空之间",
  "behavior": "伞盖轻缩、缓缓漂游、星丝拖曳、渐隐",
  "weather_ids": [
   2
  ],
  "condition": "月夜时，留意远山上方缓缓漂浮的透明光伞。",
  "description": "几把透明的小伞在星空里一收一放，细细的光丝落向看不见的海。它们漂得很慢，仿佛整个夜晚都没有风。",
  "hint": "夜空里的小光团，也许会像水母一样呼吸。",
  "color": "bdc6e4"
 },
 "twin_moons": {
  "name": "双月临空",
  "type": "幻想天空奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "山脊上方的月夜天空",
  "behavior": "第二轮月影浮现、双辉交叠、浅月渐退",
  "weather_ids": [
   2
  ],
  "condition": "月夜时，看看熟悉的月亮旁是否多了一轮浅淡月影。",
  "description": "一轮浅淡的月亮慢慢来到另一轮身旁。两道月光在水上并行了一小段，随后其中一道悄悄回到了梦里。",
  "hint": "今晚的水面，会不会有两条月光铺成的路？",
  "color": "ddd8c6"
 },
 "floating_isles": {
  "name": "浮空群岛",
  "type": "幻想远景奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "晴日、晨曦或晨雾中的山谷上空",
  "behavior": "岛影浮起、群岛错落漂移、云丝绕行",
  "weather_ids": [
   0,
   7,
   5
  ],
  "condition": "晴日、晨曦或晨雾时，留意山谷上空与地面分开的岛影。",
  "description": "几片长着树的小岛慢慢离开山谷，云从它们脚下穿过。岛上的影子落不到水面，像是一段还没有醒来的地理。",
  "hint": "雾散开的山谷里，有些轮廓也许没有连着地面。",
  "color": "a8bba1"
 },
 "bioluminescent_tide": {
  "name": "蓝潮来信",
  "type": "水面奇观",
  "rarity": "稀有",
  "category": "wonders",
  "habitat": "月夜或夕照后的弯曲水岸",
  "behavior": "蓝光沿岸浮起、波纹点亮、细光散开",
  "weather_ids": [
   2,
   3
  ],
  "condition": "月夜或夕照时，留意弯曲岸边一圈圈亮起的蓝光。",
  "description": "蓝色的微光沿着岸线一段段亮起，仿佛水在慢慢写信。波纹经过的地方都留了字，下一阵水又轻轻擦去。",
  "hint": "夜色里的岸边，可能有不来自窗灯的蓝光。",
  "color": "73c3d4"
 },
 "constellation_stag": {
  "name": "星座之鹿",
  "type": "幻想天空奇遇",
  "rarity": "传说",
  "category": "wonders",
  "habitat": "月夜的山脊与星群之间",
  "behavior": "星点相连、鹿影迈步、角枝舒展、散回星空",
  "weather_ids": [
   2
  ],
  "condition": "月夜时，留意山脊上方渐渐连成鹿形的星点。",
  "description": "几颗星先连成角，接着是轻盈的背与四蹄。那只鹿在山脊上方走过一步，随后又散回各自遥远的位置。",
  "hint": "熟悉的星点连起来，会不会正在轻轻迈步？",
  "color": "c7d6cf"
 }
}

var collection: Dictionary = {}
var records: Array = []
var favorites: Array[String] = []
var attraction: String = "seeds"
var seconds_focused: float = 0.0
var music_on: bool = true
var ambience_on: bool = true
var world_seed: int = 0
var last_seen_unix: float = 0.0
var timezone_bias_minutes: int = int(Time.get_time_zone_from_system().get("bias", 0))
var last_summary: String = ""
var rare_misses: int = 0
var simulation_count: int = 0
## Tests can select an isolated file before calling load_state().
var storage_path_override: String = ""
var _tokens: Dictionary = {}
var _batch_mutation: bool = false
var _tick_elapsed: float = 0.0

func _ready() -> void:
 load_state()
 settle_offline(Time.get_unix_time_from_system())

func _process(delta: float) -> void:
 _tick_elapsed += delta
 if _tick_elapsed >= 30.0:
  _tick_elapsed = 0.0
  settle_offline(Time.get_unix_time_from_system())

func _exit_tree() -> void:
 save_state()

func get_entry_defs() -> Dictionary:
 return ENTRY_DEFS

func get_count() -> int:
 return collection.size()

func get_attraction_defs() -> Dictionary:
 return ATTRACTION_DEFS

func set_attraction(id: String) -> bool:
 if not ATTRACTION_DEFS.has(id):
  return false
 if attraction == id:
  return true
 attraction = id
 save_state()
 changed.emit()
 return true

## Affinity and mementos are derived from the existing observation count.
## Reading a profile, replaying, or changing decor never awards a visit.
func get_profile(id: String) -> Dictionary:
 if not ENTRY_DEFS.has(id) or str(ENTRY_DEFS[id].get("category", "")) not in ["birds", "animals", "insects"]:
  return {}
 var definition: Dictionary = ENTRY_DEFS[id]
 var visits: int = maxi(0, int(collection.get(id, {}).get("count", 0)))
 var bond_label: String = "尚未相识"
 if visits >= 10:
  bond_label = "窗边老友"
 elif visits >= KEEPSAKE_VISITS:
  bond_label = "熟悉的邻居"
 elif visits >= 2:
  bond_label = "渐渐熟悉"
 elif visits == 1:
  bond_label = "初次相遇"
 return {"visits":visits, "bond_label":bond_label,
  "personality":str(definition.get("personality", "")),
  "preference":str(definition.get("preference", "")),
  "attraction_id":str(definition.get("attraction_id", "")),
  "keepsake_unlocked":visits >= KEEPSAKE_VISITS,
  "keepsake_name":str(definition.get("keepsake_name", "")),
  "keepsake_description":str(definition.get("keepsake_description", ""))}

func get_visit_pool(weather: int) -> Array[String]:
 return _weather_pool(NORMAL_IDS, weather)

func get_rare_pool(weather: int) -> Array[String]:
 return _weather_pool(RARE_IDS, weather)

func _weather_pool(ids: Array[String], weather: int) -> Array[String]:
 var eligible: Array[String] = []
 var mode: int = clampi(weather, 0, 7)
 for id: String in ids:
  if ENTRY_DEFS.has(id) and ENTRY_DEFS[id].get("weather_ids", []).has(mode):
   eligible.append(id)
 return _weighted_pool(eligible)

## Every eligible visitor keeps a base chance; a preferred decoration adds two.
func _weighted_pool(ids: Array[String]) -> Array[String]:
 var weighted: Array[String] = []
 for id: String in ids:
  if not ENTRY_DEFS.has(id):
   continue
  weighted.append(id)
  if str(ENTRY_DEFS[id].get("attraction_id", "")) == attraction:
   weighted.append(id)
   weighted.append(id)
 return weighted

func is_favorite(id: String) -> bool:
 return collection.has(id) and favorites.has(id)

## Favorites are a personal bookmark, never an unlock or observation reward.
func toggle_favorite(id: String) -> bool:
 if not collection.has(id) or not ENTRY_DEFS.has(id):
  return false
 if favorites.has(id):
  favorites.erase(id)
 else:
  favorites.append(id)
 save_state()
 changed.emit()
 return favorites.has(id)

## Attach atmosphere to an existing observation without registering it twice.
func record_context(id: String, weather_name: String) -> void:
 if not collection.has(id) or weather_name.strip_edges().is_empty():
  return
 var atmosphere: String = weather_name.strip_edges()
 if str(collection[id].get("last_weather", "")) == atmosphere:
  return
 collection[id]["last_weather"] = atmosphere
 if str(collection[id].get("first_weather", "")).is_empty():
  collection[id]["first_weather"] = atmosphere
 save_state()
 changed.emit()

func discover(id: String, note: String = "", unique_token: String = "") -> bool:
 return _register(id, note, unique_token, Time.get_unix_time_from_system())

func _register(id: String, note: String, token: String, timestamp: float) -> bool:
 if not ENTRY_DEFS.has(id):
  return false
 if not token.is_empty() and _tokens.has(token):
  return false
 var first: bool = not collection.has(id)
 var stamp: String = _date_label(timestamp)
 var name_text: String = str(ENTRY_DEFS[id]["name"])
 if first:
  collection[id] = {"name":name_text, "count":0, "first_seen":stamp, "last_seen":stamp, "first_timestamp":timestamp}
 collection[id]["count"] = int(collection[id].get("count", 0)) + 1
 collection[id]["last_seen"] = stamp
 collection[id]["last_timestamp"] = timestamp
 if not token.is_empty():
  _tokens[token] = true
 while _tokens.size() > 4096:
  _tokens.erase(_tokens.keys()[0])
 records.push_front({"id":id, "name":name_text, "note":note, "time":stamp, "timestamp":timestamp, "new":first})
 while records.size() > 120:
  records.pop_back()
 if not _batch_mutation:
  save_state()
  changed.emit()
 return first

## Returns newly added records in chronological order. Each real-world slot is
## deterministic; reopening or rolling the clock backward cannot reroll it.
func settle_offline(now_unix: float) -> Array:
 var added: Array = []
 if now_unix <= 0.0:
  return added
 if world_seed == 0:
  world_seed = int(now_unix) ^ 734729
 if last_seen_unix <= 0.0:
  last_seen_unix = now_unix
  if last_summary.is_empty():
   last_summary = "第一次来到窗边，日记从现在开始。"
  save_state()
  return added
 if now_unix <= last_seen_unix:
  return added
 var real_gap: float = now_unix - last_seen_unix
 var lower: float = maxf(last_seen_unix, now_unix - DAY * MAX_OFFLINE_DAYS)
 var shift: float = float(timezone_bias_minutes) * 60.0
 var start_day: int = int(floor((lower + shift) / DAY))
 var end_day: int = int(floor((now_unix + shift) / DAY))
 _batch_mutation = true
 for day_index in range(start_day, end_day + 1):
  for hour in [6, 12, 18, 20]:
   var event_time: float = day_index * DAY + float(hour) * 3600.0 - shift
   if event_time <= lower or event_time > now_unix:
    continue
   var token: String = "world:%d:%d" % [day_index, hour]
   if _tokens.has(token):
    continue
   var rng: RandomNumberGenerator = RandomNumberGenerator.new()
   rng.seed = hash("%d:%d:%d" % [world_seed, day_index, hour])
   if hour == 20:
    if rng.randf() < 0.10 or rare_misses >= 6:
     var pool: Array[String] = []
     if rare_misses >= 6:
      for candidate in RARE_IDS:
       if not collection.has(candidate):
        pool.append(candidate)
     if pool.is_empty():
      pool.assign(RARE_IDS)
     pool = _weighted_pool(pool)
     var rare_id: String = pool[rng.randi_range(0, pool.size() - 1)]
     _register(rare_id, "%s曾出现在窗外，错过的相遇已经为你留下。" % str(ENTRY_DEFS[rare_id]["name"]), token, event_time)
     added.append(records[0].duplicate(true))
     rare_misses = 0
    else:
     rare_misses += 1
     _tokens[token] = true
   else:
    var normal_pool: Array[String] = _weighted_pool(NORMAL_IDS)
    var normal_id: String = normal_pool[rng.randi_range(0, normal_pool.size() - 1)]
    _register(normal_id, "安静的来访已自动记入日记。", token, event_time)
    added.append(records[0].duplicate(true))
 _batch_mutation = false
 last_seen_unix = now_unix
 if real_gap > DAY * MAX_OFFLINE_DAYS:
  last_summary = "演示版补算最近 30 天，新增 %d 条观察；更早的间隔未补算。" % added.size()
 elif not added.is_empty():
  last_summary = "离开期间新增 %d 条观察，已经自动记入日记。" % added.size()
 elif last_summary.is_empty():
  last_summary = "窗外正在慢慢变化，新发现会自动留下。"
 save_state()
 if not added.is_empty():
  changed.emit()
 return added

## Explicit demonstration: adds illustrative records without moving the real
## clock, its settlement cursor, or real-world rare pity forward.
func simulate_offline(hours: int = 24) -> Array:
 var added: Array = []
 var safe_hours: int = clampi(hours, 1, 168)
 var old_cursor: float = last_seen_unix
 var now: float = Time.get_unix_time_from_system()
 simulation_count += 1
 var number: int = clampi(int(ceil(safe_hours / 8.0)), 1, 12)
 _batch_mutation = true
 for i in range(number):
  var id: String = NORMAL_IDS[(simulation_count + i) % NORMAL_IDS.size()]
  var token: String = "simulation:%d:%d" % [simulation_count, i]
  _register(id, "演示补算：模拟离开 %d 小时后的来访。" % safe_hours, token, now)
  added.append(records[0].duplicate(true))
 if safe_hours >= 24:
  var rare_id: String = RARE_IDS[(simulation_count - 1) % RARE_IDS.size()]
  _register(rare_id, "演示补算：一段已错过现场的稀有相遇，也可以回看。", "simulation:%d:rare" % simulation_count, now)
  added.append(records[0].duplicate(true))
 _batch_mutation = false
 last_seen_unix = old_cursor
 last_summary = "演示补算完成：%d 条模拟记录；真实时间未推进。" % added.size()
 save_state()
 changed.emit()
 return added

func _date_label(timestamp: float) -> String:
 var local_time: float = timestamp + float(timezone_bias_minutes) * 60.0
 var d: Dictionary = Time.get_datetime_dict_from_unix_time(int(local_time))
 return "%02d月%02d日 %02d:%02d" % [d.month, d.day, d.hour, d.minute]

func _save_path() -> String:
 if not storage_path_override.is_empty():
  return storage_path_override
 var args: PackedStringArray = OS.get_cmdline_user_args()
 if args.has("--capture"):
  return ""
 if args.has("--test-mode") or args.has("--ui-test"):
  return "user://window_diary_demo_test_save.json"
 return "user://window_diary_demo_save.json"

func save_state() -> void:
 var path: String = _save_path()
 if path.is_empty():
  return
 var payload: Dictionary = {"version":SAVE_VERSION, "collection":collection, "records":records, "favorites":favorites, "attraction":attraction,
  "seconds_focused":seconds_focused, "music_on":music_on, "ambience_on":ambience_on,
  "world_seed":world_seed, "last_seen_unix":last_seen_unix, "rare_misses":rare_misses,
  "simulation_count":simulation_count, "tokens":_tokens, "timezone_bias_minutes":timezone_bias_minutes}
 var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if file == null:
  push_warning("Could not write Window Diary demo save.")
  return
 file.store_string(JSON.stringify(payload))
 file.flush()
 file.close()
 if _read_payload(path).size() > 0:
  DirAccess.copy_absolute(path, path + ".bak")
 var error: Error = DirAccess.rename_absolute(path + ".tmp", path)
 if error != OK:
  # Windows can reject an atomic replacement when the target exists.
  var copy_error: Error = DirAccess.copy_absolute(path + ".tmp", path)
  if copy_error == OK:
   DirAccess.remove_absolute(path + ".tmp")
  else:
   push_warning("Could not replace Window Diary demo save.")

func _read_payload(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):
  return {}
 var parser: JSON = JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path)) != OK:
  return {}
 var value: Variant = parser.data
 if not (value is Dictionary):
  return {}
 if int(value.get("version", -1)) not in [1, SAVE_VERSION]:
  return {}
 if not (value.get("collection") is Dictionary) or not (value.get("records") is Array):
  return {}
 return value

func load_state() -> void:
 var path: String = _save_path()
 collection = {}
 records = []
 favorites.clear()
 attraction = "seeds"
 _tokens = {}
 last_seen_unix = 0.0
 last_summary = ""
 world_seed = int(Time.get_unix_time_from_system()) ^ 734729
 rare_misses = 0
 simulation_count = 0
 seconds_focused = 0.0
 music_on = true
 ambience_on = true
 if path.is_empty():
  return
 var data: Dictionary = _read_payload(path)
 if data.is_empty() and FileAccess.file_exists(path):
  data = _read_payload(path + ".bak")
  if data.is_empty():
   last_summary = "存档暂时无法读取，先从新日记开始；原文件保留在备份位置。"
   DirAccess.copy_absolute(path, path + ".unreadable")
  else:
   last_summary = "已从上一次可读的备份恢复日记。"
 if data.is_empty():
  return
 var saved_attraction: String = str(data.get("attraction", "seeds"))
 if ATTRACTION_DEFS.has(saved_attraction):
  attraction = saved_attraction
 for id in data["collection"]:
  var entry: Variant = data["collection"][id]
  if ENTRY_DEFS.has(id) and entry is Dictionary and int(entry.get("count", 0)) > 0:
   collection[id] = entry
 if data.get("favorites") is Array:
  for raw_id in data["favorites"]:
   var favorite_id: String = str(raw_id)
   if collection.has(favorite_id) and not favorites.has(favorite_id):
    favorites.append(favorite_id)
 for record in data["records"]:
  if record is Dictionary and ENTRY_DEFS.has(record.get("id", "")):
   records.append(record)
 while records.size() > 120:
  records.pop_back()
 seconds_focused = maxf(float(data.get("seconds_focused", 0)), 0.0)
 music_on = bool(data.get("music_on", true))
 ambience_on = bool(data.get("ambience_on", true))
 world_seed = int(data.get("world_seed", world_seed))
 last_seen_unix = maxf(float(data.get("last_seen_unix", 0)), 0.0)
 timezone_bias_minutes = int(data.get("timezone_bias_minutes", timezone_bias_minutes))
 rare_misses = clampi(int(data.get("rare_misses", 0)), 0, 6)
 simulation_count = maxi(int(data.get("simulation_count", 0)), 0)
 if data.get("tokens") is Dictionary:
  _tokens = data["tokens"]
