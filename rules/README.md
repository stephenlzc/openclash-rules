# 规则文件

这里存放 OpenClash / Mihomo 可直接作为 `rule-providers` 使用的规则文件。

这些文件由 `scripts/build-rules.mjs` 生成：

- `ai-openai-twsg.yaml`：OpenAI、ChatGPT、Codex 主要来自 `blackmatrix7/ios_rule_script`，目标 `🌏 台湾/新加坡 AI`。
- `usa-ai.yaml`：Claude、Anthropic、Gemini、Copilot 来自 `blackmatrix7/ios_rule_script`；Grok、NotebookLM、Perplexity 使用个人补充规则，目标 `🇺🇸 美国 AI`。
- `typeless.yaml`：Typeless，目标 `📝 Typeless`。
- `google-hk.yaml`：Google 主体来自 `blackmatrix7/ios_rule_script`，目标香港。
- `youtube-hk.yaml`：YouTube 来自 `blackmatrix7/ios_rule_script`，目标香港。
- `github-hk.yaml`：GitHub 来自 `blackmatrix7/ios_rule_script`，另补充少量日志里见过的域名，目标香港。
- `x-twitter-hk.yaml`：X / Twitter 来自 `blackmatrix7/ios_rule_script`，目标香港，不单独创建可见策略组。
- `taiwan-shopee.yaml`：只包含 Shopee 台湾的个人补充规则，目标 `🛒 台湾 Shopee`；其他地区 Shopee 不强制放入台湾规则组。
- `media-hk.yaml`：流媒体规则来自 `blackmatrix7/ios_rule_script`，目标 `🇭🇰 香港`。
- `western-news.yaml`：欧美新闻和各国网站，AFP / BBC / NYTimes 来自 `blackmatrix7/ios_rule_script`，AP / WSJ / Reuters / The Times 等使用个人补充规则，目标 `🇺🇸🇨🇦🇪🇺🇬🇧 欧美地区`。
- `direct-cn.yaml`：补充直连规则。

除个人补洞外，不在本仓库手写或长期维护通用 `DOMAIN-SUFFIX` 列表。

文件格式为 Mihomo classical rule-provider：

```yaml
payload:
  - DOMAIN-SUFFIX,example.com
```
