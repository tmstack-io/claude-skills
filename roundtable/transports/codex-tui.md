# codex TUI 輸送路 — 固有差分

codex の対話ハーネスを賢者ペインで起用するときのハーネス固有差分。共通手順の正本は [../tui-protocol.md](../tui-protocol.md)（ペイン操作は `mux.sh` 経由）。

## 起動

`mux.sh run` に渡す起動コマンド:

```sh
codex --sandbox workspace-write -c approval_policy=on-request -c approvals_reviewer=auto_review -C '<プロジェクトルート>'
```

- **sandbox は `workspace-write`**: read-only は回答ファイルの書き出しと通信規約の push まで遮断するため使わない。書き込みの遮断はブリーフの規律が担う。
- **`on-request` ＋ `auto_review`**: 承認要求（sandbox 昇格・MCP ツール承認等）を codex のリスク評価サブエージェントに自動裁定させる公式機構で、無人運用の成立要件。`never` は承認要求を裁定に乗せないため使わない。
- モデルは当該席の `--model` 指定時のみ付加する: `-m <slug>`、effort 付き（`<slug>@<effort>` 解決時）はさらに `-c model_reasoning_effort=<effort>`。省略時は `~/.codex/config.toml` の既定。実測モデル名はペイン下部の表示（例: `gpt-5.6-terra max`）で確認できる。モデル名は TUI 起動時に検証されず、誤指定は最初のターンで API エラーとして顕在化する（`sages.sh models codex` による事前検証が SKILL.md の規定）。

## trust ダイアログ

cwd の trust が `~/.codex/config.toml` に未記録だと、git リポジトリでも初回起動時に trust ダイアログ（"Do you trust the contents of this directory?"）が出る。`mux.sh wait-output <ペインID> "Do you trust" 15000` で確定待ちし、マッチしたら `mux.sh send <ペインID> "1"` ＋ `mux.sh key <ペインID> Enter` で「Yes, continue」を選ぶ（タイムアウト＝ダイアログなしは正常分岐）。この Yes は config.toml にプロジェクトの `trust_level = "trusted"` を永続記録する。同一セッションで同一プロジェクトの Yes 通過またはダイアログなし起動を観測済みなら、以後の起動では確定待ちを省いてよい。

## エージェント検知と受理判定

- エージェント名 `codex`。`agent_session`（codex セッション ID）を報告する — 受理完了の判定は tui-protocol 手順2の本則（working ＋ `agent_session`）に従う。**`agent_session` 無しの working 応答は実測で発生する** — その場合は手順3の二分（`mux.sh read` で実作業を確認）で受理を確定する。
- 完了後に done を報告せず idle に戻るだけのことがある（実測）— pull 安全網は tui-protocol の規定どおり `--until` 無しで張る。

## 検証記録

2026-07-30 実測（合議2件・計5ラウンドの実運用）: trust 済みプロジェクトでのダイアログなし起動 / エージェント検知（`codex`・status・session）/ `agent_session` 無し working 応答と pane read 二分での受理確定 / auto_review による書き込み・push の無人裁定 / 完了 push の到達（5/5）/ ラウンド間の同一ペイン追送による文脈保持 / ペイン表示での実測モデル確認（`gpt-5.6-terra max`）。
