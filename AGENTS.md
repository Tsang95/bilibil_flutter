# b_flutter 工程规范

## 项目定位

本项目是 `doc_2026-08-20_21-51-08` 的全新实现。旧项目只作为 UI、业务规则、接口契约、插件依赖与资源基准，不复制其 Dart 实现。目录职责参考 `yes_flutter`，但公共基础设施与业务代码均重新设计。

## 目录职责

| 目录 | 职责 |
| --- | --- |
| `lib/api/` | 按业务模块声明 API，页面不得直接使用 Dio |
| `lib/common/` | 主题、颜色、视觉令牌和跨模块公共规范 |
| `lib/components/` | 两个及以上业务模块复用的 Widget |
| `lib/mixins/` | 可复用且有明确生命周期的业务行为 |
| `lib/models/` | 纯 Dart 数据模型与序列化 |
| `lib/pages/` | 按功能划分页面；功能内部组件放 `components/` |
| `lib/routes/` | 路由名、参数解析与页面注册 |
| `lib/stores/` | 全局状态、会话与长生命周期服务 |
| `lib/utils/` | 无 UI 业务耦合的工具和基础设施 |
| `test/` | 路径与 `lib/` 对应的单元及 Widget 测试 |
| `.vscode/` | VS Code 调试入口，仅引用工作区外的本机私有配置 |

## 当前基础文件

| 文件 | 职责 |
| --- | --- |
| `lib/common/app_environment.dart` | 构建环境、域名、接口及视频签名安全配置入口 |
| `lib/common/styles.dart` | 旧 UI 视觉令牌和全局主题 |
| `lib/common/utils.dart` | 键盘与公共页面行为 |
| `lib/components/legacy_app_bar.dart` | 旧 UI 导航栏 |
| `lib/components/legacy_text_field.dart` | 旧 UI 输入框 |
| `lib/components/legacy_action_button.dart` | 旧 UI 主次按钮 |
| `lib/components/legacy_field_label.dart` | 表单字段标题 |
| `lib/components/legacy_birthday_field.dart` | 生日选择字段 |
| `lib/components/legacy_prompt_dialog.dart` | 旧版登录、金币和 VIP 权限提示弹窗 |
| `lib/components/legacy_network_image.dart` | 旧资源域名兼容、缓存及失败占位图片 |
| `lib/components/post_access_badge.dart` | 首页帖子金币与 VIP 权限角标 |
| `lib/utils/api_client.dart` | 缓存、lock、去重、匿名/登录请求头、解析和错误统一处理 |
| `lib/utils/api_endpoint.dart` | 保留旧后端 `/api/api/` 规则的线路标准化 |
| `lib/utils/toast.dart` | 全局轻提示 |
| `lib/utils/request_cache.dart` | 请求缓存与 tag 失效 |
| `lib/utils/request_lock.dart` | 并发安全请求锁 |
| `lib/utils/legacy_protocol_interceptor.dart` | 旧后端签名及响应解密兼容层 |
| `lib/utils/video_url_resolver.dart` | 播放地址补全、已有签名复用及外部密钥时效签名 |
| `lib/stores/startup_controller.dart` | 启动、线路和配置状态 |
| `lib/stores/user_store.dart` | 当前账号全局状态 |
| `lib/api/bootstrap_api.dart` | 线路及应用配置接口 |
| `lib/api/auth_api.dart` | 登录、注册和密码恢复接口 |
| `lib/api/user_api.dart` | 当前账号资料接口 |
| `lib/api/home_api.dart` | 首页频道、轮播和分页内容接口 |
| `lib/api/search_api.dart` | 搜索分类、排行榜、帖子、用户与关注接口 |
| `lib/api/post_api.dart` | 帖子详情、弹幕及点赞、收藏、投币、关注、推荐和购买接口 |
| `lib/models/search_user.dart` | 搜索用户展示模型及关注状态 |
| `lib/models/post_detail.dart` | 帖子详情、游客限制、下载、广告、打赏、反馈、作者、标签和播放线路纯数据模型 |
| `lib/models/post_comment.dart` | 帖子评论、回复与评论用户模型 |
| `lib/models/post_barrage.dart` | 帖子弹幕内容与播放时间纯数据模型 |
| `lib/models/common_barrage.dart` | 常用弹幕选择项纯数据模型 |
| `lib/models/charge_subscription_product.dart` | UP 主充电套餐纯数据模型 |
| `lib/models/charge_member.dart` | UP 主充电计划页的作者资料与累计陪伴天数模型 |
| `lib/models/app_version.dart` | 旧版首页升级提示纯数据模型 |
| `lib/models/suggestion_reason.dart` | 调查问卷反馈原因纯数据模型 |
| `lib/stores/search_history_store.dart` | 搜索历史去重、限量与本地持久化 |
| `lib/pages/login/` | 登录、注册和忘记密码页面及页面控制器 |
| `lib/pages/home/` | 主导航壳、首页频道、懒加载内容流及首页组件 |
| `lib/pages/home/home_startup_controller.dart` | 首页启动后的旧版升级、问卷与弹窗广告顺序控制 |
| `lib/pages/home/home_advertisement_action.dart` | 首页广告点击统计、HTML 公告与外链跳转 |
| `lib/pages/home/components/home_startup_dialogs.dart` | 旧版升级、调查问卷入口与全屏广告弹窗 |
| `lib/pages/home/home_top_menu_page.dart` | 旧版四列首页分区入口页 |
| `lib/pages/home/home_partition_page.dart` | 旧版分区子标签、轮播与分页内容页 |
| `lib/pages/home/components/home_grid_advertisement_card.dart` | 旧版双列内容流广告卡片 |
| `lib/pages/mine/suggestion_page.dart` | 旧版调查问卷填写与提交成功页 |
| `lib/pages/search/` | 搜索历史、排行榜、帖子/用户结果及板块筛选 |
| `lib/pages/posts/` | 帖子详情、正文与用户互动组件 |
| `lib/pages/posts/banner_html_page.dart` | 旧版广告 HTML 公告页 |
| `lib/pages/posts/charge_user_page.dart` | 旧版全屏 UP 主充电计划页、套餐选择与提交 |
| `lib/pages/posts/post_label_page.dart` | 详情标签的独立懒加载帖子列表 |
| `lib/pages/posts/components/post_tag_post_card.dart` | 旧版标签详情页两列小卡片 |
| `lib/pages/posts/components/post_coin_animator_dialog.dart` | 旧版 22 娘投币选择与跳跃动画弹窗 |
| `lib/pages/posts/components/post_video_player.dart` | 基于 Chewie 与 fanjiao_danmu 的帖子播放、弹幕、倍速、手势、线路、锁定态、全屏与生命周期管理 |
| `lib/pages/posts/components/post_common_barrage_list.dart` | 发送弹幕下方的旧版常用弹幕浮层选择列表 |
| `lib/pages/posts/components/post_reward_sheet.dart` | 旧版帖子金币打赏选择与提交面板 |
| `lib/pages/posts/components/post_feedback_sheet.dart` | 旧版帖子问题原因选择与意见提交面板 |
| `test/pages/search/search_user_controller_test.dart` | 用户搜索分页、去重及末页状态测试 |
| `test/models/post_detail_test.dart` | 帖子详情兼容解析和不可变互动状态测试 |
| `test/pages/posts/post_comments_controller_test.dart` | 评论分页、去重和回复兼容解析测试 |
| `test/pages/posts/post_video_player_test.dart` | 视频金币/VIP 锁定态与延迟初始化测试 |
| `test/pages/posts/post_feedback_sheet_test.dart` | 反馈原因弹窗的 Material 水波纹承载测试 |
| `test/pages/posts/post_coin_animator_dialog_test.dart` | 22 娘投币选择、提交与自动关闭测试 |
| `test/models/post_barrage_test.dart` | 弹幕兼容字段和播放时间解析测试 |
| `test/models/post_interaction_models_test.dart` | 常用弹幕与充电套餐兼容解析测试 |
| `test/models/home_startup_models_test.dart` | 旧版升级与问卷原因兼容解析测试 |
| `test/utils/video_url_resolver_test.dart` | 视频地址签名、透传参数及免签行为测试 |
| `lib/pages/home/home_category_tab.dart` | 默认分组及三列竖版频道布局 |
| `lib/pages/home/home_forum_tab.dart` | 论坛筛选、图文信息流和广告布局 |
| `lib/pages/home/home_latest_tab.dart` | 热门话题与横向排行布局 |
| `lib/pages/home/components/home_latest_post_card.dart` | “最新”频道旧版左图右文信息流卡片 |
| `lib/pages/home/home_movie_tab.dart` | 影视横滑、通栏与双列混合布局 |
| `.vscode/settings.json` | 为所有 VS Code Flutter Run 自动注入本机配置 |

## 强制规则

- 文件和目录使用 `snake_case`，类使用 `PascalCase`，成员使用 `camelCase`。
- **旧版 UI 与功能必须一比一还原。** 每次重构必须先定位旧项目对应页面、组件、状态和交互，再据此实现；禁止仅根据接口数据流、通用设计习惯或主观猜想编写界面。旧版的文字、字体、颜色、尺寸、间距、圆角、图标、资源、动画、弹窗、空/加载/错误态，以及每一个可达功能与分支都不得擅自删减、合并或替换。旧实现或素材无法确认时必须先核对或向用户说明，不得自行补全为“合理”的新方案。
- 旧项目已有对应 Flutter 插件的功能必须沿用同一插件及兼容版本约束；仅在插件与当前 Flutter 不兼容或存在明确安全、稳定性问题时允许替换，并在 `docs/refactor_matrix.md` 记录原因和替代方案。
- 页面只依赖 API、store、model 和公共组件，不直接拼装网络请求。
- 长列表必须懒构建；禁止用大型 `shrinkWrap` 列表嵌套滚动容器。
- Timer、Controller、StreamSubscription、播放器和 Socket 必须在所属生命周期释放。
- 用户主动触发的所有数据提交都必须反馈成功或失败；后台静默刷新不弹成功提示。
- 写请求必须防重复提交，并主动失效相关请求缓存。
- Token、签名密钥、AES 密钥、签名文件和密码不得写入源码或日志。
- 新文件创建后同步更新本文件的目录表和 `docs/refactor_matrix.md`。
- 提交前执行 `dart format .`、`flutter analyze` 和 `flutter test`。
