# 烬织 · CINDERWEAVE M1

原创、非官方的 Godot 4.6.3 单人卡牌远征学习原型：24 张牌及升级态、九层分叉地图、9 种敌人、8 件遗物、3 种药水、4 个事件、附魔/负面附着，以及单章胜败闭环。

**本项目不是《杀戮尖塔 2》的完整复刻，不隶属于或得到任何商业游戏开发商的认可。代码、界面、图形、文案和合成短音为本工程原创；不使用原商业游戏资产。**

## 运行与操作

用官方 Godot **4.6.3** 标准版导入 `project.godot`，运行主场景。Linux/macOS 也可在 `godot` 已加入 PATH 后执行 `bash launch.sh`。

- 点击攻击牌，再点击敌人；技能牌直接生效
- 1–9 选手牌，Space 结束回合，Tab 打开牌组，Esc 暂停或关闭面板
- 药水点击立即使用；选择点亮的地图节点推进远征
- 有效行动自动保存，暂停菜单可保存返回标题；只有一个远征存档槽，新远征会覆盖它
- 网页存档保存在当前浏览器的站点存储中；清除站点数据、无痕模式或存储限制可能使进度无法保留。退出前先保存返回标题

## Web 构建与发布

每次向 `main` 推送，GitHub Actions 都会使用固定版本官方引擎/模板，执行规则、UI 和独立 UI 回归，导出单线程 Compatibility/WebGL 2 包，再部署 GitHub Pages。无需账号或付费游戏文件；不启用 PWA 或第三方分析服务。

构建输出 `build-info.json`，包含确切仓库提交、CI run ID、原始 M1 来源、模板及运行文件哈希。`SHA256SUMS.txt` 用于核对线上资源。浏览器需要 WebAssembly 与 WebGL 2。

本地复现：

```sh
python3 tools/build_web.py --godot godot --template /path/to/web_nothreads_release.zip --work-parent /tmp/cinderweave-build
```

模板必须来自官方 Godot 4.6.3 的 export templates，脚本会校验其 SHA256。构建与测试均在新建副本运行，保留原工程与个人存档。规则/源资源有意迭代后需更新 `tools/m1-baseline.json`，不得把不同版本冒称为同一产物。

## 验收边界

M1 原生 Linux 基线已完成自然胜/败路线；最终 UI 修复有复测。规则 7525 项、UI 24 项、独立 UI 259 项回归通过。Web 导出三次完全一致，但此记录不能代替实际公网浏览器验收。CI 成功和 HTTP 200 均不代表浏览器可玩；浏览器交互、存档刷新和音频须单独验收。

M1 来源版本：`a8c00b3224e7fdba7801d3aeb6e76ffa70118976`。本仓库是经过公开内容筛选的新代码历史，不能把它的提交 SHA 与此前归档 SHA 等同。

## 内容、许可与范围

- 原创简化矢量美术与基础合成短音，尚非商业美术/音频质量
- 单角色、单章节、自定义数值、固定地图拓扑；不含联机或商业游戏全内容
- 字体为重新命名的 Noto Sans CJK 子集，完整 SIL Open Font License 与来源说明保留在 `third_party/Noto-CJK-LICENSE.txt`
- Godot 引擎和捆绑第三方组件许可证位于 `third_party/`，也随网页发布
- 公开仓库不包含个人存档、原始 QA 交互记录、私人日志或第三方动画参考
- 当前没有将游戏过程上传到外部分析服务
