# 🟢 P6 — 工程实践

> 锦上添花，可灵活处理。
>
> 📅 最后更新: 2026-03-11

---

## 1. 代码风格

- 注释使用**中文**
- 导入顺序：标准库 → 第三方 → fbc-starter → 本 crate
- `pub` 项添加 `///` 文档注释
- 可选字段使用 `skip_serializing_if`

```rust
#[derive(Serialize)]
pub struct UserInfo {
    pub id: i64,
    pub username: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
}
```

## 2. CI/CD

```bash
cargo fmt -- --check
cargo clippy -- -D warnings
cargo test --lib --tests
cargo audit
```

## 3. 性能

- 关键路径使用 `#[tracing::instrument]` 追踪性能
- HTTP 客户端循环外创建复用
- 只启用必要的 fbc-starter feature
- 数据库查询使用索引，避免全表扫描
- 批量操作优于循环单条操作

## 4. 运维

### 健康检查

每个微服务建议暴露 `/health` 端点，供负载均衡器和容器编排探活：

```rust
// router.rs
Router::new()
    .route("/health", get(|| async { Json(R::<()>::ok()) }))
    .nest("/api/v1", api_router)
```

### Docker 镜像

```dockerfile
# 多阶段构建
FROM rust:1.83-slim AS builder
WORKDIR /app
COPY . .
RUN cargo build --release -p ms-xxx

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/ms-xxx /usr/local/bin/
CMD ["ms-xxx"]
```

### 日志格式

生产环境建议 JSON 格式日志，便于日志收集（ELK / Loki）：

```bash
# .env 或环境变量
APP__LOGGING__FORMAT=json
```
