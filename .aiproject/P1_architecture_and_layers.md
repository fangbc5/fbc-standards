# 🟠 P1 — 分层架构与模块规范

> 影响代码组织和长期可维护性。
>
> 📅 最后更新: 2026-03-11

---

## 1. 调用方向

```
Handler → Service → Repository / CRUD
```

| 层 | 允许调用 | 禁止调用 |
|----|----------|----------|
| Handler | Service | Repository、sqlx |
| Service | Repository、CRUD、**其他模块的 Service** | Handler |
| Repository | sqlx、CRUD | Service、Handler |

---

## 2. 跨模块调用

**Service 间可互相调用，但禁止循环依赖。**

跨模块 Service 通过 `AppState` 注入，不直接 `use` 对方的内部实现：

```rust
// ✅ 正确：通过 AppState 注入的 Arc<XxxService> 调用
pub async fn create_org(&self, app_state: &AppState, dto: CreateOrgDto) -> Result<()> {
    // 调用 identity 模块的 Service
    let user = app_state.user_service.get_user_info(dto.creator_id).await?;
    // ...
}

// ❌ 错误：直接在 Service 中 use 另一个模块的 Repo
use crate::modules::user::repository::UserRepo;  // 禁止跨模块直接访问 Repo
```

**依赖方向建议**：如 A 调 B、B 调 A → 提取公共逻辑到新 Service 或使用事件驱动解耦。

---

## 3. 模块导出

```rust
// modules/user/mod.rs
mod handler; mod model; mod repository; mod service;
pub use model::*;
pub use repository::UserRepo;
pub use service::UserService;
pub use handler::*;

// modules/user/model/mod.rs
mod dto; mod entity;
pub use entity::{User, TenantUserRel};
pub use dto::*;
```

---

## 4. Repository

**只实现 CRUD trait 不存在的方法**（`find_by_username`、`exists_by_email` 等）。

以下方法已由 `sqlxplus::CRUD` trait 提供，**禁止重复实现**：

| 方法 | 说明 |
|------|------|
| `T::find_by_id(pool, id)` | 按主键查询 |
| `T::find_one(pool, builder)` | 条件查单条 |
| `T::find_list(pool, builder)` | 条件查列表 |
| `T::paginate(pool, builder, page, size)` | 分页查询 |
| `entity.insert(pool)` | 插入 |
| `entity.update(pool)` | 更新 |
| `T::delete_by_id(pool, id)` | 按主键删除 |

自定义查询用 `QueryBuilder`：

```rust
pub struct UserRepo;
impl UserRepo {
    pub async fn find_by_username(pool: &Pool<MySql>, name: &str) -> Result<User> {
        let builder = QueryBuilder::new("SELECT * FROM `user`").and_eq("username", name);
        User::find_one(pool, builder).await?.ok_or_else(|| error::user_not_found())
    }
}
```

---

## 5. Service

持有 `Arc<DbPool>`，调用 Repository 和 CRUD 方法。**禁止直接写 SQL。**

```rust
// 事务
sqlxplus::with_transaction(self.db_pool.mysql_pool(), |tx| async move {
    User::find_by_id(tx.as_mysql_executor(), id).await?;
    user.update(tx.as_mysql_executor()).await?;
    Ok(())
}).await

// 分页 → 返回 (Vec<T>, i64)
let result = User::paginate(pool, builder, page, size).await?;
Ok((result.items, result.total as i64))
```

---

## 6. Handler

只调用 Service，使用 Axum extractors + `R<T>` 响应。

### 基本示例

```rust
pub async fn get_user(
    State(app_state): State<Arc<AppState>>,
    Path(id): Path<i64>,
) -> Json<R<UserInfo>> {
    match app_state.user_service.get_user_info(id).await {
        Ok(user) => Json(R::ok_with_data(user.into())),
        Err(e) => Json(R::fail_with_message(e.to_string())),
    }
}
```

### 分页 Handler 示例

```rust
pub async fn list_users(
    State(app_state): State<Arc<AppState>>,
    Query(params): Query<UserListParams>,
) -> Json<R<CursorPageBaseResp<UserInfo>>> {
    match app_state.user_service.list_users(params).await {
        Ok((items, total)) => {
            let resp = CursorPageBaseResp::init(
                params.cursor, items.is_empty(), items, total
            );
            Json(R::ok_with_data(resp))
        }
        Err(e) => Json(R::fail_with_message(e.to_string())),
    }
}
```
