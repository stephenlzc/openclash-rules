#!/bin/sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_OUT "Tip: Start Running Custom OpenClash Rules Overwrite..."
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/openclash.log"
CONFIG_FILE="$1"
TEMPLATE_FILE="${OPENCLASH_PROXY_GROUPS_TEMPLATE:-/etc/openclash/custom/proxy-groups.local.yaml}"

ruby -ryaml -E UTF-8 -e '
config_file = ARGV[0]
template_file = ARGV[1]
value = YAML.load_file(config_file, aliases: true)

value["ipv6"] = false
value["dns"] ||= {}
value["dns"]["ipv6"] = false

keep_provider_urls = [
  "https://redacted.invalid/subscription/hongxingyun",
  "https://redacted.invalid/subscription/gwshudong",
  "https://redacted.invalid/subscription/uuone"
]

provider_names_by_url = {
  "https://redacted.invalid/subscription/hongxingyun" => "红杏云",
  "https://redacted.invalid/subscription/gwshudong" => "GW树洞",
  "https://redacted.invalid/subscription/uuone" => "UUone"
}

providers = value["proxy-providers"] || {}
kept_providers = {}
providers.each do |_name, provider|
  friendly_name = provider_names_by_url[provider["url"].to_s]
  kept_providers[friendly_name] = provider if friendly_name
end
kept_provider_names = provider_names_by_url.values.select { |name| kept_providers.key?(name) }

value["proxy-providers"] = kept_provider_names.to_h { |name| [name, kept_providers[name]] }

raise "proxy group template not found: #{template_file}" unless File.exist?(template_file)

template = YAML.load_file(template_file, aliases: true)
template_groups = template["proxy-groups"] || []
raise "proxy group template has no proxy-groups: #{template_file}" if template_groups.empty?

if kept_provider_names.empty?
  raise "none of the expected subscription providers were found in proxy-providers"
end

template_groups.each do |group|
  group["use"] = kept_provider_names if group["use"].is_a?(Array)
end
value["proxy-groups"] = template_groups

base = "https://gh.zhicong.cc/gh/stephenlzc/openclash-rules/raw/main/rules"
rule_providers = value["rule-providers"] || {}
custom_rule_providers = {
  "AI_OPENAI_TWSG" => "ai-openai-twsg.yaml",
  "USA_AI" => "usa-ai.yaml",
  "TYPELESS" => "typeless.yaml",
  "GOOGLE_HK" => "google-hk.yaml",
  "YOUTUBE_HK" => "youtube-hk.yaml",
  "GITHUB_HK" => "github-hk.yaml",
  "X_TWITTER_HK" => "x-twitter-hk.yaml",
  "TAIWAN_SHOPEE" => "taiwan-shopee.yaml",
  "MEDIA_HK" => "media-hk.yaml",
  "WESTERN_NEWS" => "western-news.yaml",
  "OKX_WESTERN" => "okx-western.yaml",
  "DIRECT_CN" => "direct-cn.yaml"
}
custom_rule_providers.each do |name, file|
  rule_providers[name] = {
    "type" => "http",
    "behavior" => "classical",
    "url" => "#{base}/#{file}",
    "path" => "./rule_provider/#{file}",
    "interval" => 86400
  }
end
value["rule-providers"] = rule_providers

custom_rules = [
  "RULE-SET,DIRECT_CN,🎯 全球直连",
  "RULE-SET,AI_OPENAI_TWSG,🌏 台湾/新加坡 AI",
  "RULE-SET,USA_AI,🇺🇸 美国 AI",
  "RULE-SET,TYPELESS,📝 Typeless",
  "RULE-SET,YOUTUBE_HK,🇭🇰 香港",
  "RULE-SET,GOOGLE_HK,🇭🇰 香港",
  "RULE-SET,GITHUB_HK,🇭🇰 香港",
  "RULE-SET,X_TWITTER_HK,🇭🇰 香港",
  "RULE-SET,TAIWAN_SHOPEE,🛒 台湾 Shopee",
  "RULE-SET,MEDIA_HK,🇭🇰 香港",
  "RULE-SET,WESTERN_NEWS,🇺🇸🇨🇦🇪🇺🇬🇧 欧美地区",
  "RULE-SET,OKX_WESTERN,🇺🇸🇨🇦🇪🇺🇬🇧 欧美地区"
]
direct_rules = (value["rules"] || []).select do |rule|
  parts = rule.to_s.split(",")
  target = parts[-1]
  target == "🎯 全球直连" || target == "DIRECT" || rule.to_s.include?(",🎯 全球直连,")
end
direct_rules.reject! { |rule| rule.to_s.start_with?("MATCH,") }
direct_rules.reject! { |rule| custom_rule_providers.key?(rule.to_s.split(",")[1].to_s) }

base_rules = [
  "GEOSITE,private,🎯 全球直连",
  "GEOIP,private,🎯 全球直连,no-resolve",
  "GEOSITE,cn,🎯 全球直连",
  "GEOIP,cn,🎯 全球直连,no-resolve"
]

value["rules"] = (custom_rules + direct_rules + base_rules).uniq + ["MATCH,🇭🇰 香港"]

File.open(config_file, "w") { |f| YAML.dump(value, f) }
' "$CONFIG_FILE" "$TEMPLATE_FILE" 2>> "$LOG_FILE"

exit 0
