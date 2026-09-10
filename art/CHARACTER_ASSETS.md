# 角色素材快速测试

运行游戏后按 **F2** 在“高精度 · 墨衣剑仙”、“新版 · 墨衣行者”和“原版 · 清简剑客”之间切换。右侧“角色 / 靶场”页也有下拉框。默认使用高精度版；切换立即作用于地面与空中角色，不重置位置、技能或飞剑参数。关闭游戏后，下次启动恢复默认高精度版。

点击 **放大查看素材 / 动作**，可同时查看全身和放大的头部衣领，切换五种动作、八个方向，并用按钮或 F2 比较角色。场景中角色仍保持原来的大小；素材精度不会改变移动速度和碰撞范围。

## 高精度素材

`assets/character/hd/` 下有 `idle`、`walk`、`cast`、`fly`、`hover` 五组 PNG 和可编辑 Aseprite 文件。每帧 **384×640**，每个方向 **24 帧**，每份 Aseprite 文件含 **192 帧**和 8 个方向标签，总计 **960 帧**。PNG 使用 **16 列 × 12 行**，尺寸 **6144×7680**。先按方向 E、SE、S、SW、W、NW、N、NE 排列各自 24 帧，再连续从左到右换行打包；方向起点不一定在行首。

行走、施法、飞行和悬停按 **30 FPS** 播放，完整循环 0.8 秒；待机约 **16.67 FPS**，循环 1.44 秒。相比旧版 8 帧增加了过渡帧，保持原来的循环时长。走路移除了循环中的待机姿态硬切换，步态、袖口、衣摆和发丝按连续相位变化，最后一帧平滑接回第一帧。

角色保持参考图的细发丝、五官、手指、叠层衣襟与布料纹理。生成后的角色像素未经降采样，透明处理及位置对齐由 Aseprite 完成。`source/` 保存内置 ImageGen 生成的关键姿态原图，[HD_PROMPTS.md](HD_PROMPTS.md) 保存完整提示词。新增中间帧由原姿态连续变形生成，取原图像素、不使用透明叠影；960 帧不是 960 张独立手绘动作。

编辑高精度源文件后，将对应动作导出为 16×12 透明 PNG 覆盖同名文件，Godot 会重新导入。永久角色资源为 `assets/character/hd.tres`，使用 `action_atlases` 分动作加载，`frames_per_direction=24`、`atlas_columns=16`，脚底锚点 (192,600)，显示倍率 0.16。五张贴图原始 RGBA 像素约 900 MiB；保留原始精度并增加三倍帧数会相应增加贴图内存，游戏帧内只绘制当前帧，不实时计算补帧。

在包含 `sword` 子目录的上一级工程目录重新组装：

```powershell
& '<Aseprite.exe>' --batch --script-param out=sword/assets/character/hd --script sword/art/build_hd_character.lua
& '<Python.exe>' sword/art/check_hd_character.py
& '<Godot.exe>' --headless --path sword --script res://tests/hd_character_test.gd
```

重新组装会覆盖五组 PNG 和 Aseprite 文件，应先保存手工修改。像素检查覆盖所有帧的裁切边界、重复帧、相邻轮廓跳变和首尾循环，并生成 `reference/hd-walk-24.gif`。运行检查覆盖所有帧的播放时序、分图集取帧、地面/空中同步和预览控件。

## 在 Aseprite 中修改后立即预览

1. 打开任一 `.aseprite` 源文件，修改需要测试的帧。
2. 导出透明背景 PNG 图集。保持 **8 列、40 行**，不要裁掉各帧的透明边距，也不要加帧间距。
3. 在游戏“角色 / 靶场”页点击“载入外部 PNG 图集…”，选中 PNG，立即替换角色。
4. 继续修改并导出到同一 PNG，然后点击“重新加载外部图集”。无需关闭游戏或等待 Godot 导入。

外部素材会成为下拉框中的第四个选项，可以按 F2 与内置三套比较。新载入的外部文件替换这个测试选项；格式不合格时会显示原因，并保留当前角色。此快捷载入器接收单张 8×40 PNG；高精度版的五张分动作图集通过上面的 `.tres` 资源接入。

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

复制 `assets/character/traveler.tres`，在 Godot Inspector 中修改 `display_name` 和 `atlas`，按需调整 `frame_size`、`foot_pivot`、`display_scale`；将新资源加入 `scripts/character_skins.gd` 的 `skins` 列表。分动作素材可复制 `hd.tres` 并设置五项 `action_atlases`。`frames_per_direction`、`atlas_columns`、`animation_fps` 和 `idle_fps` 分别设置每方向帧数、打包列数、动作帧率和待机帧率，旧版默认保持 8 帧、8 列。`selected` 指定启动默认索引，当前为 2。动作和方向顺序相同即可，无需修改移动、施法或起降代码。

## 从 Lua 重新生成

在包含 `sword` 子目录的上一级工程目录执行：

```powershell
& '<Aseprite.exe>' --batch --script-param out=sword/assets/character/traveler --script-param renderer=sword/art/traveler_renderer.lua --script sword/art/generate_swordsman.lua
```

新版使用独立的 `traveler_renderer.lua` 绘制，原版仍由 `generate_swordsman.lua` 的默认绘制器生成。两者共享 Aseprite 的分层、帧标签和图集导出流程。省略 `renderer` 参数并将 `out` 改为 `sword/assets/character` 可重新生成原版。

可运行 `art/preview_traveler.py`（Pillow）生成新版动作图与 GIF；`art/verify_swordsman.lua` 加 `--script-param out=sword/assets/character/traveler` 可重新打开新版 Aseprite 文件，逐帧核对源文件与 PNG。`tests/skin_swap_test.gd` 覆盖 F2、下拉框、地面/空中同步、PNG 热加载与无效格式保护。
