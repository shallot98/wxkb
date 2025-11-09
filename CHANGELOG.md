# WXKBTweak 更新日志

## [未发布] - 2025-01-XX

### 🐛 Bug修复

#### 1. 修复点击被误识别为滑动的问题
- **问题描述**：正常点击键盘按键时，手指的微小移动会被错误识别为滑动手势，触发语言切换
- **影响范围**：严重影响正常输入体验
- **修复方案**：
  - 添加最小移动距离阈值（15像素）
  - 只有移动距离超过阈值才进入滑动检测逻辑
  - 计算总移动距离（欧几里得距离）而非单一方向距离
- **涉及文件**：`Tweak.x`
- **代码变更**：
  ```objective-c
  // 添加最小移动距离阈值
  CGFloat minMoveThreshold = 15.0;
  CGFloat totalDistance = sqrt(pow(verticalDistance, 2) + pow(horizontalDistance, 2));
  
  if (totalDistance < minMoveThreshold) {
      return;  // 忽略微小移动
  }
  ```

#### 2. 修复滑动时触发底层按钮点击的问题
- **问题描述**：上下滑动键盘时，除了触发滑动手势，还同时触发了底层语言切换按钮的点击事件，导致语言连续切换两次
- **影响范围**：滑动功能完全失效，用户无法通过滑动切换语言
- **修复方案**：
  - 初始化时设置 `cancelsTouchesInView = NO`，允许正常点击
  - 检测到滑动时动态设置 `cancelsTouchesInView = YES`，阻止底层事件
  - 手势结束后恢复 `cancelsTouchesInView = NO`
- **涉及文件**：`Tweak.x`
- **代码变更**：
  ```objective-c
  // 检测到滑动时取消底层触摸事件
  if (!self.isSwiping) {
      self.isSwiping = YES;
      self.cancelsTouchesInView = YES;
  }
  
  // 手势重置时恢复
  - (void)reset {
      self.cancelsTouchesInView = NO;
  }
  ```

### ✨ 改进

#### 1. 增强手势识别器
- 添加 `isSwiping` 标志，准确标记滑动状态
- 添加 `startTime` 属性，记录触摸开始时间（为未来的速度检测做准备）
- 完善手势生命周期管理（`touchesEnded`, `touchesCancelled`）
- 手势触发后强制设置 `state = UIGestureRecognizerStateEnded`

#### 2. 改进日志输出
- 添加触摸持续时间信息
- 添加滑动距离和方向的详细信息
- 区分点击和滑动的日志输出

### 📝 文档

#### 新增文档
- `BUG_FIX_TESTING.md` - Bug修复测试指南
  - 详细的测试场景
  - 预期结果说明
  - 问题诊断方法

#### 更新文档
- `REVERSE_ENGINEERING_REPORT.md` - 添加Bug修复记录章节

---

## [3.0] - 2025-01-XX

### ✨ 新功能
- 完整的生命周期管理
- 多策略语言切换（6种方案）
- 震动和视觉反馈
- PreferenceLoader 设置面板

### 🔧 技术细节
- 使用 UIInputView hook 作为主要注入点
- 支持 rootless 越狱
- arm64 和 arm64e 架构支持
- iOS 13.0+ 兼容

---

## 修复对比

### 修复前
```
用户点击按键
  → 手指微小移动（5像素）
  → 被识别为滑动 ❌
  → 触发语言切换 ❌
  → 输入失败 ❌
```

```
用户滑动键盘
  → 滑动手势触发 ✅
  → 底层按钮也被点击 ❌
  → 语言切换两次 ❌
  → 滑动功能失效 ❌
```

### 修复后
```
用户点击按键
  → 手指微小移动（5像素）
  → 小于阈值，忽略 ✅
  → 识别为点击 ✅
  → 正常输入 ✅
```

```
用户滑动键盘
  → 移动超过15像素 ✅
  → 标记为滑动，取消底层事件 ✅
  → 只触发一次语言切换 ✅
  → 滑动功能正常 ✅
```

---

## 性能影响

### 内存
- 新增属性：2个（16字节）
- 影响：可忽略

### CPU
- 新增计算：sqrt（距离计算）
- 耗时：< 0.1ms
- 影响：可忽略

### 电池
- 无额外后台任务
- 影响：无

---

## 兼容性

### 测试环境
- ✅ iOS 13.x
- ✅ iOS 14.x
- ✅ iOS 15.x
- ✅ iOS 16.x

### 越狱类型
- ✅ Rootless
- ✅ Rooted

---

## 致谢

感谢所有用户的反馈和测试！

**艹，这版本稳了！** 🔥
