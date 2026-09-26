# Jev 预审分流（收网前的置信度闸门）

把 Jev（TypeSafe AI, 2026-09 发布的"System One"决策模型）接进蜂群：**收 judge 之前**，对每份回执做一次廉价的置信度判断，明显合格/明显缺项的免派评审蜂，judge 的新鲜上下文只花在灰区上。

## 1. 定位：仪器，不是兵种

- Jev 无上下文、无工具、不写黑板——它只对**编排者序列化给它的文本**负责。
- 它能判"回执是否逐条回应了完成标准、证据是否带 file:line、范围是否越界"；它**不能**读文件、跑命令——"代码真的能编译"仍是 judge（Read/Bash）的领地。**它是分流器，不是替代品。**
- 三兵种定义不变；调用只发生在编排者手里。

## 2. 何时用 / 何时禁用

| 场景 | 用法 |
|---|---|
| L2/L3 收 judge 前的回执预审 | 完成标准逐条 → Noul；综合处置 → Choice |
| L3 侦察回执去重 | 证据两两配对 → Noul（是否同一发现），压缩汇总材料 |
| L3 结论矛盾检测 | 结论配对 → Noul，矛盾的才升级 judge 投票 |
| 失败预案"答非所问"判断 | Noul，确认后再 resume，避免浪费一次完整 resume |

**禁用**：L4 最终投票门（多数投票是 L4 的全部意义，永不 auto-pass）；任何需要读文件/跑命令的事实验证；生成类任务（Jev 不产文字）。

## 3. 调用方式

脚本在本插件根目录 `scripts/jev.sh`（本文件向上三级）。问题文件是完整的 Jev 请求体（state + questions），临时文件放哪都行：

```bash
JEV_API_KEY=... bash <插件根>/scripts/jev.sh .swarm/<mission-id> T03 /tmp/jev-T03.json
```

**API key 配置（三种方式，推荐第一种）**：

1. **配置文件 `~/.swarm/jev.env`**（脚本自动读取，兼容 CRLF）：
   ```bash
   mkdir -p ~/.swarm && printf 'JEV_API_KEY=你的key\n' > ~/.swarm/jev.env
   ```
   也可在文件里放 `JEV_BASE_URL` / `JEV_MODE` 等默认值。**注意：文件里的赋值会覆盖继承的环境变量**——临时换值用 `JEV_ENV_FILE=别的文件` 指过去。key 放这里不会出现在蜂巢目录或会话记录里。
2. 单次调用前缀：`JEV_API_KEY=... bash scripts/jev.sh ...`。
3. 全局环境变量：`~/.bashrc` 里 `export`（ZCode 的 Bash 工具每次从 profile 初始化，下次调用即生效），或 Windows 用户变量 `setx JEV_API_KEY "..."`（需重启 ZCode 才被继承）。

**接入路线（2026-09 实测验证）**：默认走 OpenRouter 中转——`https://openrouter.ai/api/alpha/decisions`，key 用 OpenRouter 的 `sk-or-...`；也可直连官方 `https://api.typesafe.ai/v1/systemone`（需 TypeSafe 自己的 key，完整规范见 https://api.typesafe.ai/openapi.json）。切换只需在 jev.env 里改 `JEV_BASE_URL` / `JEV_ENDPOINT`。

回执预审的问题文件示例（**state 只放回执全文 + 完成标准，不放会话上下文、不放下游产物全文**——序列化克制，控制输入成本）：

```json
{
  "model": "jev-latest",
  "state": "任务卡 T03 完成标准：\n1) 迁移后 tsc --noEmit 零错误\n2) 不改动 src/utils 之外文件\n\n回执全文：\n# T03 回执\n结论：...\n证据：\n- src/utils/format.ts:1 — ...",
  "questions": {
    "c1": {"type": "noul", "instructions": "回执是否为完成标准1给出了具体证据（命令输出或 file:line）？"},
    "c2": {"type": "noul", "instructions": "改动清单是否表明仅涉及 src/utils 内文件？"},
    "dispose": {"type": "choice", "instructions": "综合以上各条，这份回执应如何处置？",
      "criteria": {"auto-pass": "全部标准有据可查", "auto-fail": "明显缺项", "judge": "证据不全需人工复核"}}
  }
}
```

三种原语：`noul`（yes/no 概率）、`choice`（选项概率）、`score`（有序等级）。**questions 是命名对象**（名字自取，响应靠名字对答案），`model` 必填（`jev-latest` 别名即可）。实测响应结构：

```json
{"model": "typesafe/jev-1.13-20260917",
 "answers": {"c1": {"type": "noul", "noul": 0.67},
             "dispose": {"type": "choice", "choice": "judge", "probabilities": {"auto-pass": 0.2, "judge": 0.44, "auto-fail": 0.36}, "confidence": 0.16}},
 "usage": {"input_tokens": 607, "cost": 0.000025494}}
```

分流阈值读 `answers.<名>.noul`；dispose 的 choice 结果仅作交叉参考，**分流由 Noul 阈值决定**。

## 4. 分流规则（仅 active 模式执行）

| 条件 | 动作 | STATUS 记法 |
|---|---|---|
| 全部完成标准 p ≥ 0.97 | auto-pass，免派 judge | `done(auto-pass,jev)` |
| 任一完成标准 p ≤ 0.30 | auto-fail，带未达标项 SendMessage 退回工蜂 | `rework(auto-fail,jev)` |
| 灰区（0.30 – 0.97） | 照常派 judge | 不变 |

派出的 judge 裁决后，若该卡有过预审，回填一行供校准：

```bash
printf '%s\n' '{"card":"T03","judge_outcome":"pass"}' >> .swarm/<mission-id>/decisions.jsonl
```

## 5. 模式与校准（先影子，后放开）

- **shadow（默认）**：预审照跑、decisions.jsonl 照记，但**一律照常派 judge**——分流建议不生效。
- **切 active 的条件**（由 swarm-retro 依据 decisions.jsonl 判定，用户确认）：
  - 影子期 ≥ 3 个任务且 ≥ 20 次预审调用；
  - 开 auto-pass：分流建议 auto-pass 的卡，judge 驳回率为 0；
  - 开 auto-fail：分流建议 auto-fail 的卡，judge 实际判 pass 的比例 < 5%（误杀率）。
- 切换方式：调用时 `JEV_MODE=active`，并在 mission.md 预算段注明 `jev: active`。
- 观测指标：灰区占比长期 > 80% 说明阈值过窄或完成标准措辞含糊——优先改任务卡，不是放宽阈值。

## 6. 降级纪律（硬规则）

- 脚本 exit ≠ 0（无 key / 超时 / HTTP 错误 / 响应异常）→ **当作未预审，照常派 judge**，最多重试一次。
- 预审是纯优化，不是正确性依赖：任何情况下 Jev 的缺失不能阻塞收网。
- Jev 不是访问控制层：阈值闸门不承担安全/授权职责，那归代码与编排者。
