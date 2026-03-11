# fbc-standards — fbc-starter 微服务开发规范分发工具

> 为使用 fbc-starter 框架的微服务项目一键初始化 AI 编码工具的开发规范。

## 快速使用

```bash
# 1. 在你的微服务项目中运行初始化脚本
cd /path/to/your/ms-xxx
bash /path/to/fbc-standards/init.sh .

# 2. 交互式选择你使用的 AI 编码工具
# 脚本会自动生成 .aiproject/ 规范 + 对应 AI 工具的配置文件
```

## 支持的 AI 工具

| # | 工具 | 生成的文件 |
|---|------|-----------|
| 1 | Cursor | `.cursorrules` + `.cursor/rules/fbc-starter.md` |
| 2 | GitHub Copilot | `.github/copilot-instructions.md` |
| 3 | Gemini Code Assist | `.gemini/settings.json` + `.gemini/styleguide.md` |
| 4 | Claude Code | `CLAUDE.md` |
| 5 | Windsurf | `.windsurfrules` |
| 6 | Cline | `.clinerules` |

## 目录结构

```
fbc-standards/
├── README.md              # 本文件
├── init.sh                # 交互式初始化脚本
├── .aiproject/            # 规范文件（P0–P6）
│   ├── STANDARDS.md
│   ├── P0_project_foundation.md
│   ├── P1_architecture_and_layers.md
│   ├── P2_api_and_error.md
│   ├── P3_data_and_config.md
│   ├── P4_integration.md
│   ├── P5_quality.md
│   └── P6_engineering.md
└── templates/             # AI 工具规则模板
    ├── cursorrules
    ├── cursor_rules.md
    ├── copilot_instructions.md
    ├── gemini_settings.json
    ├── gemini_styleguide.md
    ├── claude.md
    ├── windsurfrules
    └── clinerules
```

## 规范更新

当 `.aiproject/` 中的规范更新后，只需在目标项目中重新运行 `init.sh`（选择覆盖即可）。
AI 工具的规则文件不需要更新，因为它们只是引用 `.aiproject/` 的指向文件。
