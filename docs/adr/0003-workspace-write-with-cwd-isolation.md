# 全奏者を workspace-write で起動し、プロジェクト保護を cwd 分離に移す

Status: accepted（ADR 0002 の Consequence「sandbox 既定は奏者単位（implement 奏者のみ workspace-write）」を置き換える）

運用初日に `read-only` sandbox の実害が確定した: シェルの書き込みに加えて、herdr への完了通知（ソケット送信が Operation not permitted）と MCP ツールの書き込み系呼び出しまで遮断され、review / explore 奏者は報告書を書けず完了も通知できない — TUI 輸送路の通信契約（ペイロードはファイル、ペインは信号）が原理的に履行不能だった。対策として sandbox モードは全奏者 `workspace-write` に統一し、プロジェクトへの書き込み保護は **cwd の分離**で実現する: workspace-write の書き込み許可は cwd と OS 一時領域に限られるため、review / explore 奏者の cwd を一時領域の作業ディレクトリ（`<一時領域>/<奏者ラベル>/`）に置けば、プロジェクトは sandbox レベルで書き込み不能のまま報告書・通知・MCP が通る。あわせて通信規約に送信不能時のフォールバック（同文の done / question 行を最終メッセージに出力 → 既存の pull 安全網で回収）を追加した。

## Considered Options

- **read-only を維持し、報告はペイン出力の pull のみにする** — 却下。長文報告が端末の折返し・行数制限で劣化し、MCP 書き込み抑制も残る。
- **workspace-write＋cwd=プロジェクトで、「書かない」はブリーフ規律に委ねる** — 却下。review / explore の書き込み不能が prompt レベルの約束に落ち、single-writer の sandbox 保証が消える。
- **workspace-write＋cwd 分離（採用）**。

## Consequences

- review / explore 奏者はプロジェクトをブリーフ記載の絶対パスで読む（読み取りは sandbox 無制約）。cwd がプロジェクト外になるため codex のプロジェクト文脈（AGENTS.md 等）は自動では載らず、必要な文脈は自己完結ブリーフが運ぶ（既存規定で充足）。
- 本変更は sandbox レイヤーの修正であり、MCP ツールの承認プロンプト（`approval_mode` レイヤー、`~/.codex/config.toml`）は消えない。
- CLI 輸送路も同じ cwd 規則に統一（`codex exec` の `-o` は sandbox 外で書かれるため従来 read-only でも報告は成立していたが、MCP 抑制は共通のため）。
