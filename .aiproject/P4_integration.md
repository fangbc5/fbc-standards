# 🟡 P4 — 集成能力

> 影响微服务间通信和中间件交互。
>
> 📅 最后更新: 2026-03-11

---

## 1. 缓存

使用 `CacheKeyBuilder` 构建键，**禁止手动拼接字符串**：

```rust
let key = SimpleCacheKeyBuilder::new("user")
    .with_modular("identity").with_field("id")
    .with_value_type(ValueType::Obj)
    .with_expire(Duration::from_secs(3600))
    .key(&[&user_id]);
```

键格式：`[前缀:][租户:][模块:]表[:字段][:值类型][:值]`

### 缓存策略

| 策略 | 规则 |
|------|------|
| 写后删除 | 写操作（INSERT / UPDATE / DELETE）后**删除**相关缓存 |
| 强制 TTL | 所有缓存**必须设过期时间**，防止内存泄漏 |
| 缓存穿透 | 查询不存在的数据时，缓存空值并设短 TTL（如 60s） |
| 批量操作 | 批量写操作后使用 `UNLINK` 批量删除相关键，避免逐条删除 |

---

## 2. gRPC — Proto 文件管理

### 目录约定

Proto 文件存放在**提供服务的微服务**自己的 `proto/` 目录下：

```
ms-identity/proto/identity.proto     # identity 服务定义
ms-organization/proto/organization.proto
ms-im/proto/health.proto
```

**消费方跨服务引用**时，使用相对路径引用提供方的 proto：

```rust
// ms-auth/build.rs — 消费 ms-identity 的 gRPC 服务
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(false)   // 消费方只需 client
        .build_client(true)
        .compile_protos(
            &["../ms-identity/proto/identity.proto"],
            &["../ms-identity/proto"],
        )?;
    Ok(())
}

// ms-identity/build.rs — 提供方只需 server
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true)
        .build_client(false)
        .compile_protos(&["proto/identity.proto"], &["proto"])?;
    Ok(())
}
```

### 规则

- 提供方：`build_server(true)` + `build_client(false)`
- 消费方：`build_server(false)` + `build_client(true)`
- 同时提供和消费：两者都设 `true`

---

## 3. gRPC — 服务调用

使用负载均衡器，**必须导入 `LoadBalancer` trait**：

```rust
use fbc_starter::{get_load_balancer, LoadBalancer};

let endpoint = get_load_balancer("ms-identity")
    .next_endpoint().ok_or_else(|| anyhow!("无可用实例"))?;
let mut client = XxxClient::new(endpoint.endpoint.connect().await?);
```

gRPC 服务在 `Server::run` 中通过 `builder.grpc_router(...)` 注册：

```rust
// main.rs
let grpc_router = tonic::transport::Server::builder()
    .add_service(grpc::IdentityServiceImpl::server(
        user_service, user_tenant_service, tenant_service
    ));
builder.http_router(http_router).grpc_router(grpc_router)
```

---

## 4. Kafka — 消费者

### 4.1 实现 `KafkaMessageHandler` trait

```rust
use async_trait::async_trait;
use fbc_starter::{KafkaMessageHandler, messaging::Message};

pub struct NotificationHandler {
    context: Arc<NotificationHandlerContext>,
}

#[async_trait]
impl KafkaMessageHandler for NotificationHandler {
    /// 返回要订阅的 topic 列表
    fn topics(&self) -> Vec<String> {
        vec!["notification".to_string(), "email".to_string()]
    }

    /// 返回消费者组 ID
    fn group_id(&self) -> String {
        "ms-notify-group".to_string()
    }

    /// 处理接收到的消息
    async fn handle(&self, message: Message) {
        match message.topic.as_str() {
            "notification" => self.handle_notification(message).await,
            "email" => self.handle_email(message).await,
            _ => tracing::warn!("未知 topic: {}", message.topic),
        }
    }
}
```

### 4.2 注册消费者

在 `Server::run` 中注册：

```rust
// 单个 handler
let handler: Arc<dyn KafkaMessageHandler> = Arc::new(NotificationHandler::new(context));
builder.with_kafka_handler(handler).http_router(http_router)

// 多个 handlers
let handlers: Vec<Arc<dyn KafkaMessageHandler>> = vec![
    Arc::new(LogHandler::new()),
    Arc::new(NotifyHandler::new()),
];
builder.with_kafka_handlers(handlers).http_router(http_router)
```

---

## 5. Kafka — 生产者

生产者通过 `fbc_app_state` 获取（框架自动初始化，需启用 `producer` feature）：

```rust
use fbc_starter::messaging::{Message, MessageProducer};

// 从 fbc_app_state 获取 producer
let producer = app_state.fbc.kafka_producer.as_ref()
    .expect("Kafka Producer 未初始化");

// 发送消息
let msg = Message::new("notification", "ms-identity", serde_json::json!({
    "user_id": user_id,
    "event": "user_created"
}));
producer.publish("notification", msg).await?;
```
