# fbc-starter 微服务开发规范

你正在开发一个基于 fbc-starter 框架的 Rust 微服务。
在生成、修改或审查代码时，你**必须严格遵守**本项目 `.aiproject/` 目录下的规范体系。

## 必读规范文件

请在开始任何编码工作前，阅读以下文件（按优先级排序）：

1. `.aiproject/STANDARDS.md` — 规范总览和场景速查
2. `.aiproject/P0_project_foundation.md` — 🔴 **必须遵守**：依赖管理、项目结构、启动模式
3. `.aiproject/P1_architecture_and_layers.md` — 🟠 分层架构、模块组织、跨模块调用
4. `.aiproject/P2_api_and_error.md` — 🔵 响应格式、错误处理、错误码、路由
5. `.aiproject/P3_data_and_config.md` — 🟣 实体定义、数据库、配置管理
6. `.aiproject/P4_integration.md` — 🟡 缓存、gRPC、Kafka
7. `.aiproject/P5_quality.md` — 🟤 命名、日志、测试、安全
8. `.aiproject/P6_engineering.md` — 🟢 代码风格、CI/CD、性能

## 核心规则速记

- 使用 `Server::run` 启动，禁止手动初始化
- 调用方向：Handler → Service → Repository，禁止反向调用
- 所有 HTTP 响应用 `R<T>` 包装
- 错误用 `AppError::biz_error()` / `common_error()` / `customer_error()` 工厂方法
- 实体用 `sqlxplus` 派生宏，字段用 `Option<T>`
- 缓存键用 `CacheKeyBuilder`，禁止手动拼接
- 日志用 `tracing`，禁止 `println!`
- 注释使用中文
