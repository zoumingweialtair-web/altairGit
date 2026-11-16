# Little Elsewhere 跨设备交接

更新时间：2026-11-16（北京时间）。保存可审阅的游戏需求、实现与验证；不是聊天原始记录。

## 持续协作要求

- 每次游戏修改提交，同步更新此文件，并追加DEVELOPMENT_LOG.md。读取两级AGENTS.md及CROSS_DEVICE_WORKFLOW.md。
- 检查状态及最近提交，保留无关工作。当前main未配置上游，本轮未pull或push；不要把本地提交称为远端同步。
- 已启用 `.githooks/pre-commit`；新设备检查后配置。不绕过上下文检查，不提交真实存档、凭据或本机会话数据。
- 所有捕获和测试使用 `--capture` / `--test-mode` 隔离正式存档。保留 `.uid` 和源 `.import`，忽略 `.godot` 与 `.work`。

## 最新请求与完成范围

用户在认可呆萌魔性造型和16鸟手绘原画后，要求“加到游戏中，做成2d动画资产看看效果”。本轮已将16种全部接入实际Godot工程、自然来访、图鉴和动画检视台，并提供可复用透明资源。

项目入口 `game/project.godot`，Godot4.7.2标准版 / Compatibility。基础为6f9e59e贴景运动、c751fdb原有10鸟、fbd9b2b五档脑暴、19acf06的16鸟原画；35号Pocket Fieldkit UI与原分层窗景保留。

当前事实：26种鸟、4动物、7昆虫，共37生物；加8风景和21奇遇，共66图鉴。旧10鸟与全部旧存档ID保留；存档版本仍3。

## 新鸟与概率

新增鸽子、乌鸦、玄凤、面团鸟、蒲团鸟、纸团鸟、云兜鸟、毛线鸟、咔哒鸟、信号不好鸟、两口子鸟、隐形鸟、影影鸟、倒着鸟、一口星河鸟、缺一口鸟。实现名单及英文ID见diary_state.gd、expansion_bird_art.gd。

每次鸟类抽选以10000整数票先抽档：普通9000、罕见690、稀有200、神秘100、传说10；再按天气/食物/摆设调整档内物种。实际档内数量13/5/3/3/2。旧林鸮和翠鸟归罕见，其他旧鸟普通。动物、昆虫、奇遇不进入鸟类分母；原奇遇补算机制独立。在线和离线共用select_visit/select_bird，无鸟类保底。每档保持全天候基础候选。

原NORMAL_IDS/RARE_IDS不再混入鸟，main自然来访已改用select_visit；常驻图鉴总数从定义读取。满场候选存入actor的replacement_queue，避免覆盖稀有鸟，GM清场同步清队列；回放不重复记账。

## 美术、运动与复用资源

- `game/assets/creatures/expansion/atlas_a..d.png`：从已选概念图制作的4张1254²透明手绘部件图；generation_manifest.json保留提示词、清理来源和哈希。
- `expansion_bird_art.gd`：真实贴图分层，近/远翼、脚、机械发条、独立双头、眨眼和小特效。身体材质保持手绘，脚点固定。图鉴、场景、头像共用VisitorArt。
- `visitor_motion.gd` 与 `habitat_paths.gd`：完整进入/停留/进食/离开。倒着鸟接触枝下后绕脚翻转，离开展开；影影鸟在(1040,755)窗台表面出入，避开底部工具栏。新普通枝头鸟避让已预留的枝头落点。
- `scenes/expansion_bird.tscn`：可拖入的连续动画角色，选择16个ID及4种模式；脚原点在节点位置。
- `assets/creatures/expansion/animations/`：16套SpriteFrames及透明PNG，6动作×8帧/只，共768帧，192²；脚点在帧中心，比例0.72。实际游戏连续运动不受8帧循环限制。
- `PreviewNewBirds.cmd`：只看新16鸟，默认放大，入场/停留/进食/离场、调速和天气。PreviewCreatures仍支持全部37种，不读写正式收藏。
- `docs/bird-expansion-demo/`：原生总览、8秒GIF、真实窗景及图鉴截图。角色设计原图仍在bird-expansion-art-v1。

## 本轮实际验证

Godot4.7.2导入和脚本检查完成。测试均为本轮实际运行：

- state_test 68/68；expansion_state_test 27/27，穷举10000票精确核对五档、26鸟可达、旧存档迁移及新鸟纪念品。
- habitat_route_test 166/166；bird_expansion_motion_test 189/189，含80次中途离场，接触点和倒挂连续性。
- bird_perch_spacing_test 42/42，真实枝头落点避让；
- creature_animation_test 720/720；creature_lab_test 581/581，全模式；实际--new-birds参数372/372。
- visitor_queue_test 14/14，16新鸟满场排队最终均出现，最多6演员，GM清场不复活，不重复记录。
- GM396/396、GM UI16/16；Fieldkit33/33；主界面UI_SMOKE_OK，66图鉴、分类、回放、陪伴、离线流程通过。
- 原生37生物×3阶段×64姿态=7104次绘制，111个阶段动画变化检查，0失败。
- expansion_asset_test 6137/6137：16套、96动作、768透明帧，0裁切，最小边缘留白21px；独立场景64个实际渲染样本通过。
- 原生展示板100帧×80ms，0失败；实际检查静态、飞翼、倒挂脚点和双头极值。正式存档在状态、队列、UI、资产及录制检查中保持一致。

验证详情见 `docs/bird-expansion-demo/validation.json`。程序化骨骼/切片动画与原画部件均已进入工程，不只是设计图。

## 边界与下一步

50种鸟仍是长期候选目标，目前实现26种；剩余候选、关系互动、行为收藏层未实现。新16种为手绘切片，旧10种保留已认可的程序绘制，未来可逐步统一笔触。当前不声称实现完整商业化养成系统。

下一步从PreviewNewBirds逐只评审表情和动作节奏，再据用户反馈精修；如改变renderer，重新运行export_expansion_animations、导入PNG、导出新头像并执行资产/渲染检查，避免源与烘焙资源不一致。记录验证后随代码提交上下文。

## 同步状态

本轮将实现、素材、预览与交接一起本地提交，未push。最终提交哈希与工作区状态见本轮回复或git log/status。
