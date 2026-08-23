# 架构基线

## 数据流

`Page -> Store/Controller -> XxxApi -> ApiClient -> Dio`

- Page 只负责渲染和转发用户意图。
- Store/Controller 管理页面状态、竞态、乐观更新及失败回滚。
- XxxApi 表达业务接口和模型转换。
- ApiClient 统一处理域名、Header、缓存、lock、去重、异常和响应解包。

## 用户反馈

- `showToast`：短反馈，支持 text/success/error/warning/info。
- `SubmissionFeedback.run`：提交动作的 loading、成功提示、失败提示和异常传递。
- 初始化和后台刷新不显示成功 Toast；主动刷新及所有主动提交必须显示结果。

## 缓存

- 缓存键由请求方法、路径、参数、账号作用域和运行环境稳定生成。
- 查询接口按调用配置 TTL；写接口成功后按 tag 主动失效关联缓存。
- 同一查询在途时合并请求，页面销毁时通过 CancelToken 取消无需继续的请求。

## 安全

正式域名与加密/签名密钥通过 `--dart-define` 或 CI secret 注入。源码只保留配置字段名，不保留旧工程中的明文凭据。

所需字段：`API_DOMAINS`、`WS_URL`、`API_SIGNING_KEY`、`API_RESPONSE_AES_KEY`、`API_RESPONSE_IV_PREFIX`、`IDENTITY_CARD_IV_SUFFIX` 和 `APP_CHANNEL`。
