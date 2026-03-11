# fbc-starter 微服务开发规范

> AI 工具在生成、修改或审查代码时**必须遵守**本规范体系。
>
> 📅 最后更新: 2026-03-11

## 规范文件（P0 最高 → P6 最低）

| 优先级 | 文件 | 领域 |
|--------|------|------|
| 🔴 P0 | [P0_project_foundation.md](P0_project_foundation.md) | 依赖锁定 · 项目结构 · 启动模式 · AppState |
| 🟠 P1 | [P1_architecture_and_layers.md](P1_architecture_and_layers.md) | 分层架构 · 模块组织 · Repository / Service / Handler · 跨模块调用 |
| 🔵 P2 | [P2_api_and_error.md](P2_api_and_error.md) | R\<T\> 响应 · 错误处理 · 错误码体系 · 路由规范 |
| 🟣 P3 | [P3_data_and_config.md](P3_data_and_config.md) | 实体定义 · 数据库 · 配置管理 · 数据库迁移 |
| 🟡 P4 | [P4_integration.md](P4_integration.md) | 缓存 · gRPC · Kafka · Proto 管理 |
| 🟤 P5 | [P5_quality.md](P5_quality.md) | 命名 · 日志 · 测试 · 安全 · HTTP 安全 |
| 🟢 P6 | [P6_engineering.md](P6_engineering.md) | 代码风格 · CI/CD · 性能 · 运维 |

## 场景速查

| 开发场景 | 必读 |
|----------|------|
| 新建微服务 | P0 → P3 |
| 新增业务模块 | P1 → P2 |
| 数据库操作 | P3 → P1 §3-4 |
| HTTP 接口 | P2 |
| 错误处理 | P2 §2 |
| 微服务间调用（gRPC） | P4 §2-3 |
| 缓存操作 | P4 §1 |
| 消息队列（Kafka） | P4 §4-5 |
| 安全与认证 | P5 §4-5 |

## 检查清单

### P0 基础（必须通过）
```
[ ] Cargo.toml workspace 依赖（版本以 workspace Cargo.toml 为准）
[ ] modules/ 目录结构
[ ] Server::run 启动
[ ] AppState #[derive(Clone)] + Arc 包装
```

### P1-P2 架构与接口
```
[ ] Handler → Service → Repo 单向调用
[ ] 跨模块通过 Service 层互调（禁止循环依赖）
[ ] R<T> 包装响应
[ ] AppError 工厂方法（biz_error / common_error / customer_error）
[ ] 错误码按服务分段分配
```

### P3-P4 数据与集成
```
[ ] sqlxplus 实体宏（ModelMeta + CRUD）
[ ] .env.example 完整配置
[ ] CacheKeyBuilder 构建键（禁止手动拼接）
[ ] gRPC build.rs + proto/ 目录
[ ] Kafka Handler 实现 KafkaMessageHandler trait
```

### P5-P6 质量与工程
```
[ ] tracing 日志（禁止 println!）
[ ] 敏感信息不暴露
[ ] Service 方法有成功+失败测试
[ ] cargo fmt / clippy / test 通过
```
