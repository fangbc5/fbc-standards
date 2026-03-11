# 🔵 P2 — 接口与错误规范

> 影响前后端交互一致性和错误可追溯性。
>
> 📅 最后更新: 2026-03-11

---

## 1. 响应格式

所有 HTTP 接口使用 `R<T>` 包装，分页使用 `CursorPageBaseResp<T>`：

```rust
R::ok_with_data(data)              // 成功
R::fail_with_message(msg)          // 失败
R::fail_with_code(code, msg)       // 带错误码

// 分页
CursorPageBaseResp::init(next_cursor, is_last, list, total)
```

禁止自定义分页响应结构体。

---

## 2. 错误处理

### 2.1 错误定义

每个微服务定义错误枚举，通过 `From` 转换到 `AppError`：

```rust
#[derive(Debug, thiserror::Error)]
pub enum XxxError {
    #[error("用户不存在")]
    UserNotFound,
    #[error("数据库错误: {0}")]
    DatabaseError(String),
}

impl From<XxxError> for AppError {
    fn from(err: XxxError) -> Self {
        match err {
            XxxError::UserNotFound => AppError::biz_error(4001, err.to_string()),
            XxxError::DatabaseError(msg) => AppError::common_error(5001, msg),
        }
    }
}
```

### 2.2 错误码分配规则

错误码按 **微服务 + 错误类型** 分段分配，避免冲突：

| 段位 | 微服务 | 示例 |
|------|--------|------|
| 40xx | ms-identity | 4001 用户不存在 / 4002 租户不存在 |
| 41xx | ms-organization | 4101 部门不存在 / 4102 组织不存在 |
| 42xx | ms-auth | 4201 认证失败 / 4202 Token 过期 |
| 43xx | ms-im | 4301 消息发送失败 |
| 44xx | ms-notify | 4401 通知发送失败 |
| 5xxx | 通用系统错误 | 5001 数据库错误 / 5002 缓存错误 |

> 新增微服务时，按序分配下一个段位。

### 2.3 工厂方法

**必须使用工厂方法**创建分类错误：

| 方法 | 错误分类 | 用途 |
|------|----------|------|
| `AppError::biz_error(code, msg)` | `Biz` 业务错误 | 业务逻辑异常（用户不存在等） |
| `AppError::common_error(code, msg)` | `Common` 通用错误 | 系统/基础设施错误（数据库、缓存等） |
| `AppError::customer_error(code, msg)` | `Custom` 自定义错误 | 其他自定义场景 |

> 注：`customer_error` 命名为历史 API，映射到 `ErrorCategory::Custom`。

### 2.4 AppError 自动响应

`AppError` 已实现 `IntoResponse`，Handler 中也可用 `?` 运算符简化错误处理：

```rust
// 方式一：match 手动处理（适合需要自定义成功响应时）
pub async fn get_user(...) -> Json<R<UserInfo>> {
    match app_state.user_service.get_user_info(id).await {
        Ok(user) => Json(R::ok_with_data(user.into())),
        Err(e) => Json(R::fail_with_message(e.to_string())),
    }
}

// 方式二：返回 Result（适合错误直接由 AppError 处理时）
// AppError 的 IntoResponse 会自动转换为 JSON 响应
pub async fn delete_user(
    State(app_state): State<Arc<AppState>>,
    Path(id): Path<i64>,
) -> Result<Json<R<()>>, AppError> {
    app_state.user_service.delete_user(id).await?;
    Ok(Json(R::ok()))
}
```

---

## 3. 路由

```rust
Router::new().nest("/api/v1", Router::new()
    .nest("/users", Router::new()
        .route("/{id}", get(user::get_user))
        .route("/", post(user::create_user))
    )
).with_state(app_state)
```

- 路径 kebab-case：`/user-tenants`
- 参数 `{id}` 不是 `:id`
- 版本：`/api/v1/...`
- GET 查询 / POST 创建 / PUT 全量更新 / PATCH 部分更新 / DELETE 删除
