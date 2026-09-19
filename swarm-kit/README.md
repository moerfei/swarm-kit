# Swarm Kit（蜂群工具箱）

把 2024–2026 多代理蜂群研究的核心结论，落到 ZCode 现有原语（并行子代理、后台代理、SendMessage、文件系统）上的可复用插件。

## 设计理念

| 理论 | 出处 | 在本插件的落地 |
|---|---|---|
| 编排者-工人 | [Anthropic 多代理研究系统](https://www.anthropic.com/engineering/multi-agent-research-system)（比单代理强 90.2%，token ≈15×） | L1–L4 分级、预算红线、并行 fan-out |
| Routines + Handoffs | [OpenAI Swarm](https://github.com/openai/swarm) / [Agents SDK](https://openai.github.io/openai-agents-python/handoffs/) | agent 定义 = 例程；SendMessage+resume ≈ 移交 |
| 采样-投票 | [More Agents Is All You Need](https://arxiv.org/abs/2402.05120) | L4 高风险交付派多只 judge 独立投票 |
| 可优化图 | [GPTSwarm (ICML 2024)](https://arxiv.org/abs/2402.16823) | swarm-retro：改提示词（节点）/改路由（边） |
| A2A 不透明协作 | [A2A Project](https://github.com/a2aproject/a2a) | 蜂巢黑板：代理间只经任务卡/回执交换信息 |

## 三种兵种

| 代理 | 权限 | 职责 |
|---|---|---|
| `scout` 侦察蜂 | 只读（Read/Bash/WebSearch/WebFetch） | 并行调研、定位、取证，产出带证据的回执 |
| `worker` 工蜂 | 可写（仅限任务卡所有权清单） | 按卡施工，写者唯一，防并行写冲突 |
| `judge` 评审蜂 | 只读 | 逐条验收 pass/fail；投票出 JSON 裁决 |

## 蜂巢黑板协议

```
.swarm/<mission-id>/
├── mission.md              # 目标/约束/成功标准（编排者写）
├── STATUS.md               # 看板：卡 | 兵种 | 状态 | 一句话
├── tasks/T01-<slug>.md     # 任务卡：范围 / 文件所有权 / 完成标准 / 交付路径
└── results/T01.md          # 回执：结论 / 证据 / 改动清单 / 未决问题
```

## 使用

- `/swarm <任务>` —— 唯一入口：自动分级（L1 不组群；L2 工蜂并行；L3 侦察蜂 fan-out；L4 施工+投票）。
- 也可直接点名兵种：让主会话把子任务派给 `swarm-kit:scout` / `swarm-kit:worker` / `swarm-kit:judge`。
- 任务结束后运行蜂群复盘（`swarm-retro` 技能），把失败模式变成对蜂群自身的最小修改。

示例：

```
/swarm 并行调研 Drizzle/Prisma/Kysely 三个 ORM 在我们项目里的适配性，给出选型结论
/swarm 把 src/utils 下 5 个互不依赖的模块迁移到 TypeScript
/swarm 准备发版：实现迁移脚本后派 3 只评审蜂投票验收
```

## 边界

ZCode 的代理协作是星型（编排者居中）而非网状：代理之间不能自主互发消息、不能任务中途移交控制权。本插件用 SendMessage+resume 做近似，其余全部用显式编排补齐——这是当前平台的边界，也是设计取舍。

## 安装/重载

个人插件位于 `~/plugins/swarm-kit`，已在 `~/.agents/plugins/marketplace.json`（personal marketplace）登记。修改插件文件后，走 marketplace 的 cachebuster 重装流程（或在插件管理界面重载）生效。
