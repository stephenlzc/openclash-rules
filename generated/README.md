# 生成片段

这里存放给 OpenClash 使用的生成片段。

## `rule-providers.yaml`

用于注入 Mihomo/OpenClash 的 `rule-providers`。

## `custom-rules.list`

用于注入 OpenClash 的 `rules`。

注意：这些片段是辅助文件，不建议手工编辑。需要修改规则时，请改 `config/sources.json`，然后运行：

```bash
npm run build
```

