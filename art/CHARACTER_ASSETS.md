# 角色素材快速测试

运行游戏后按 **F2** 在“新版 · 墨衣行者”和“原版 · 清简剑客”之间切换。右侧“角色 / 靶场”页也有下拉框。默认使用新版；切换立即作用于地面与空中角色，不重置位置、技能或飞剑参数。关闭游戏后，下次启动恢复默认新版。

## 在 Aseprite 中修改后立即预览

1. 打开任一 `.aseprite` 源文件，修改需要测试的帧。
2. 导出透明背景 PNG 图集。保持 **8 列、40 行**，不要裁掉各帧的透明边距，也不要加帧间距。
3. 在游戏“角色 / 靶场”页点击“载入外部 PNG 图集…”，选中 PNG，立即替换角色。
4. 继续修改并导出到同一 PNG，然后点击“重新加载外部图集”。无需关闭游戏或等待 Godot 导入。

外部素材会成为下拉框中的第三个选项，可以按 F2 与内置两套比较。新载入的外部文件替换这个测试选项；格式不合格时会显示原因，并保留当前角色。

## 文件和帧布局

| 素材 | 可编辑源文件 | 运行图集 |
| --- | --- | --- |
| 新版 · 墨衣行者 | `assets/character/traveler/swordsman.aseprite` | `assets/character/traveler/swordsman.png` |
| 原版 · 清简剑客 | `assets/character/swordsman.aseprite` | `assets/character/swordsman.png` |

两套都是每帧 64×80、总图集 512×3200、320 帧、三图层、40 个标签。每行 8 帧、从左向右播放；从上至下排列如下（行号从 1 起算）：

| 行 | 动作 | 每组方向顺序 |
| --- | --- | --- |
| 1–8 | idle / 待机 | E、SE、S、SW、W、NW、N、NE |
| 9–16 | walk / 行走 | 同上 |
| 17–24 | cast / 施法 | 同上 |
| 25–32 | fly / 移动飞行 | 同上 |
| 33–40 | hover / 悬停 | 同上 |

待机每帧 180 ms，其余 100 ms。脚底锚点为 (32,74)。外部 PNG 支持不同帧尺寸，但仍须为完整的 8×40 格；加载器按画布宽度的 50%、高度的 92.5% 定位脚底，并自动缩放到 112 像素画布高度。推荐沿用 64×80 模板，以免角色大小、锚点与技能剑环不匹配。

## 永久添加一套内置角色

复制 `assets/character/traveler.tres`，在 Godot Inspector 中修改 `display_name` 和 `atlas`，按需调整 `frame_size`、`foot_pivot`、`display_scale`；将新资源加入 `scripts/character_skins.gd` 的 `skins` 列表。列表第一项为启动默认素材。动作行序相同即可，无需修改移动、施法或起降代码。

## 从 Lua 重新生成

在包含 `sword` 子目录的上一级工程目录执行：

```powershell
& '<Aseprite.exe>' --batch --script-param out=sword/assets/character/traveler --script-param renderer=sword/art/traveler_renderer.lua --script sword/art/generate_swordsman.lua
```

新版使用独立的 `traveler_renderer.lua` 绘制，原版仍由 `generate_swordsman.lua` 的默认绘制器生成。两者共享 Aseprite 的分层、帧标签和图集导出流程。省略 `renderer` 参数并将 `out` 改为 `sword/assets/character` 可重新生成原版。

可运行 `art/preview_traveler.py`（Pillow）生成新版动作图与 GIF；`art/verify_swordsman.lua` 加 `--script-param out=sword/assets/character/traveler` 可重新打开新版 Aseprite 文件，逐帧核对源文件与 PNG。`tests/skin_swap_test.gd` 覆盖 F2、下拉框、地面/空中同步、PNG 热加载与无效格式保护。
