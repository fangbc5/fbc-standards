# 🔴 P0 — 项目基础

> 新建微服务必须遵守。违反将导致项目无法正常集成到工作空间。
>
> 📅 最后更新: 2026-03-11

---

## 1. 依赖管理

### Workspace 依赖

所有微服务加入 `hula-server` 工作空间，共享依赖使用 `workspace = true`。
**禁止**自行指定 workspace 中已声明的版本。

```toml
[package]
name = "ms-xxx"
version.workspace = true
edition.workspace = true
authors.workspace = true
license.workspace = true

[dependencies]
fbc-starter = { path = "../fbc-starter", features = ["nacos", "mysql"] }
axum.workspace = true
tokio.workspace = true
serde.workspace = true
serde_json.workspace = true
anyhow.workspace = true
thiserror.workspace = true
tracing.workspace = true
# 按需启用
sqlx.workspace = true
sqlxplus.workspace = true
```

### 版本管理

**所有依赖版本以 workspace 根目录 `Cargo.toml` 中 `[workspace.dependencies]` 声明为准。**

微服务 `Cargo.toml` 中只写 `xxx.workspace = true`，禁止覆盖版本号。
如需升级依赖，统一修改 workspace `Cargo.toml`。

### Feature 选择

只启用必要 feature：`mysql` / `redis` / `nacos` / `balance` / `grpc` / `producer` / `consumer`

---

## 2. 项目结构

```
ms-xxx/
├── Cargo.toml
├── build.rs               # 如需 gRPC，配置 tonic_build
├── .env / .env.example
├── proto/                 # 如需 gRPC，存放 .proto 文件
│   └── xxx.proto
└── src/
    ├── main.rs            # 仅启动逻辑
    ├── lib.rs             # 可选：集成测试需导出的模块
    ├── config.rs          # 服务配置
    ├── error.rs           # 服务错误
    ├── state.rs           # AppState
    ├── router.rs          # 路由定义
    ├── grpc/              # 可选：gRPC 服务实现
    ├── middleware/         # 可选：自定义中间件
    └── modules/           # 业务模块
        └── {模块名}/
            ├── mod.rs
            ├── model/
            │   ├── entity/
            │   └── dto.rs
            ├── repository.rs
            ├── service.rs
            └── handler.rs
```

**核心规则：**
- DTO / Handler / Repository **必须**在 `modules/{模块}/` 内，禁止独立目录
- `grpc/` — 当微服务需暴露 gRPC 服务时添加
- `middleware/` — 当需要自定义认证、权限等中间件时添加
- `lib.rs` — 当需要在集成测试中导出模块时添加（如 `ms-organization`）
- 其他按需可选目录：`jwt/`、`casbin/`、`client/` 等

---

## 3. 启动与 AppState

使用 `Server::run` 启动，**禁止手动初始化日志/数据库/Nacos**。

> **启动阶段规则**：启动时依赖未就绪（如 MySQL 连接池为空）属不可恢复错误，允许 `panic!` 或 `expect()`。
> **运行时规则**：服务运行后的所有操作必须返回 `Result`，禁止 `unwrap()` / `expect()`。

```rust
#[tokio::main]
async fn main() -> AppResult<()> {
    Server::run(|builder| {
        let fbc_app_state = builder.app_state().clone();

        // 启动阶段：连接池必须存在，否则 panic
        let mysql_pool = fbc_app_state.mysql.as_ref()
            .expect("MySQL 连接池未初始化").clone();

        let db_pool = Arc::new(DbPool::from_mysql_pool(mysql_pool)
            .expect("创建 DbPool 失败"));

        let config = config::XxxConfig::new(builder.config().clone())
            .expect("加载配置失败");

        let app_state = Arc::new(state::AppState::new(fbc_app_state, db_pool, config));

        // 注册 HTTP 路由（必须）
        let mut b = builder.http_router(router::create_router(app_state.clone()));

        // 注册 gRPC 路由（可选）
        // let grpc_router = tonic::transport::Server::builder()
        //     .add_service(grpc::XxxServiceImpl::server(...));
        // b = b.grpc_router(grpc_router);

        b
    }).await
}
```

### AppState 规范

```rust
#[derive(Clone)]
pub struct AppState {
    pub fbc: FbcAppState,       // 必须持有框架 AppState
    pub db_pool: Arc<DbPool>,
    pub config: XxxConfig,
    // Service 用 Arc 包装
    pub user_service: Arc<UserService>,
}
```

- AppState 必须 `#[derive(Clone)]`
- 每个 Service 用 `Arc` 包装
- 必须持有 `fbc_app_state`（框架可能需要通过它访问 Redis、Kafka 等）
