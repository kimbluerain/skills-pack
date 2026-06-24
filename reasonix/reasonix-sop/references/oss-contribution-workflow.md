# 开源项目 PR 贡献流程

## 全流程（按 SOP 执行）

### 第 1 步：澄清
确认要修什么 issue，不改本地 App，只动源码仓库。明确涉及的几个文件。

### 第 2 步：扫描 skill
相关 skill：`github-workflow`（PR 流程）、`kanban-orchestrator`（多 agent 分工）、`reasonix-superpower`。

### 第 3 步：规划
1. Fork 上游仓库
2. Clone 自己的 fork（注意设代理）
3. 调研代码，理解根因
4. 分配任务给 coder（指定模型/分支名）
5. Reviewer 审查后才算完成
6. 推分支 + 提 PR

### 第 4 步：执行细节

```bash
# 0. 确认代理端口（macOS 系统代理在 7897，不是 7892）
export http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897

# 1. Fork
curl -X POST "https://api.github.com/repos/upstream/repo/forks"

# 2. Clone（depth=1 节省时间）
git clone --depth 1 https://github.com/yourname/repo.git /tmp/repo
cd /tmp/repo
git remote add fork https://github.com/yourname/repo.git

# 3. 建分支（从 main 出发）
git checkout main
git checkout -b fix/issue-number-description

# 4. 改代码后
git add -A
git commit -m "fix(scope): description"

# 5. 推分支（用 token 在 URL 中认证）
git remote set-url fork https://user:TOKEN@github.com/yourname/repo.git
git push fork fix/issue-number-description --force
# 立刻清除 token，防 keychain 弹窗
git config --global credential.helper "cache --timeout=3600"
git remote set-url fork https://github.com/yourname/repo.git

# 6. 提 PR
curl -s -X POST "https://api.github.com/repos/upstream/repo/pulls" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"fix(scope): desc","head":"yourname:fix/branch","base":"main","body":"Fix #123\\n\\nRoot cause: ...\\nFix: ..."}'
```

### 第 5 步：检查
- PR 只包含本 issue 的改动（`git diff main...branch --stat`）
- 多个 PR 不能有重叠的 commit
- CI 通过
- Issue 已关联

## 常见坑

### 多子 agent 同时改同一个仓库 → 分支污染

**具体场景（本 session 遇到的）：**
两个 `delegate_task` 子 agent 用同一个仓库路径（如 `/tmp/repo`）先后执行。第一个 agent 改了代码，第二个 agent 在同一个目录上工作，**继承了第一个 agent 的全部改动** → 第二个分支里包含了第一个分支的 commit → PR 内容重叠。

```python
# ❌ 错误的做法：两个任务用同一个路径，先后执行
delegate_task(tasks=[
    {"goal": "修 #1546", "context": "仓库在 /tmp/repo"},
    {"goal": "修 #1450", "context": "仓库在 /tmp/repo"},
])
# → 第二个 agent 看到的是第一个 agent 改完后的代码
```

**两种解决方案：**

方案 A（可靠）：每个子 agent 用独立的 clone
```python
delegate_task(tasks=[
    {"goal": "修 #1546", "context": "clone 到 /tmp/repo-fix-1546"},
    {"goal": "修 #1450", "context": "clone 到 /tmp/repo-fix-1450"},
])
```

方案 B（推荐，省空间）：同一个目录，但确保 clean start
```python
# 每次 spawn 前重置：
# cd /tmp/repo && git checkout main && git reset --hard origin/main
# 或者 spawn 后让子 agent 自己从 main 建分支
```

**验收方法（提交前必做）：**
```bash
git diff main...my-branch --stat
```
只看这一行：如果文件数和你预期的不一致（比如多了不属于本 issue 的文件），说明分支被污染了。

### Reviewer 发现分支污染后的修复流程
如果 reviewer 反馈 PR 有分支污染问题：
1. 从 main 重建干净分支：`git checkout main && git checkout -b fix/clean-branch`
2. 只 cherry-pick 属于本 issue 的改动，或者直接重新改代码
3. 确认 `git diff main...branch --stat` 只有预期文件
4. force push 更新 PR：`git push fork fix/clean-branch --force`

### 测试必须验证 computed/sorted 属性，不要只测 raw data
被 reviewer 纠正过的模式：
- ❌ `expect(store.messages[0].id).toBe('...')` — 测试的是原始数组（事件到达顺序）
- ✅ `expect(store.sortedMessages[0].id).toBe('...')` — 测试的是实际渲染用的 computed 属性

规则：尽可能断言**用户看到的内容**，而不是底层数据源。

### git push 超时或弹"Keychain Not Found"对话框
- 代理没设：`export http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897`（端口以当前生效为准，见 Step 4 代理检查说明）
- token-in-URL 后 git 试图存 macOS 钥匙串 → 弹对话框
- 完全修复方案（三步修好不再弹）：
  1. `git config --global credential.helper ""` — 清空列表，覆盖系统 osxkeychain
  2. `git config --global --add credential.helper "cache --timeout=3600"` — 只记内存，不碰钥匙串
  3. 把 GitHub token 写入 `~/.netrc`：`echo -e "machine github.com\\nlogin yourname\\npassword TOKEN" >> ~/.netrc && chmod 600 ~/.netrc`
  4. 另在 `.zshrc` 加 `export GIT_CONFIG_SYSTEM=/dev/null` 彻底屏蔽 Apple 自带的系统 gitconfig
- 推完立刻清 remote URL：`git remote set-url fork https://github.com/yourname/repo.git`
- macOS 钥匙串弹窗的根本原因：/Library/Developer/CommandLineTools/usr/share/git-core/gitconfig 里写死了 `helper = osxkeychain`

### GitHub API 把 PR 当 issue 数
`GET /repos/{o}/{r}/issues` 返回的是 issue + PR 的混合体。查真实 issue 数要用 search API：
```
GET /search/issues?q=repo:{o}/{r}+state:open+type:issue
```

### 测试跑不了
本地缺依赖时不用纠结，GitHub Actions CI 会跑。代码对、测试结构对就行。
