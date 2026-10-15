# 游戏像素资产

默认场景的可见图像使用原生 Aseprite 绘制，PNG 与同名 `.aseprite` 一同保存，游戏运行无需安装 Aseprite。编辑源文件后可将对应 PNG 重新导出并交给 Godot 导入；保留画布大小、透明边距及角色图集布局。中文操作文字继续使用系统字体，避免像素字库缺字。

| 类别 | 源文件与运行贴图 | 内容与尺寸 |
| --- | --- | --- |
| 默认角色 | `assets/character/pixel/`、`assets/character/pixel.tres` | 五组分层图集，每格 96×128，八方向 × 24 帧，30 FPS 动作 |
| 飞剑与战斗 | `assets/pixel/combat/` | 48×20 剑、96×20 御剑踏板、靶子三状态、尾迹、命中特效、准星、瞄准纹理、血条、角色阴影、靶场地面和应用图标 |
| 浮岛与云层 | `assets/pixel/world/` | 三座 2048×1792 分层浮岛、四帧云朵图集、256×256 穿云纹理 |
| 控制面板 | `assets/pixel/ui/` | 九宫格面板与按钮、选项卡、滑杆、复选框、下拉箭头、技能和起降图标 |

通过 Aseprite Lua API 绘制并导出，项目上一层目录运行：

```powershell
& '<Aseprite.exe>' --batch --script sword/art/generate_pixel_character.lua
& '<Aseprite.exe>' --batch --script sword/art/generate_pixel_combat.lua
& '<Aseprite.exe>' --batch --script sword/art/generate_pixel_world.lua
& '<Aseprite.exe>' --batch --script sword/art/generate_pixel_ui.lua
```

生成脚本会覆盖上述各目录的同名 `.aseprite` 和 PNG。若对某帧做了手工修改，请先保留副本，再单独从 Aseprite 导出修改后的 PNG。`assets/character/swordsman.aseprite` 等旧素材不在这些脚本的输出目录内，也仍可通过 F2 选择。

角色图集每动作 **1536×1536**、16 列 × 12 行；按 E、SE、S、SW、W、NW、N、NE 的顺序，每方向连续放置 24 帧。场景图以 2 倍显示，战斗道具依运行尺寸显示；所有贴图使用 nearest 采样。起飞缩放依旧连续，空中云纹由像素贴图采样，剑身长轴翻转与技能运动只变换已有像素贴图。

检查：`python sword/art/check_pixel_assets.py` 验证 42 组 Aseprite/PNG 对应文件和角色各方向的 24 张不同帧；`Godot --headless --path sword --script res://tests/pixel_art_test.gd`、`travel_test.gd`、`skin_swap_test.gd` 检查实际接线与功能。实机画面截图可运行 `Godot --path sword --fixed-fps 60 -- --travel-capture=ground` 或 `sky`，输出到上一层 `reference/`。测试时 48 把剑、三座浮岛、云海、面板的实际场景稳定为 60 FPS / 80 draw calls（本机 RTX 5060 Ti；不是跨设备帧率保证）。
