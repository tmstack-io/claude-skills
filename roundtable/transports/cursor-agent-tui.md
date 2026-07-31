# cursor-agent TUI 輸送路 — 固有差分

cursor-agent の対話ハーネスを賢者ペインで起用するときのハーネス固有差分。共通手順の正本は [../tui-protocol.md](../tui-protocol.md)（ペイン操作は `mux.sh` 経由）。

## 起動

`mux.sh run` に渡す起動コマンド:

```sh
cursor-agent --trust --auto-review --workspace '<プロジェクトルート>'
```

- **`--trust`**（必須）: Workspace Trust ダイアログを出さずに起動する（trust ダイアログの確定待ちは不要になる）。
- **`--auto-review`**（必須）: 承認要求をサーバ側分類器に自動裁定させる（codex の `on-request` ＋ `auto_review` に相当する無人運用の成立要件）。`--force` / `--yolo` は承認を全面バイパスするため使わない。
- **既定モード（agent）で起動する**: `--mode ask` は読み取り専用のため回答ファイルの書き出しと完了通知が行えない。書き込みの遮断はブリーフの規律が担う。
- モデルは当該席の `--model` 指定時のみ `--model <モデル>` を付加する。省略時はアカウントの既定モデル（起動後にペインのフッターへ表示される。編成の宣言・question.md に記載する）。

## エージェント検知と受理判定

- エージェント名 `cursor`。`agent_session` を報告する — 受理完了の判定は tui-protocol 手順2の本則（working ＋ `agent_session`）に従う。
- ツール活動（ファイル編集・シェル実行）は差分付きでペインに表示され、観戦できる（表示されるのはツール活動と回答の出力であり、モデル内部の推論過程ではない）。

## 固有の注意

- 賢者自身による push（通信規約のコマンド実行）は auto-review の裁定次第で承認待ちになり得る（未検証）。pull 安全網での回収を必須とし、push はあれば早いという扱いにする。

## 検証記録

2026-07-30 実測: `--trust` によるダイアログ抑止 / エージェント検知（`cursor`・status・session）/ send ＋ Enter の委譲と Enter 吸収の再現（tui-protocol 手順3の二分で回復）/ 既定モード＋`--auto-review` でのファイル書き込み自動承認とツール活動のペイン表示。未検証: 賢者自身による push の実行可否（安全網回収でカバー）。
