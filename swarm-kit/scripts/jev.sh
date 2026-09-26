#!/usr/bin/env bash
# jev.sh —— 蜂群收网前的 Jev 预审调用器（编排者的仪器，不是兵种）
#
# 用法:
#   JEV_API_KEY=... bash <插件根>/scripts/jev.sh <mission-dir> <card-id> <questions-file>
#   例: JEV_API_KEY=... bash scripts/jev.sh .swarm/20260925-orm选型 T03 /tmp/jev-T03.json
#
# 环境变量:
#   JEV_API_KEY   必需。未设置则直接降级退出（exit 1）
#   JEV_BASE_URL  默认 https://openrouter.ai/api/alpha   ← OpenRouter 中转（key 用 sk-or-...）
#   JEV_ENDPOINT  默认 /decisions                          ← 直连官方则为 api.typesafe.ai + /v1/systemone（需 TypeSafe 自己的 key）
#   JEV_MODE      shadow（默认，只记录不生效）/ active（按阈值分流）
#   JEV_TIMEOUT   秒，默认 5
#
# 行为:
#   成功 → 响应 JSON 原样打到 stdout，并向 <mission-dir>/decisions.jsonl 追加一行日志
#   失败（无 key / 超时 / HTTP 错误 / 响应非 JSON）→ 错误进 stderr，exit 1。
#   调用方（编排者）对 exit 1 的唯一正确处理：当作未预审，照常派 judge。
set -u

# 用户级配置文件（推荐把 key 放这里）：默认 ~/.swarm/jev.env，可用 JEV_ENV_FILE 改路径。
# 内容就是 shell 赋值，例如：
#   JEV_API_KEY=sk-...
#   # JEV_BASE_URL=https://api.typesafe.ai/v1
#   # JEV_MODE=shadow
# 注意：文件里的赋值会覆盖已继承的环境变量；临时换值请编辑文件，
# 或用 JEV_ENV_FILE 指向另一个文件。tr -d '\r' 兼容 Windows 编辑器保存的 CRLF。
ENV_FILE="${JEV_ENV_FILE:-$HOME/.swarm/jev.env}"
[ -f "$ENV_FILE" ] && . <(tr -d '\r' < "$ENV_FILE")

MISSION_DIR="${1:?usage: jev.sh <mission-dir> <card-id> <questions-file>}"
CARD="${2:?missing card-id}"
QFILE="${3:?missing questions-file}"

BASE_URL="${JEV_BASE_URL:-https://openrouter.ai/api/alpha}"
ENDPOINT="${JEV_ENDPOINT:-/decisions}"
MODE="${JEV_MODE:-shadow}"
TIMEOUT="${JEV_TIMEOUT:-5}"
LOG="$MISSION_DIR/decisions.jsonl"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '%s\n' "$1" >> "$LOG"; }

if [ -z "${JEV_API_KEY:-}" ]; then
  log "{\"ts\":\"$(ts)\",\"card\":\"$CARD\",\"mode\":\"$MODE\",\"error\":\"no_api_key\"}"
  echo "jev.sh: JEV_API_KEY 未设置，按未预审处理" >&2
  exit 1
fi

if [ ! -f "$QFILE" ]; then
  log "{\"ts\":\"$(ts)\",\"card\":\"$CARD\",\"mode\":\"$MODE\",\"error\":\"questions_file_missing\"}"
  echo "jev.sh: 找不到问题文件 $QFILE" >&2
  exit 1
fi

BODY="$(cat "$QFILE")"

RESP="$(curl -fsS --max-time "$TIMEOUT" \
  -H "Authorization: Bearer $JEV_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST "$BASE_URL$ENDPOINT" \
  --data-binary "$BODY" 2>&1)" || {
  log "{\"ts\":\"$(ts)\",\"card\":\"$CARD\",\"mode\":\"$MODE\",\"error\":\"request_failed\"}"
  echo "jev.sh: 请求失败（$RESP），按未预审处理" >&2
  exit 1
}

# 响应是 JSON 对象/数组才原样嵌入日志（去掉换行/压缩空白对合法 JSON 是安全的）；
# 否则视为异常响应，按错误处理。
case "$RESP" in
  '{'*|'['*)
    COMPACT="$(printf '%s' "$RESP" | tr -d '\n' | tr -s ' ')"
    log "{\"ts\":\"$(ts)\",\"card\":\"$CARD\",\"mode\":\"$MODE\",\"response\":$COMPACT}"
    ;;
  *)
    ESC="$(printf '%s' "$RESP" | tr -d '\n' | sed 's/"/\\"/g' | cut -c1-500)"
    log "{\"ts\":\"$(ts)\",\"card\":\"$CARD\",\"mode\":\"$MODE\",\"error\":\"non_json\",\"response\":\"$ESC\"}"
    echo "jev.sh: 响应非 JSON，按未预审处理" >&2
    exit 1
    ;;
esac

printf '%s\n' "$RESP"
