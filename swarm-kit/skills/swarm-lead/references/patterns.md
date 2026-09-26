# 理论 → ZCode 落地映射（含出处）

| # | 理论/实践 | 核心结论 | 在本插件的落地 |
|---|---|---|---|
| 1 | 编排者-工人（Anthropic 多代理研究系统, 2025） | 多代理比单代理强 90.2%，但 token ≈15×；努力随复杂度分级；3–5 个子任务；并行独立上下文；提示词微调影响巨大 | L1–L4 分级表；任务卡 2–5 张；同消息并行派发；预算红线 |
| 2 | Routines + Handoffs（OpenAI Swarm → Agents SDK） | 例程 = 指令 + 工具；移交 = 控制权转移；agents-as-tools 范式下编排者保留控制权 | `agents/*.md` 即例程；`SendMessage` + resume 是移交的近似；编排者始终保留控制权 |
| 3 | 采样-投票（More Agents Is All You Need, 2024） | 同题多采样取多数即可提升，收益递减、与任务难度正相关 | L4 的 2–3 只 judge 独立投票，多数通过才收网 |
| 4 | 可优化图（GPTSwarm, ICML 2024） | 节点优化（改提示词）+ 边优化（改连接路由）= 蜂群自改进 | `swarm-retro`：节点 = `agents/*.md` 提示词，边 = swarm-lead 的分级与路由规则 |
| 5 | A2A 协议（Google → Linux Foundation, 2025） | 对等、不透明的代理间协作；MCP 管 agent→工具，A2A 管代理↔代理 | 蜂巢黑板：只经任务卡/回执交换信息，互不读对方内部过程 |
| 6 | 涌现协调研究（2025–2026） | 自组织与涌现尚在研究期，工程上仍以显式编排为主 | 本插件全部采用显式编排，不引入自发认领任务 |
| 7 | System 1/System 2 分层（Kahneman 双系统；Jev, TypeSafe AI 2026） | 微决策（分流/判类/路由）交给廉价的校准决策层，LLM 专注开放推理；校准声明未经第三方验证 | 收网前 Jev 预审（`jev.md`）：Jev 是编排者的仪器而非兵种，默认影子模式 |

## 实践告诫（来自生产反馈）

- **编排开销**：分解与汇总的额外 LLM 调用在规模变大时可能超过工人本身的成本——所以 L1 不组群、任务卡上限 5 张。
- **状态可变并行的写冲突**：多个代理同时写文件是一致性的最大风险——所以任务卡强制"文件所有权，写者唯一"。
- **调试困难**：并行代理的失败难以复现——所以每张卡必有回执，STATUS.md 是唯一事实来源。
- **决策层校准风险**：Jev 类决策模型的置信度未经第三方验证——所以预审默认影子模式（只记录不生效），阈值用 decisions.jsonl 的实测吻合度校准后再放开（`jev.md`）。

## 来源

- Anthropic, "How we built our multi-agent research system" — https://www.anthropic.com/engineering/multi-agent-research-system
- OpenAI Swarm — https://github.com/openai/swarm ；OpenAI Agents SDK: Handoffs — https://openai.github.io/openai-agents-python/handoffs/
- Li et al., "More Agents Is All You Need" — https://arxiv.org/abs/2402.05120
- Zhuge et al., "GPTSwarm: Language Agents as Optimizable Graphs" — https://arxiv.org/abs/2402.16823
- A2A Project (Linux Foundation) — https://github.com/a2aproject/a2a
- Jimenez-Romero et al., "Multi-agent systems powered by large language models" — https://arxiv.org/abs/2503.03800
