#!/usr/bin/env bash
# ハーネスカタログの正本 — 候補 CLI の疎通確認（probe）とモデル一覧（models）。
# ハーネスの実行は TUI ペイン起用（SKILL.md ＋ transports/<CLI名>-tui.md）のみで
# 行い、本スクリプトは実行を担わない。
#
# 使い方:
#   catalog.sh probe
#       候補 CLI ごとに「名前<TAB>ok|excluded<TAB>詳細」を1行ずつ出力する。
#       ok の詳細にはモデル一覧等の補足を含める。
#   catalog.sh models <cli>
#       当該 CLI の指定可能モデルを1行1件で出力する（--model 検証の正本）。
#       取得できない場合は理由を stderr に出して非0で終了する。
#
# 新しい CLI の追加: models_<名前> と probe_<名前> を書いて probe の呼び出し列と
# models のディスパッチに分岐を足す。起用には対話 TUI の実測検証と
# transports/<CLI名>-tui.md の作成も必要（SKILL.md のカタログ規定）。

set -u -o pipefail

TIMEOUT_BIN=$(command -v gtimeout || command -v timeout) || {
  echo "timeout 未導入 (macOS は brew install coreutils)" >&2
  exit 127
}

# --- モデル一覧（1行1件。取得不可は理由を stderr に出して非0終了） ---

models_codex() {
  command -v codex >/dev/null 2>&1 || { echo "codex 未導入" >&2; return 1; }
  command -v jq >/dev/null 2>&1 || { echo "jq 未導入のためモデル一覧を取得できない" >&2; return 1; }
  "$TIMEOUT_BIN" 60 codex debug models 2>/dev/null \
    | jq -r '.models[] | select(.visibility == "list") | .slug'
}

models_cursor_agent() {
  command -v cursor-agent >/dev/null 2>&1 || { echo "cursor-agent 未導入" >&2; return 1; }
  local out parsed
  out=$("$TIMEOUT_BIN" 60 cursor-agent --list-models 2>&1) \
    || { echo "疎通失敗: $(printf '%s' "$out" | head -n1)" >&2; return 1; }
  printf '%s' "$out" | grep -q 'No models available' \
    && { echo "認証切れ（cursor-agent login が必要）" >&2; return 1; }
  parsed=$(printf '%s\n' "$out" | grep -E '^[A-Za-z0-9][A-Za-z0-9._-]* - ' | cut -d' ' -f1)
  [ -n "$parsed" ] || { echo "モデル一覧の解析に失敗（cursor-agent --list-models の出力形式変更の可能性）" >&2; return 1; }
  printf '%s\n' "$parsed"
}

models_agy() {
  command -v agy >/dev/null 2>&1 || { echo "agy 未導入" >&2; return 1; }
  local out parsed
  out=$("$TIMEOUT_BIN" 60 agy models 2>&1)
  if [ $? -ne 0 ] || [ -z "$out" ]; then
    echo "$(printf '%s' "$out" | grep -im1 'error' || echo '疎通失敗')" >&2
    return 1
  fi
  # 出力は「slug のみ」（旧形式）と「slug<TAB>表示名」（新形式）のいずれもありうる。
  # タブ区切りの第1フィールドを共通の抽出対象にする（旧形式は行全体がそのまま第1
  # フィールドになるため同じ規則で通る）。見出し行（"Fetching available models..."
  # 等）は空白を含み regex にマッチしないため自然に落ちる。
  parsed=$(printf '%s\n' "$out" | awk -F'\t' '$1 ~ /^[A-Za-z0-9][A-Za-z0-9._-]+$/ {print $1}')
  [ -n "$parsed" ] || { echo "モデル一覧の解析に失敗（agy models の出力形式変更の可能性）" >&2; return 1; }
  printf '%s\n' "$parsed"
}

models_grok() {
  command -v grok >/dev/null 2>&1 || { echo "grok 未導入" >&2; return 1; }
  local out parsed
  out=$("$TIMEOUT_BIN" 60 grok models 2>&1) \
    || { echo "$(printf '%s' "$out" | grep -im1 'error\|log' || echo '疎通失敗')" >&2; return 1; }
  parsed=$(printf '%s\n' "$out" | grep -E '^\s+\*' | awk '{print $2}')
  [ -n "$parsed" ] || { echo "モデル一覧の解析に失敗（grok models の出力形式変更の可能性）" >&2; return 1; }
  printf '%s\n' "$parsed"
}

# --- 疎通確認（probe の1行は models_* の成否と CLI 固有の注記から組み立てる） ---

join_lines() { paste -sd, -; }

probe_codex() {
  command -v codex >/dev/null 2>&1 || { printf 'codex\texcluded\t未導入\n'; return; }
  "$TIMEOUT_BIN" 60 codex login status >/dev/null 2>&1 \
    || { printf 'codex\texcluded\t認証切れ（codex login が必要）\n'; return; }
  local note='reasoning effort は <slug>@<effort> 形で指定'
  local out
  if out=$(models_codex 2>&1); then
    printf 'codex\tok\tmodels: %s ／ %s\n' "$(printf '%s\n' "$out" | join_lines)" "$note"
  else
    printf 'codex\tok\tmodels: 一覧取得不可（%s）— --model は検証なしで透過 ／ %s\n' \
      "$(printf '%s' "$out" | head -n1)" "$note"
  fi
}

probe_cursor_agent() {
  command -v cursor-agent >/dev/null 2>&1 || { printf 'cursor-agent\texcluded\t未導入\n'; return; }
  local out
  if out=$(models_cursor_agent 2>&1); then
    printf 'cursor-agent\tok\tmodels: %s\n' "$(printf '%s\n' "$out" | join_lines)"
  else
    printf 'cursor-agent\texcluded\t%s\n' "$(printf '%s' "$out" | head -n1 | cut -c1-160)"
  fi
}

probe_agy() {
  command -v agy >/dev/null 2>&1 || { printf 'agy\texcluded\t未導入\n'; return; }
  local out
  if out=$(models_agy 2>&1); then
    printf 'agy\tok\tmodels: %s\n' "$(printf '%s\n' "$out" | join_lines)"
  else
    printf 'agy\texcluded\t%s\n' "$(printf '%s' "$out" | head -n1 | cut -c1-160)"
  fi
}

probe_grok() {
  command -v grok >/dev/null 2>&1 || { printf 'grok\texcluded\t未導入\n'; return; }
  local out
  if out=$(models_grok 2>&1); then
    printf 'grok\tok\tmodels: %s\n' "$(printf '%s\n' "$out" | join_lines)"
  else
    printf 'grok\texcluded\t%s\n' "$(printf '%s' "$out" | head -n1 | cut -c1-160)"
  fi
}

case "${1:-}" in
  probe)
    probe_codex
    probe_cursor_agent
    probe_agy
    probe_grok
    ;;
  models)
    [ $# -eq 2 ] || { echo "usage: catalog.sh models <cli>" >&2; exit 2; }
    case "$2" in
      codex)        models_codex ;;
      cursor-agent) models_cursor_agent ;;
      agy)          models_agy ;;
      grok)         models_grok ;;
      *) echo "カタログ外の CLI: $2（probe/models に分岐を追加し、transports を検証してから使う）" >&2; exit 2 ;;
    esac
    ;;
  *)
    echo "usage: catalog.sh probe | catalog.sh models <cli>" >&2
    exit 2
    ;;
esac

