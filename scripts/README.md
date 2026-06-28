# 脚本

## `build-rules.mjs`

负责：

1. 从 `config/sources.json` 读取规则配置。
2. 直接从原始 GitHub / raw.githubusercontent.com 地址下载上游规则。
3. 解析 Clash classical `payload`。
4. 合并本地补充规则。
5. 去重、排序并输出到 `rules/`。
6. 生成 `generated/rule-providers.yaml` 和 `generated/custom-rules.list`。

注意：`gh.zhicong.cc` 只用于本地 OpenClash 拉取本仓库生成的最终规则文件，不用于 GitHub Actions 拉取上游规则。
