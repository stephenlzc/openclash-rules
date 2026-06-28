import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const checkMode = process.argv.includes("--check");

const configPath = resolve(root, "config/sources.json");
const config = JSON.parse(await readFile(configPath, "utf8"));

const repoFullName = process.env.GITHUB_REPOSITORY || "stephenlzc/openclash-rules";
const openclashPullBase =
  process.env.OPENCLASH_PULL_BASE || config.openclashPullBase || "https://gh.zhicong.cc";
const publicBaseUrl =
  process.env.PUBLIC_BASE_URL ||
  `${openclashPullBase.replace(/\/$/, "")}/gh/${repoFullName}/raw/main`;

const rulesDir = resolve(root, "rules");
const generatedDir = resolve(root, "generated");

await mkdir(rulesDir, { recursive: true });
await mkdir(generatedDir, { recursive: true });

function parseClassicalRules(text) {
  const rules = [];
  let inPayload = false;

  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    if (line === "payload:" || line.startsWith("payload:")) {
      inPayload = true;
      continue;
    }

    if (inPayload) {
      if (!line.startsWith("-")) continue;
      const value = line.replace(/^-\s*/, "").replace(/^['"]|['"]$/g, "").trim();
      if (value) rules.push(value);
      continue;
    }

    if (/^(DOMAIN|DOMAIN-SUFFIX|DOMAIN-KEYWORD|DOMAIN-REGEX|IP-CIDR|IP-CIDR6|GEOIP|GEOSITE|PROCESS-NAME|DST-PORT),/.test(line)) {
      rules.push(line.replace(/^-\s*/, ""));
    }
  }

  return rules;
}

async function fetchText(url) {
  const response = await fetch(url, {
    headers: {
      "user-agent": "openclash-rules-updater/0.1"
    }
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} while fetching ${url}`);
  }
  return response.text();
}

function uniqueSorted(rules) {
  return [...new Set(rules.map((rule) => rule.trim()).filter(Boolean))].sort((a, b) =>
    a.localeCompare(b, "en")
  );
}

function yamlRuleProvider(rules, description) {
  const header = [
    "# 此文件由 scripts/build-rules.mjs 自动生成，请勿手工编辑。",
    `# ${description}`,
    "payload:"
  ];
  const body = rules.map((rule) => `  - ${JSON.stringify(rule)}`);
  return `${header.concat(body).join("\n")}\n`;
}

function providerName(id) {
  return id
    .split("-")
    .map((part) => part.toUpperCase())
    .join("_");
}

const builtGroups = [];

for (const group of config.groups) {
  const collected = [...(group.rules || [])];
  const errors = [];

  for (const upstream of group.upstreams || []) {
    try {
      const text = await fetchText(upstream);
      collected.push(...parseClassicalRules(text));
    } catch (error) {
      errors.push(`${upstream}: ${error.message}`);
    }
  }

  const rules = uniqueSorted(collected);
  const output = yamlRuleProvider(rules, group.description || group.id);
  const filePath = resolve(rulesDir, `${group.id}.yaml`);
  await writeFile(filePath, output);

  builtGroups.push({
    ...group,
    provider: providerName(group.id),
    fileName: `${group.id}.yaml`,
    count: rules.length,
    errors
  });
}

const providerLines = ["# 此文件由 scripts/build-rules.mjs 自动生成。", "rule-providers:"];
for (const group of builtGroups) {
  providerLines.push(`  ${group.provider}:`);
  providerLines.push("    type: http");
  providerLines.push("    behavior: classical");
  providerLines.push(`    url: ${publicBaseUrl.replace(/\/$/, "")}/rules/${group.fileName}`);
  providerLines.push(`    path: ./rule_provider/${group.fileName}`);
  providerLines.push(`    interval: ${group.interval || config.defaultInterval || 86400}`);
}
await writeFile(resolve(generatedDir, "rule-providers.yaml"), `${providerLines.join("\n")}\n`);

const byId = new Map(builtGroups.map((group) => [group.id, group]));
const ruleLines = ["# 此文件由 scripts/build-rules.mjs 自动生成。", "rules:"];
for (const id of config.ruleOrder || builtGroups.map((group) => group.id)) {
  const group = byId.get(id);
  if (!group) continue;
  ruleLines.push(`  - RULE-SET,${group.provider},${group.policy}`);
}
for (const rule of config.builtinRules || []) {
  ruleLines.push(`  - ${rule}`);
}
await writeFile(resolve(generatedDir, "custom-rules.list"), `${ruleLines.join("\n")}\n`);

const summary = {
  publicBaseUrl,
  groups: builtGroups.map((group) => ({
    id: group.id,
    provider: group.provider,
    policy: group.policy,
    count: group.count,
    errors: group.errors
  }))
};

await writeFile(resolve(generatedDir, "summary.json"), `${JSON.stringify(summary, null, 2)}\n`);

const hasErrors = builtGroups.some((group) => group.errors.length > 0);
console.log(JSON.stringify(summary, null, 2));
if (checkMode && hasErrors) {
  process.exitCode = 1;
}
