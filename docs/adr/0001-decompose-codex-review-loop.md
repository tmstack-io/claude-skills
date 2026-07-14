# codex-review-loop を配役（soloist-codex）と収束ループ（iterate-review）に分解して削除する

Status: accepted

codex-review-loop は「レビュアーは codex」という配役と「GREEN まで回す」というループ構造を1本のスキルに焼き込んでおり、どちらの関心も単独では再利用できなかった。これを直交する2スキル — セッション中の特定ロール（implement / review / explore）を codex へ割り当てる **soloist-codex** と、レビュアー非依存の収束ループ **iterate-review** — に分解し、codex-review-loop はエイリアスや移行注記を残さず削除する。maestro（構造: 指揮者と奏者の分離）× soloist-codex（配役）× iterate-review（品質ゲート）の合成で、統合スキル1本より広い運用範囲を少ない規定量で覆える。配役ファミリーの接頭辞は、初見の自己説明性より maestro の音楽メタファーとの一貫性を取り、single-writer 規律（ソリストは同時に一人）を名前自体が運ぶ `soloist-` とする（`agent-` は Claude Code の Agent ツールと語が重なる点でも不利）。ループ側は機構の平明さを優先し、音楽語彙（da-capo 等）を採らず `iterate-` とする。

## Considered Options

- **maestro に「実装は codex」を組み込む** — 却下。汎用の構造スキルに特定エージェントへの依存が入り、可用性が狭まる。
- **codex-review-loop を維持したまま実装委譲スキルを別に足す** — 却下。「codex ×ループ」の焼き込みが残り、レビュアー差し替え・ループの他用途転用が塞がったまま。
- **分解して削除（採用）** — 資産は消さず再配置する: codex 実行プロトコル（タイムアウト・事後判定・リトライ）→ soloist-codex の CLI 輸送路 / ループ構造（ラウンド・GREEN・スコアボード・暴走防止・PR/非 git 対応）→ iterate-review / 語彙 → CONTEXT.md。

## Consequences

- 輸送路は2種: herdr 環境では **TUI 輸送路**（ペイン・観戦と介入が可能）、非 herdr 環境では **CLI 輸送路**（headless・ファイル受け渡し）。TUI を既定に選ぶ根拠は運用実績 — 対話式 codex が出力を吐かずにハングした事例はゼロである一方、headless はタイムアウト到達時に成果ゼロで時間を失う。
- soloist-codex に Claude 代替は存在しない。起動した時点でユーザーが求めるのは codex の成果であり、codex が失敗したら失敗を明示して終了する（ロール不問）。「Claude 代替」の語彙は soloist-codex を経由しない codex 起用（ralplan / ralph 等の共通ルール）でのみ生きる。
- `--implement` と `--review` の同時有効化は同一モデルの自己査読になるためエラー（fail fast）。
- 削除は置き換えと同一変更で行い、`~/.claude/hooks/codex-exec-rules.md` の codex-review-loop への名指しも同時に書き換える（リポジトリ外のフォローアップ）。
