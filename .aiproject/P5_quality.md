# 🟤 P5 — 质量保障

> 影响代码质量、可观测性和安全性。
>
> 📅 最后更新: 2026-03-11

---

## 1. 命名

| 元素 | 风格 | 示例 |
|------|------|------|
| 包名 | `ms-{名称}` | `ms-identity` |
| 结构体 | `PascalCase` | `UserService` |
| 函数 | `snake_case` | `get_user_info` |
| 常量 | `SCREAMING_SNAKE` | `USER_NOT_FOUND` |
| 路由 | `kebab-case` | `/user-tenants` |
| 环境变量 | `APP__XX__YY` | `APP__SERVER__PORT` |
| 错误枚举变体 | `PascalCase` | `UserNotFound` |

## 2. 日志

| 级别 | 用于 |
|------|------|
| `error!` | 不可恢复错误（数据库连接断开、关键操作失败） |
| `warn!` | 可恢复异常（缓存未命中、降级处理、业务规则拦截） |
| `info!` | 关键业务事件（用户注册、订单创建、服务启动） |
| `debug!` | 调试信息（SQL 参数、中间变量） |

**禁止** `println!`，使用结构化日志：

```rust
tracing::info!(user_id = %id, action = "login", "用户登录成功");
tracing::error!(error = ?e, user_id = %id, "查询用户失败");
```

## 3. 测试

### 测试要求

- 每个 Service 方法至少一个**成功** + 一个**失败**测试
- DTO 序列化/反序列化边界测试
- 测试文件按模块组织在 `tests/` 下

### 测试策略

| 层 | 测试方式 | 说明 |
|----|----------|------|
| Repository | 集成测试 | 使用真实数据库或 testcontainers |
| Service | 单元测试 | mock 数据库层，验证业务逻辑 |
| Handler | 集成测试 | 使用 `axum::test` 发送 HTTP 请求 |

```rust
// tests/user_tests.rs
#[tokio::test]
async fn test_get_user_info_success() {
    // 构造测试数据
    let pool = setup_test_db().await;
    let service = UserService::new(pool);
    let result = service.get_user_info(1).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_get_user_info_not_found() {
    let pool = setup_test_db().await;
    let service = UserService::new(pool);
    let result = service.get_user_info(99999).await;
    assert!(result.is_err());
}
```

## 4. 安全

- 错误响应**不暴露** SQL / 堆栈 / 文件路径 / 内部错误详情
- 密码使用 argon2/bcrypt，**禁止** MD5 / 明文存储
- Handler 层**校验用户输入**（长度、格式、范围）
- 定期执行 `cargo audit` 检查依赖安全漏洞

## 5. HTTP 安全

| 机制 | 说明 |
|------|------|
| CORS | 使用 `tower-http::CorsLayer` 配置（workspace 已引入 `tower-http`） |
| 认证 | 自定义 middleware 验证 Token（参考 ms-identity/middleware/） |
| 限流 | 关键接口考虑限流保护，使用 `tower::ServiceBuilder` + 限流中间件 |
| 请求体大小 | 限制请求体大小，防止大载荷攻击 |

```rust
// CORS 配置示例
use tower_http::cors::{CorsLayer, Any};

let cors = CorsLayer::new()
    .allow_origin(Any)
    .allow_methods(Any)
    .allow_headers(Any);

Router::new()
    .nest("/api/v1", api_router)
    .layer(cors)
```
