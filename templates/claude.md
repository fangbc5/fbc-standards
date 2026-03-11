# CLAUDE.md — fbc-starter 微服务开发规范

你正在开发一个基于 fbc-starter 框架的 Rust 微服务。
在生成、修改或审查代码时，你**必须严格遵守**本项目 `.aiproject/` 目录下的规范体系。

## 规范文件

请在编码前阅读以下文件（P0 最高优先级，P6 最低）：

- `.aiproject/STANDARDS.md` — 规范总览 + 场景速查 + 检查清单
- `.aiproject/P0_project_foundation.md` — 依赖管理、项目结构、启动模式（**必须遵守**）
- `.aiproject/P1_architecture_and_layers.md` — 分层架构、跨模块调用
- `.aiproject/P2_api_and_error.md` — 响应格式、错误码体系、路由
- `.aiproject/P3_data_and_config.md` — 实体定义、配置管理、数据库迁移
- `.aiproject/P4_integration.md` — 缓存、gRPC、Kafka
- `.aiproject/P5_quality.md` — 命名、日志、测试、安全
- `.aiproject/P6_engineering.md` — 代码风格、CI/CD、性能

## 关键约束

- `Server::run` 启动，禁止手动初始化
- `Handler → Service → Repository` 单向调用
- `R<T>` 包装所有 HTTP 响应
- `AppError` 工厂方法处理错误
- `sqlxplus` 实体宏，字段 `Option<T>`
- `CacheKeyBuilder` 构建缓存键
- `tracing` 日志（禁止 `println!`）
- 中文注释
