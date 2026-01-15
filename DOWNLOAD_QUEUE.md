# 下载队列功能

## 功能概述

实现了一个完整的下载管理系统，支持：
- ✅ 下载任务队列管理
- ✅ 下载进度追踪
- ✅ 任务持久化（数据库存储）
- ✅ 断点续传（应用重启后继续下载）
- ✅ 后台下载支持
- ✅ 失败重试
- ✅ 批量操作

## 主要组件

### 1. 数据库层（Rust）
- **文件**: `rust/src/entities/download_task.rs`
- **功能**: 定义下载任务数据模型和数据库操作
- **字段**:
  - 作品信息：`illust_id`, `illust_title`, `page_index`, `page_count`
  - 下载信息：`url`, `target_path`, `save_target`
  - 状态信息：`status`, `progress`, `error_message`, `retry_count`
  - 时间信息：`created_time`, `updated_time`

### 2. API层（Rust）
- **文件**: `rust/src/api/api.rs`
- **功能**: 提供下载任务管理的API接口
- **主要方法**:
  - `create_download_task`: 创建下载任务
  - `get_all_download_tasks`: 获取所有任务
  - `get_pending_download_tasks`: 获取待处理任务
  - `update_download_task_status`: 更新任务状态
  - `retry_download_task`: 重试失败任务
  - `delete_download_task`: 删除任务
  - `execute_download_task`: 执行下载任务

### 3. 下载管理器（Flutter）
- **文件**: `lib/basic/download/download_manager.dart`
- **功能**: 
  - 管理下载队列
  - 自动处理待下载任务（每2秒检查一次）
  - 并发控制（最多同时处理3个任务）
  - 任务状态追踪

### 4. 下载服务（Flutter）
- **文件**: `lib/basic/download/download_service.dart`
- **功能**: 提供立即下载和队列下载两种模式
- **方法**:
  - `downloadIllust`: 立即下载作品
  - `downloadIllustQueued`: 添加作品到下载队列
  - `downloadSingleImage`: 立即下载单张图片
  - `downloadSingleImageQueued`: 添加单张图片到下载队列

### 5. 下载列表UI（Flutter）
- **文件**: `lib/screens/download_list_screen.dart`
- **功能**:
  - 显示所有下载任务
  - 实时更新下载进度
  - 支持重试、删除等操作
  - 显示统计信息

## 使用方式

### 1. 用户配置
在设置界面可以：
- 开启/关闭下载队列功能
- 查看下载列表
- 配置下载目录和保存位置

### 2. 下载模式切换
- **队列模式**（默认）: 点击下载后添加到队列，后台自动处理
- **立即模式**: 关闭队列功能后，点击下载立即执行

### 3. 查看下载状态
在设置 > 下载列表中可以：
- 查看所有下载任务
- 查看统计信息（总计、等待中、下载中、已完成、失败）
- 重试失败的任务
- 删除任务
- 清除已完成的任务

## 技术实现

### 数据持久化
- 使用SQLite数据库存储下载任务
- 数据库文件：`download_tasks.db`
- 应用重启后自动加载未完成的任务

### 后台处理
- 使用定时器（Timer）每2秒检查一次待处理任务
- 自动并发处理（最多3个任务）
- 支持暂停/继续

### 状态管理
使用Signals进行响应式状态管理：
- `tasksSignal`: 任务列表
- `isProcessingSignal`: 是否正在处理
- `useDownloadQueueSignal`: 是否使用队列模式

### 错误处理
- 自动重试机制
- 错误信息记录
- 重试次数统计

## 国际化支持

已添加中英文支持：
- 下载列表相关文本
- 状态描述
- 操作提示

## 注意事项

1. **权限要求**: 在Android和iOS上可能需要存储权限
2. **后台限制**: Flutter在后台可能会断网，数据库持久化确保任务不丢失
3. **并发控制**: 默认最多同时下载3个任务，避免过多并发
4. **自动清理**: 可以手动清除已完成的任务，释放数据库空间

## 未来优化

可能的改进方向：
- [ ] 支持自定义并发数
- [ ] 支持下载优先级
- [ ] 支持暂停/恢复单个任务
- [ ] 支持下载速度限制
- [ ] 支持分类管理（按作品、按日期等）
- [ ] 导出下载历史
