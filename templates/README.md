# 模板文件

这里存放可以公开维护的 OpenClash / Mihomo 模板。

## `proxy-groups.yaml`

精简代理组模板，不包含订阅地址、token 或本地密码。

模板中的：

```text
__PROVIDER_NAMES__
```

需要由路由器本地脚本替换为本机实际的 `proxy-providers` 名称。

敏感信息只保存在路由器本地，不进入 GitHub 仓库。
