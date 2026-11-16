# 16种新鸟 · Godot实际动画

本目录是游戏真实渲染结果，使用与窗景和图鉴相同的手绘部件及动作，非概念图滑动。

- `animated-birds.gif`：16种鸟的8秒原生动作展示，100帧、80毫秒/帧。
- `characters.png`：16种手绘鸟总览与稀有度。
- `expansion.png`：真实窗景中的新来客。
- `expansion_guide.png`：新图鉴详情、分类与66项总数。
- `animation_lab.png`：新鸟动作检视台，放大查看双头鸟。
- `all_creatures.png`：37种生物的回归绘制板。
- `validation.json`：本轮实际验证记录。

启动 `../../game/PreviewNewBirds.cmd` 可自由切换16只新鸟、入场/停留/进食/离场及天气，默认放大动作；`../../game/Play.cmd` 则以正式存档自然游玩。

透明2D动画部件、每只48帧的SpriteFrames及可直接拖入Godot的角色场景，入口见 `../../game/README.md`。图鉴概率以每次鸟类抽选为分母：90% / 6.9% / 2% / 1% / 0.1%。

仍属于2D原型：原有10鸟与新16鸟采用不同绘制来源，后续可继续统一笔触；脑暴中未实现的候选、双鸟关系系统和行为收藏层仍为提案。
