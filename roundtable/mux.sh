#!/usr/bin/env bash
# roundtable TUI マルチプレクサラッパーの正本 — ペイン操作の機械的差異を吸収する。
# 議長も賢者（通信規約の push）も、ペイン操作は本スクリプト経由で行う
# （マルチプレクサの生コマンドを直接叩かない。セッション毎のばらつき防止）。
#
# バックエンド: herdr（0.7 系コマンド形・検証済み）のみ。cmux / tmux は未検証のため
# 未対応（detect が検出した場合は stderr に表示だけする）。
#
# 使い方:
#   mux.sh detect
#       利用可能なバックエンドを判定し「backend=<名前>」を stdout に出力する。
#       検証済みバックエンドが無ければ理由を stderr に出して exit 1。
#   mux.sh split <対象ペインID> <right|down>
#       対象ペインを分割し、新ペインの ID だけを1行出力する（フォーカスは移さない）。
#   mux.sh run <ペインID> <コマンド文字列>       … ペインでコマンドを起動する
#   mux.sh send <ペインID> <テキスト>            … テキストを送る（Enter は送らない）
#   mux.sh key <ペインID> <キー名>               … キーを送る（例: Enter, y）
#   mux.sh read <ペインID> [--scrollback] [--lines <N>]
#       画面を読む。--scrollback は折り返し前の履歴ソース（alt-screen 描画の
#       ハーネスで必須）。既定は可視画面・20行。
#   mux.sh wait-output <ペインID> <パターン> <タイムアウトms>
#       パターンの出現を確定待ちする（現れなければ非0終了）。
#   mux.sh agent-wait <ペインID> [--until idle|working|done|blocked] <タイムアウトms>
#       ペインのエージェント状態の到達を確定待ちし、状態 JSON を出力する。
#       --until なしは idle / done / blocked のいずれかで発火する（pull 安全網用）。
#   mux.sh close <ペインID>
#   mux.sh list                                  … 全ペインの一覧 JSON
#   mux.sh layout                                … フォーカス中タブのレイアウト JSON
#
# バックエンドの追加: 対話 TUI での実測検証（分割・送信・読み取り・エージェント状態
# 検知・確定待ち）を済ませてから、detect の判定と各サブコマンドの case に
# <バックエンド名>) 分岐を実装する（検証なしに追加しない）。

set -u -o pipefail

detect_backend() {
  if [ "${HERDR_ENV:-}" = "1" ] && command -v herdr >/dev/null 2>&1; then
    echo herdr
    return 0
  fi
  command -v cmux >/dev/null 2>&1 && echo "cmux: 検出したが未検証のため未対応" >&2
  command -v tmux >/dev/null 2>&1 && echo "tmux: 検出したが未検証のため未対応" >&2
  echo "検証済みの TUI マルチプレクサが無い（対応: herdr）" >&2
  return 1
}

extract_pane_id() {
  sed -n 's/.*"pane_id"[[:space:]]*:[[:space:]]*"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/p' | head -n1
}

cmd=${1:-}
[ -n "$cmd" ] || {
  echo "usage: mux.sh detect|split|run|send|key|read|wait-output|agent-wait|close|list|layout ..." >&2
  exit 2
}
shift

if [ "$cmd" = "detect" ]; then
  BACKEND=$(detect_backend) || exit 1
  echo "backend=$BACKEND"
  exit 0
fi

BACKEND=$(detect_backend) || exit 1

case "$BACKEND" in
  herdr)
    case "$cmd" in
      split)
        [ $# -eq 2 ] || { echo "usage: mux.sh split <対象ペインID> <right|down>" >&2; exit 2; }
        out=$(herdr pane split "$1" --direction "$2" --no-focus) || exit 1
        pane=$(printf '%s' "$out" | extract_pane_id)
        [ -n "$pane" ] || { echo "split の応答から pane_id を取得できない: $out" >&2; exit 1; }
        echo "$pane"
        ;;
      run)
        [ $# -eq 2 ] || { echo "usage: mux.sh run <ペインID> <コマンド文字列>" >&2; exit 2; }
        herdr pane run "$1" "$2"
        ;;
      send)
        [ $# -eq 2 ] || { echo "usage: mux.sh send <ペインID> <テキスト>" >&2; exit 2; }
        herdr pane send-text "$1" "$2"
        ;;
      key)
        [ $# -eq 2 ] || { echo "usage: mux.sh key <ペインID> <キー名>" >&2; exit 2; }
        herdr pane send-keys "$1" "$2"
        ;;
      read)
        [ $# -ge 1 ] || { echo "usage: mux.sh read <ペインID> [--scrollback] [--lines <N>]" >&2; exit 2; }
        pane=$1; shift
        source=visible lines=20
        while [ $# -gt 0 ]; do
          case "$1" in
            --scrollback) source=recent-unwrapped; shift ;;
            --lines) lines=$2; shift 2 ;;
            *) echo "read: 不明なオプション: $1" >&2; exit 2 ;;
          esac
        done
        herdr pane read "$pane" --source "$source" --lines "$lines"
        ;;
      wait-output)
        [ $# -eq 3 ] || { echo "usage: mux.sh wait-output <ペインID> <パターン> <タイムアウトms>" >&2; exit 2; }
        herdr pane wait-output "$1" --match "$2" --timeout "$3"
        ;;
      agent-wait)
        [ $# -ge 2 ] || { echo "usage: mux.sh agent-wait <ペインID> [--until <状態>] <タイムアウトms>" >&2; exit 2; }
        pane=$1; shift
        until_arg=()
        if [ "$1" = "--until" ]; then
          until_arg=(--until "$2"); shift 2
        fi
        [ $# -eq 1 ] || { echo "usage: mux.sh agent-wait <ペインID> [--until <状態>] <タイムアウトms>" >&2; exit 2; }
        herdr agent wait "$pane" "${until_arg[@]+"${until_arg[@]}"}" --timeout "$1"
        ;;
      close)
        [ $# -eq 1 ] || { echo "usage: mux.sh close <ペインID>" >&2; exit 2; }
        herdr pane close "$1"
        ;;
      list)
        herdr pane list
        ;;
      layout)
        herdr pane layout
        ;;
      *)
        echo "不明なサブコマンド: $cmd" >&2
        exit 2
        ;;
    esac
    ;;
esac
