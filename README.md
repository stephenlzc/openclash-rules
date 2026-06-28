# OpenClash 个人分流规则

这是一个给 iStoreOS / OpenClash / Mihomo 使用的个人规则仓库。

目标是把 `blackmatrix7/ios_rule_script` 维护的 Clash YAML 规则和自己的少量补充规则合并成稳定的 `rule-providers` 文件，然后让 OpenClash 只订阅这个仓库里的规则，避免在路由器上直接挂一堆第三方地址。

通用域名规则不在本仓库重复维护。比如 OpenAI、YouTube、Google、GitHub、常见媒体等 YAML 都直接来自 `blackmatrix7/ios_rule_script`；本仓库只保留 Typeless、Shopee 台湾、日志里看到的漏网域名、以及上游暂时没有覆盖的个人补充规则。

`rules/*.yaml` 是自动生成文件，不要手工修改。每次运行 `npm run build` 或 GitHub Actions 自动更新时，这些文件都会被重新生成。

## 分流策略

当前计划：

| 流量类型 | 目标策略组 |
| --- | --- |
| YouTube | `🇭🇰 香港` |
| Google 主体 | `🇭🇰 香港` |
| GitHub 相关 | `🇭🇰 香港` |
| X / Twitter | `🇭🇰 香港` |
| Typeless | `📝 Typeless` |
| ChatGPT / OpenAI / Codex | `🌏 台湾/新加坡 AI` |
| Claude / Anthropic / Grok / Gemini / NotebookLM / Perplexity | `🇺🇸 美国 AI` |
| Shopee 台湾 | `🛒 台湾 Shopee` |
| 流媒体 | `🇭🇰 香港` |
| 欧美新闻、各国网站 | `🇺🇸🇨🇦🇪🇺🇬🇧 欧美地区` |
| 中国大陆域名和 IP、局域网 | `🎯 全球直连` |
| 漏网之鱼 | `🇭🇰 香港` |

Shopee 只强制处理台湾站点，例如 `shopee.tw`。其他地区的 Shopee 域名不放进台湾规则组，避免把不同地区站点错误固定到台湾节点。

Typeless 单独成组，方便在 OpenClash 里设置香港优先、欧美兜底，或者后续单独观察延迟。

## 目录结构

```text
openclash-rules/
  config/
    sources.json              # 上游规则和本地补充规则配置
  rules/
    *.yaml                    # OpenClash 订阅的 rule-provider 文件
  generated/
    rule-providers.yaml       # 可复制进 OpenClash 覆写脚本的 rule-providers 片段
    custom-rules.list         # 可复制进 OpenClash 自定义规则的 rules 片段
  templates/
    proxy-groups.yaml         # 无订阅 token 的精简代理组模板
  scripts/
    build-rules.mjs           # 生成规则文件
  .github/workflows/
    update.yml                # GitHub Actions 自动更新
```

## 自动更新频率

`blackmatrix7/ios_rule_script` 近期自动更新多集中在北京时间凌晨 02:20 到 03:50 左右。

本仓库 GitHub Actions 目前每天运行两次：

- 北京时间 04:20：主更新，正常情况下会拉到当天上游更新。
- 北京时间 07:20：兜底更新，用来覆盖 GitHub Actions 延迟或上游当天稍晚更新的情况。

也可以在 GitHub 仓库的 Actions 页面手动运行 `更新 OpenClash 规则` workflow。

## 链路设计

这里分成两条链路：

1. GitHub Actions 在 GitHub 上更新本仓库规则时，直接访问原始 GitHub / raw.githubusercontent.com 链接。
2. 本地 OpenClash 从本仓库拉取最终规则文件时，使用已经部署好的 Xget 域名：

```text
https://gh.zhicong.cc
```

也就是说，`gh.zhicong.cc` 只用于本地 OpenClash 拉取本仓库产物，不用于 GitHub Actions 拉上游规则。

OpenClash 使用示例：

```text
https://gh.zhicong.cc/gh/stephenlzc/openclash-rules/raw/main/rules/ai-openai-twsg.yaml
```

GitHub Actions 上游下载仍使用原始地址，例如：

```text
https://github.com/blackmatrix7/ios_rule_script/raw/master/rule/Clash/OpenAI/OpenAI.yaml
```

## 本地生成

需要 Node.js 18 或更高版本。

```bash
npm run build
```

可选环境变量：

```bash
PUBLIC_BASE_URL=https://gh.zhicong.cc/gh/stephenlzc/openclash-rules/raw/main
```

`PUBLIC_BASE_URL` 用于生成 `generated/rule-providers.yaml` 中的规则文件 URL。推到 GitHub 后，GitHub Actions 会自动根据仓库名生成正确地址。

## 如何修改规则

以后只改一个入口文件：

```text
config/sources.json
```

不要直接修改 `rules/*.yaml`、`generated/rule-providers.yaml` 或 `generated/custom-rules.list`，这些都是生成物。

### 新增规则组

适用于新增一类明确要单独分流的服务，比如将来要新增一个 `shopping-us` 或 `dev-tools-hk`。

做法：

1. 在 `config/sources.json` 的 `groups` 中新增一项。
2. 设置 `id`、`description`、`policy`。
3. 如果有 `blackmatrix7/ios_rule_script` 的现成 YAML，就放到 `upstreams`。
4. 如果只是自己的补充域名，就放到 `rules`。
5. 把这个 `id` 加到 `ruleOrder` 中，位置越靠前优先级越高。
6. 运行 `npm run build`。

示例：

```json
{
  "id": "example-hk",
  "description": "示例服务，走香港",
  "policy": "🇭🇰 香港",
  "upstreams": [
    "https://github.com/blackmatrix7/ios_rule_script/raw/master/rule/Clash/Example/Example.yaml"
  ],
  "rules": [
    "DOMAIN-SUFFIX,example.com"
  ]
}
```

### 删除规则组

适用于以后不再需要某类单独分流。

做法：

1. 从 `groups` 中删除对应对象。
2. 从 `ruleOrder` 中删除对应 `id`。
3. 运行 `npm run build`。

### 修改规则组

适用于调整某一类服务走哪个策略组，或者补充一个漏网域名。

常见修改：

- 改策略组：修改对应组的 `policy`。
- 改上游规则：修改对应组的 `upstreams`。
- 补自定义域名：在对应组的 `rules` 中增加规则。
- 删除自定义域名：从对应组的 `rules` 中删掉规则。

自定义规则只用于补洞，不要把 blackmatrix7 已经维护的通用 `DOMAIN-SUFFIX` 列表复制到本仓库。

## 代理组模板

`templates/proxy-groups.yaml` 用于维护公开的精简代理组结构，不包含任何订阅地址或 token。

路由器本地脚本可以读取这个模板，并把 `__PROVIDER_NAMES__` 替换为本机实际的 3 个订阅 provider 名称。

敏感内容仍只放在路由器本地：

- 订阅 URL
- token
- OpenClash UCI 实际配置

## OpenClash 接入方式

推荐方式：

1. 把 `generated/rule-providers.yaml` 的内容通过 OpenClash 覆写脚本合并到最终配置。
2. 把 `generated/custom-rules.list` 里的规则放到 OpenClash 自定义规则中。
3. 确保这些规则在国内直连和最终 `MATCH` 前生效。

不要直接手改 `/etc/openclash/allinone.yaml`，因为订阅更新后会被覆盖。
