# OpenClash 脱敏配置备份

这是从家庭软路由 `192.168.31.132` 导出的 OpenClash 相关配置快照，已经脱敏，适合放在 GitHub 仓库中用于审计、对比和恢复配置结构。

## 包含内容

- `config/allinone.sanitized.yaml`：当前 OpenClash 运行配置的脱敏版本。
- `custom/`：本地 OpenClash 自定义脚本、代理组模板和自定义规则的脱敏版本。
- `etc-config/`：`/etc/config/openclash`、`network`、`dhcp`、`firewall` 的脱敏版本。
- `manifest.json`：生成时间、来源和脱敏说明。

## 已脱敏或省略

- 订阅 URL、token、password、secret、uuid 等敏感字段已替换为 `REDACTED` 或 `https://redacted.invalid/subscription`。
- 节点明文配置、`proxy_provider/`、历史数据库、GeoIP/GeoSite 数据库、旧备份目录没有纳入仓库。
- 此备份不可直接还原到路由器；如果要还原，需要重新填入本地订阅和 secret。

## 用途

- 记录当前 OpenClash 规则、策略组、DNS 和 IPv6 禁用状态。
- 后续排障时对比配置变化。
- 作为公开仓库中的结构化配置参考。
