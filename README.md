# swarm-kit（蜂群工具箱）

Swarm orchestration plugin for ZCode — and a Claude Code compatible plugin marketplace.

把 ZCode 的并行子代理原语整理成有纪律的蜂群：侦察蜂（只读调研）/ 工蜂（按文件所有权施工）/ 评审蜂（验收投票），配 `.swarm/` 黑板协议与 L1–L4 分级编排手册。设计依据与理论出处见 `swarm-kit/skills/swarm-lead/references/patterns.md`。

## Install — ZCode（其他机器）

插件市场 → 添加市场 → 输入本仓库（`moerfei/swarm-kit` 或完整 git URL）→ 安装 `swarm-kit`。重启后可用 `/swarm <任务>` 与 `swarm-kit:scout / worker / judge` 三种子代理。

## Install — Claude Code

```
claude plugin marketplace add moerfei/swarm-kit
# 然后在会话中安装 swarm-kit 插件
```

## Manual

Clone this repo and copy `swarm-kit/` into your client's plugins directory.

## Layout

- `icon.png` — plugin icon（保持仓库根路径，raw 直链已写入本机清单）
- `swarm-kit/` — the plugin（含 `.zcode-plugin` / `.claude-plugin` / `.codex-plugin` 三套清单）
- `marketplace.json` 与 `.claude-plugin/marketplace.json` — 同内容双格式市场清单
