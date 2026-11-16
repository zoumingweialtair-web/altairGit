# 跨设备继续开发

## 新设备第一次使用

1. 安装 Git 和项目对应的 Godot 标准版；当前 README 标注 Godot 4.7.2。
2. 克隆仓库（目标路径可自由选择）：

```sh
git clone https://github.com/zoumingweialtair-web/altairGit.git
cd altairGit
```

3. 检查既有 hooks。全新克隆且没有其他 hooks 配置时启用本仓库检查：

```sh
git config --show-origin --get core.hooksPath
git config --local core.hooksPath .githooks
```

如果已有自定义 hooks，先整合再启用，不覆盖。Git 不会自动信任并启用克隆下来的 hooks；每台设备/每个克隆都须设置。

4. 在 Codex 中添加克隆目录为项目。给 Codex 的开场提示：

> 先读取 AGENTS.md、LittleElsewhere/AGENTS.md、LittleElsewhere/docs/HANDOFF.md 和 DEVELOPMENT_LOG.md，再检查 Git 状态与最近提交。从交接文档的下一步继续；每次提交同时更新上下文。

5. 在 Godot 导入 `LittleElsewhere/game/project.godot`。Windows 启动脚本的引擎路径可能只适用于原电脑，不应把原电脑绝对路径当作通用配置。

## 每次开始与结束

- 开始先 `git status`。工作区干净且 main 已设置上游时，用 `git pull --ff-only` 获取另一台设备的提交。如果有本地修改或历史分叉，先处理，不能强制覆盖。
- 一次做一个明确任务，按 README 选择相关测试，记录实际结果。美术与动画修改还要做视觉检查。
- 更新 HANDOFF.md，追加 DEVELOPMENT_LOG.md，再显式暂存本轮文件和上下文。不要混入另一任务的未提交修改。
- `git diff --cached` 检查后执行 `git commit -m "说明本轮改动"`。
- 经用户授权推送。首次设置上游用 `git push -u origin main`；此后按实际分支推送。确认成功才算另一台设备可获取。
- 换设备前确保目标工作已提交并推送。未提交文件、忽略文件、本地存档及原始聊天不会随 Git 自动转移。

## 提交检查

`.githooks/pre-commit` 对 LittleElsewhere 下的工程文件变更要求同次提交包含非空的 HANDOFF.md 更新。纯交接文档修改不触发该要求。新增开发记录应由 Codex 按 AGENTS.md 维护。

如提示缺少上下文，更新交接文档后执行：

```sh
git add LittleElsewhere/docs/HANDOFF.md LittleElsewhere/docs/DEVELOPMENT_LOG.md
```

再次检查暂存差异并提交。不要用 `--no-verify` 作为日常操作。

## 保存什么

保存游戏相关需求、选定方案、取舍理由、文件入口、验证命令/结果、已知问题、下一步。未确认的想法明确标为提案。

不要提交完整 .codex 目录、聊天数据库、登录凭据、API 密钥、无关私人聊天或正式游戏存档。此机制提供可迁移的工作上下文，不会在另一台设备恢复相同的聊天 UI 或模型内部状态。
