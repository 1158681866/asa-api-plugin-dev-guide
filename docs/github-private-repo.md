# GitHub 私有仓库

## 用 GitHub CLI 创建

如果已安装并登录 `gh`：

```powershell
gh auth login
gh repo create asa-api-plugin-dev-guide --private --source . --remote origin --push
```

## 网页创建后推送

如果没有 `gh`，可以在 GitHub 网页创建私有仓库，然后在本地执行：

```powershell
git remote add origin https://github.com/<owner>/asa-api-plugin-dev-guide.git
git branch -M main
git push -u origin main
```

## 检查远程

```powershell
git remote -v
git status
```

## 私有仓库建议

- 默认 private。
- 不提交服务器真实 IP、token、RCON 密码。
- 不提交编译产物 DLL，除非该仓库明确用于发布二进制。
- 文档和模板可以公开思路，但具体服主配置保留私有。
