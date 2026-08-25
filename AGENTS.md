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
| `lib/common/creator_access_policy.dart` | 创作者发布会员校验策略及临时测试放行开关 |
| `lib/common/styles.dart` | 旧 UI 视觉令牌和全局主题 |
| `lib/common/utils.dart` | 键盘与公共页面行为 |
| `lib/components/legacy_app_bar.dart` | 旧 UI 导航栏 |
| `lib/components/legacy_text_field.dart` | 旧 UI 输入框 |
| `lib/components/legacy_action_button.dart` | 旧 UI 主次按钮 |
| `lib/components/legacy_field_label.dart` | 表单字段标题 |
| `lib/components/legacy_birthday_field.dart` | 生日选择字段 |
| `lib/components/legacy_prompt_dialog.dart` | 旧版登录、金币和 VIP 权限提示弹窗 |
| `lib/components/legacy_pay_password_dialog.dart` | 旧版六位支付密码输入及重复确认弹窗 |
| `lib/components/legacy_network_image.dart` | 旧资源域名兼容、缓存及失败占位图片 |
| `lib/components/post_access_badge.dart` | 首页帖子金币与 VIP 权限角标 |
| `lib/utils/api_client.dart` | 缓存、lock、去重、匿名/登录请求头、解析和错误统一处理 |
| `lib/utils/api_endpoint.dart` | 保留旧后端 `/api/api/` 规则的线路标准化 |
| `lib/utils/toast.dart` | 全局轻提示 |
| `lib/utils/request_cache.dart` | 请求缓存与 tag 失效 |
| `lib/utils/request_lock.dart` | 并发安全请求锁 |
| `lib/utils/legacy_protocol_interceptor.dart` | 旧后端签名及响应解密兼容层 |
| `lib/utils/video_url_resolver.dart` | 播放地址补全、已有签名复用及外部密钥时效签名 |
| `lib/utils/configured_link.dart` | 启动配置外链的校验、打开及旧版失败轻提示 |
| `lib/stores/startup_controller.dart` | 启动、线路和配置状态 |
| `lib/stores/user_store.dart` | 当前账号全局状态 |
| `lib/api/bootstrap_api.dart` | 线路及应用配置接口 |
| `lib/api/auth_api.dart` | 登录、注册、密码恢复和登录密码修改接口 |
| `lib/api/user_api.dart` | 当前账号资料接口 |
| `lib/api/home_api.dart` | 首页频道、轮播和分页内容接口 |
| `lib/api/search_api.dart` | 搜索分类、排行榜、帖子、用户与关注接口 |
| `lib/api/message_api.dart` | 站内信、评论互动、私信会话及发送接口 |
| `lib/api/advertising_api.dart` | 旧版广告位置、套餐、投放记录、统计与提交接口 |
| `lib/api/game_api.dart` | 游戏大厅轮播、分类和余额接口 |
| `lib/api/post_api.dart` | 帖子详情、弹幕及点赞、收藏、投币、关注、推荐和购买接口 |
| `lib/api/topic_api.dart` | 话题搜索与话题帖子分页接口 |
| `lib/api/active_api.dart` | 动态列表、图片/视频分片上传、发布与推广统计接口 |
| `lib/api/creator_api.dart` | 创作灵感分类与创作学院推荐接口 |
| `lib/models/search_user.dart` | 搜索用户展示模型及关注状态 |
| `lib/models/user_profile.dart` | 旧版用户详情资料、主页四组视频纯数据模型 |
| `lib/models/post_detail.dart` | 帖子详情、游客限制、下载、广告、打赏、反馈、作者、标签和播放线路纯数据模型 |
| `lib/models/post_comment.dart` | 帖子评论、回复与评论用户模型 |
| `lib/models/post_barrage.dart` | 帖子弹幕内容与播放时间纯数据模型 |
| `lib/models/common_barrage.dart` | 常用弹幕选择项纯数据模型 |
| `lib/models/charge_subscription_product.dart` | UP 主充电套餐纯数据模型 |
| `lib/models/charge_member.dart` | UP 主充电计划页的作者资料与累计陪伴天数模型 |
| `lib/models/app_version.dart` | 旧版首页升级提示纯数据模型 |
| `lib/models/suggestion_reason.dart` | 调查问卷反馈原因纯数据模型 |
| `lib/models/home_label.dart` | 首页“更多”页面分类标签纯数据模型 |
| `lib/models/invite_summary.dart` | 推广中心邀请人数、奖励金币与分享域名模型 |
| `lib/models/upload_file_result.dart` | 图片及视频分片上传结果模型 |
| `lib/models/message_models.dart` | 消息互动、会话、联系人和聊天记录纯数据模型 |
| `lib/models/advertising_models.dart` | 旧版广告位置、套餐、投放记录与统计纯数据模型 |
| `lib/models/game_category.dart` | 游戏分类、项目、优惠活动、充值方式、通道与记录纯数据模型 |
| `lib/models/follow_user.dart` | 我的关注列表用户纯数据模型 |
| `lib/models/fan_user.dart` | 我的粉丝列表用户及关注关系纯数据模型 |
| `lib/models/help_item.dart` | 帮助中心条目纯数据模型 |
| `lib/models/task_models.dart` | 每日签到奖励、签到摘要与任务中心条目纯数据模型 |
| `lib/models/user_charge_price.dart` | UP 主充电套餐月卡、季卡和半年卡金币价格纯数据模型 |
| `lib/models/vip_models.dart` | 旧版会员套餐、钱包变动、充值商品、渠道、订单、充值及提现记录纯数据模型 |
| `lib/models/creation_topic.dart` | 旧版创作灵感分组及投稿话题纯数据模型 |
| `lib/models/creator_models.dart` | 创作者作品统计、最近收益和作品审核记录纯数据模型 |
| `lib/models/creator_data_center_models.dart` | 创作者数据概览与折线图纯数据模型 |
| `lib/models/creator_publish_models.dart` | 创作者发布板块、分类、类型、合集和金额选项模型 |
| `lib/models/google_verify_data.dart` | 谷歌验证码密钥与二维码纯数据模型 |
| `lib/stores/search_history_store.dart` | 搜索历史去重、限量与本地持久化 |
| `lib/pages/login/` | 登录、注册和忘记密码页面及页面控制器 |
| `lib/pages/active/` | 旧版全部/视频动态流、动态卡片与发布动态页 |
| `lib/pages/home/` | 主导航壳、首页频道、懒加载内容流及首页组件 |
| `lib/pages/home/home_startup_controller.dart` | 首页启动后的旧版升级、问卷与弹窗广告顺序控制 |
| `lib/pages/home/home_advertisement_action.dart` | 首页广告点击统计、HTML 公告与外链跳转 |
| `lib/pages/home/components/home_startup_dialogs.dart` | 旧版升级、调查问卷入口与全屏广告弹窗 |
| `lib/pages/home/home_top_menu_page.dart` | 旧版四列首页分区入口页 |
| `lib/pages/home/home_partition_page.dart` | 旧版分区子标签、轮播与分页内容页 |
| `lib/pages/home/home_more_posts_page.dart` | 旧版普通频道“更多”标签筛选与分页内容页 |
| `lib/pages/home/components/home_grid_advertisement_card.dart` | 旧版双列内容流广告卡片 |
| `lib/pages/mine/suggestion_page.dart` | 旧版调查问卷填写与提交成功页 |
| `lib/pages/mine/invite_page.dart` | 旧版推广中心统计、邀请码与复制链接页 |
| `lib/pages/mine/mine_page.dart` | 旧版“我的”主入口：账户摘要、服务宫格、认证/会员和发布推广卡片 |
| `lib/pages/message/` | 旧版站内信、评论互动、客服入口与私信会话 |
| `lib/pages/message/message_page.dart` | 旧版消息顶部入口、私信会话与评论互动分页列表 |
| `lib/pages/message/message_chat_page.dart` | 旧版文本私信历史与发送页 |
| `lib/pages/game/game_page.dart` | 旧版游戏大厅：轮播、余额、服务动作、分类与双列游戏入口 |
| `lib/pages/game/game_activity_page.dart` | 旧版优惠活动列表、活动期和 HTML 公告跳转 |
| `lib/pages/game/game_detail_page.dart` | 旧版游戏 WebView、横屏、悬浮退出与退出接口 |
| `lib/pages/game/game_recharge_page.dart` | 旧版充值支付方式、通道、快捷金额、支付跳转与完成确认 |
| `lib/pages/game/game_recharge_record_page.dart` | 旧版充值记录分页、刷新与状态展示 |
| `lib/pages/game/game_withdraw_page.dart` | 旧版提现前置校验、银行卡状态、余额和提交页 |
| `lib/pages/game/game_bind_bank_page.dart` | 旧版银行卡绑定表单与银行选择页 |
| `lib/pages/game/game_withdraw_record_page.dart` | 旧版提现记录分页、刷新与状态展示 |
| `lib/pages/follow/follow_list_page.dart` | 旧版我的关注搜索、排序和分页列表 |
| `lib/pages/follow/follow_list_controller.dart` | 我的关注查询、排序、去重与分页状态控制器 |
| `lib/pages/mine/my_fans_page.dart` | 旧版我的粉丝分页与关注操作页 |
| `lib/pages/mine/my_fans_controller.dart` | 我的粉丝加载、去重、分页与关注操作状态控制器 |
| `lib/pages/mine/help_center_page.dart` | 旧版帮助中心加载、刷新与问答条目页 |
| `lib/pages/mine/change_password_page.dart` | 旧版修改登录密码表单、校验和客服入口 |
| `lib/pages/mine/google_verify_page.dart` | 旧版谷歌验证码二维码、密钥复制和绑定页 |
| `lib/pages/mine/google_binded_page.dart` | 旧版谷歌验证码绑定成功及客服入口页 |
| `lib/pages/mine/look_history_page.dart` | 旧版历史记录板块筛选、分页和创作者帖子卡片页 |
| `lib/pages/mine/collect_page.dart` | 旧版我的收藏板块筛选、分页和创作者帖子卡片页 |
| `lib/pages/mine/buy_page.dart` | 旧版我的购买板块筛选、分页和创作者帖子卡片页 |
| `lib/pages/mine/set_pay_password_page.dart` | 旧版六位数字支付密码设置、校验和客服入口页 |
| `lib/pages/mine/task_center_page.dart` | 旧版每日签到奖励、每日/永久任务和任务跳转页 |
| `lib/pages/mine/personal_info_page.dart` | 旧版头像、昵称、性别、签名、主页背景和充电计划资料页 |
| `lib/pages/mine/profile_text_edit_page.dart` | 旧版昵称及个性签名通用编辑页 |
| `lib/pages/mine/set_charge_price_page.dart` | 旧版 UP 主充电套餐价格加载及设置页 |
| `lib/pages/mine/user_feedback_page.dart` | 旧版 500 字用户建议填写、校验及提交页 |
| `lib/pages/mine/identity_card_page.dart` | 旧版身份卡弹窗：二维码、账号密码和回家域名展示 |
| `lib/pages/vip/` | 旧版会员中心、钱包、充值、USDT 收款充值、USDT 提现及对应记录页 |
| `lib/pages/creator/creation_center_page.dart` | 旧版创作灵感分类、投稿入口与创作学院横向课程页 |
| `lib/pages/creator/creator_center_page.dart` | 旧版创作者中心：发布入口、作品统计与最近七天收益 |
| `lib/pages/creator/creator_history_page.dart` | 旧版发布成功、审核中和审核失败作品分页记录页 |
| `lib/pages/creator/data_center_page.dart` | 旧版数据概览、创作收益和粉丝分析页 |
| `lib/pages/creator/creator_work_page.dart` | 旧版作品发布分类、权限、标题、图片、媒体与富文本表单 |
| `lib/pages/creator/creator_work_controller.dart` | 作品发布选项、上传、校验、提交及资源生命周期控制器 |
| `lib/pages/ads/advertising_pages.dart` | 旧版广告投放首页、广告位/时长/封面/跳转表单及我的广告状态列表 |
| `lib/pages/search/` | 搜索历史、排行榜、帖子/用户结果及板块筛选 |
| `lib/pages/topics/` | 旧版话题中心搜索、话题帖子列表与帖子操作面板 |
| `lib/pages/posts/` | 帖子详情、正文与用户互动组件 |
| `lib/pages/posts/user_profile_page.dart` | 旧版用户详情资料卡、主页、动态与投稿分页页 |
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
| `test/models/user_profile_test.dart` | 用户详情资料和主页四组视频旧字段兼容解析测试 |
| `test/models/post_detail_test.dart` | 帖子详情兼容解析和不可变互动状态测试 |
| `test/pages/posts/post_comments_controller_test.dart` | 评论分页、去重和回复兼容解析测试 |
| `test/pages/posts/post_video_player_test.dart` | 视频金币/VIP 锁定态与延迟初始化测试 |
| `test/pages/posts/post_feedback_sheet_test.dart` | 反馈原因弹窗的 Material 水波纹承载测试 |
| `test/pages/posts/post_coin_animator_dialog_test.dart` | 22 娘投币选择、提交与自动关闭测试 |
| `test/pages/topics/topic_post_card_test.dart` | 旧版话题帖子卡片分区、尺寸与操作栏回归测试 |
| `test/models/post_barrage_test.dart` | 弹幕兼容字段和播放时间解析测试 |
| `test/models/post_interaction_models_test.dart` | 常用弹幕与充电套餐兼容解析测试 |
| `test/models/home_startup_models_test.dart` | 旧版升级与问卷原因兼容解析测试 |
| `test/models/active_models_test.dart` | 动态上传结果与推广统计兼容解析测试 |
| `test/models/advertising_models_test.dart` | 广告位置、套餐、记录和嵌套统计旧字段兼容解析测试 |
| `test/utils/video_url_resolver_test.dart` | 视频地址签名、透传参数及免签行为测试 |
| `test/utils/api_client_multipart_test.dart` | Multipart 请求缓存键与文件元数据测试 |
| `test/api/active_api_test.dart` | 视频分片上传瞬时故障重试与业务错误停止测试 |
| `test/pages/mine/change_password_page_test.dart` | 修改登录密码旧版表单字段回归测试 |
| `test/pages/mine/google_verify_page_test.dart` | 谷歌验证码绑定及成功页旧版布局回归测试 |
| `test/pages/mine/look_history_page_test.dart` | 历史记录筛选栏与创作者帖子卡片回归测试 |
| `test/pages/mine/collect_page_test.dart` | 我的收藏筛选栏与创作者帖子卡片回归测试 |
| `test/pages/mine/buy_page_test.dart` | 我的购买筛选栏与创作者帖子卡片回归测试 |
| `test/pages/mine/set_pay_password_page_test.dart` | 支付密码旧版双字段表单回归测试 |
| `test/models/task_models_test.dart` | 签到与任务中心旧接口模型兼容解析测试 |
| `test/pages/mine/task_center_page_test.dart` | 任务中心标题、签到区和任务页签旧版布局回归测试 |
| `test/models/user_charge_price_test.dart` | 充电套餐价格与用户资料不可变更新兼容解析测试 |
| `test/pages/mine/profile_text_edit_page_test.dart` | 昵称/个性签名编辑页文本区、计数器和保存入口回归测试 |
| `test/pages/mine/user_feedback_page_test.dart` | 用户建议 500 字表单、提示和提交入口回归测试 |
| `test/pages/mine/identity_card_page_test.dart` | 身份卡缺失内存密码时仍展示身份卡的回归测试 |
| `test/utils/identity_card_decoder_test.dart` | 身份卡旧 AES 凭证解密及二维码加密兼容测试 |
| `test/models/vip_models_test.dart` | 会员、钱包及充值模型旧字段兼容解析测试 |
| `test/pages/vip/vip_center_page_test.dart` | 会员中心双页签与加载态回归测试 |
| `test/pages/vip/withdraw_page_test.dart` | USDT 提现表单及支付密码弹窗回归测试 |
| `test/pages/vip/recharge_usdt_page_test.dart` | USDT 收款充值卡片、二维码、倒计时与无效订单回归测试 |
| `test/models/creation_topic_test.dart` | 创作灵感分组与话题旧字段兼容解析测试 |
| `test/pages/creator/creation_center_page_test.dart` | 创作灵感、投稿权限提示与创作学院布局回归测试 |
| `test/models/creator_models_test.dart` | 创作者统计、收益及作品记录旧字段兼容解析测试 |
| `test/models/creator_data_center_models_test.dart` | 数据中心统计及图表混合字段兼容解析测试 |
| `test/models/creator_publish_models_test.dart` | 作品发布选项旧字段解析与临时会员放行开关测试 |
| `test/pages/creator/creator_center_page_test.dart` | 创作者中心发布入口、作品统计和收益表格回归测试 |
| `test/pages/creator/creator_history_page_test.dart` | 我的作品三状态页签与作品卡片布局回归测试 |
| `test/pages/creator/data_center_page_test.dart` | 数据中心三页签、指标卡及统计区旧版布局回归测试 |
| `test/pages/creator/creator_option_sheet_test.dart` | 发布作品大量选项在小屏上的滚动与防溢出回归测试 |
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
