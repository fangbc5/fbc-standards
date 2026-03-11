# fbc-starter 微服务开发规范

你正在开发一个基于 fbc-starter 框架的 Rust 微服务。
在生成、修改或审查代码时，你**必须严格遵守**本项目 `.aiproject/` 目录下的规范体系。

## 规范文件索引

| 优先级 | 文件 | 领域 |
|--------|------|------|
| 🔴 P0 | `.aiproject/P0_project_foundation.md` | 依赖锁定 · 项目结构 · 启动模式 · AppState |
| 🟠 P1 | `.aiproject/P1_architecture_and_layers.md` | 分层架构 · 模块组织 · 跨模块调用 |
| 🔵 P2 | `.aiproject/P2_api_and_error.md` | R\<T\> 响应 · 错误处理 · 错误码 · 路由 |
| 🟣 P3 | `.aiproject/P3_data_and_config.md` | 实体定义 · 数据库 · 配置管理 |
| 🟡 P4 | `.aiproject/P4_integration.md` | 缓存 · gRPC · Kafka · Proto 管理 |
| 🟤 P5 | `.aiproject/P5_quality.md` | 命名 · 日志 · 测试 · 安全 |
| 🟢 P6 | `.aiproject/P6_engineering.md` | 代码风格 · CI/CD · 性能 · 运维 |

## 核心规则

1. 使用 `Server::run` 启动，禁止手动初始化日志/数据库/Nacos
2. 调用方向：`Handler → Service → Repository`，禁止反向调用
3. 所有 HTTP 响应用 `R<T>` 包装，错误用 `AppError` 工厂方法
4. 实体用 `sqlxplus` 派生宏（`ModelMeta` + `CRUD`），字段用 `Option<T>`
5. 缓存键用 `CacheKeyBuilder`，禁止手动拼接字符串
6. 日志用 `tracing`，禁止 `println!`
7. 注释使用中文
