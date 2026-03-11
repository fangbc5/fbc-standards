# 🟣 P3 — 数据层与配置

> 影响数据访问一致性和环境切换。
>
> 📅 最后更新: 2026-03-11

---

## 1. 实体定义

使用 `sqlxplus` 派生宏：

```rust
#[derive(Debug, Default, sqlx::FromRow, serde::Serialize, serde::Deserialize,
         sqlxplus::ModelMeta, sqlxplus::CRUD)]
#[model(table = "user", pk = "id", soft_delete = "is_del")]
pub struct User {
    pub id: Option<i64>,
    pub username: Option<String>,
    pub is_del: Option<i32>,
}
```

### 为什么字段使用 `Option`

`sqlxplus` 的设计约定：实体字段全部使用 `Option<T>` 类型，原因：
- **插入时**：`None` 字段自动跳过（使用数据库默认值，如自增 ID）
- **更新时**：`None` 字段不参与 SET 子句（实现**部分更新**）
- **查询时**：兼容 NULL 列值

> 注意：这不代表业务层允许 `None`，在 Service / Handler 中应通过 DTO 和校验确保必填字段有值。

### 连接池

从 `fbc_app_state` 获取，用 `DbPool::from_mysql_pool()` 转换。**禁止手动创建连接。**

---

## 2. 配置管理

环境变量 `APP__` 前缀，`__` 分隔层级：

```bash
APP__SERVER__PORT=3000
APP__DATABASE__MYSQL__URL=mysql://user:pass@localhost/db
APP__NACOS__SERVER_ADDR=127.0.0.1:8848
```

每个服务提供 `.env.example`。扩展配置直接读环境变量：

```rust
impl XxxConfig {
    pub fn new(base: BaseConfig) -> Result<Self> {
        Ok(Self {
            base,
            // ⚠️ 敏感配置必须 expect，禁止设默认值（防止生产遗漏）
            jwt_secret: std::env::var("APP__SERVICE__JWT__SECRET")
                .expect("缺少 APP__SERVICE__JWT__SECRET 环境变量"),
            // 非敏感配置可设默认值
            page_size: std::env::var("APP__SERVICE__PAGE_SIZE")
                .unwrap_or_else(|_| "20".into())
                .parse()
                .unwrap_or(20),
        })
    }
}
```

**规则：**
- 禁止硬编码敏感信息（密码、密钥、Token）
- 敏感配置必须 `expect()`，缺少时启动阶段 panic
- 非敏感配置可提供合理默认值
- 禁止重复使用 config crate 加载（框架已统一处理）

---

## 3. 数据库迁移

推荐使用 `sqlx migrate` 管理数据库 schema 变更：

```bash
# 创建迁移
sqlx migrate add create_user_table

# 运行迁移
sqlx migrate run --database-url mysql://user:pass@localhost/db
```

迁移文件放在 `migrations/` 目录，命名格式 `{timestamp}_{描述}.sql`。

> 如团队使用其他迁移工具（如 Flyway、手动 SQL），保持一致即可。
> 但必须确保所有 schema 变更有版本化的 SQL 脚本，禁止直接操作生产数据库。
