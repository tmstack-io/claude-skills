# 配役の正本を concertino-codex に置き、solista-codex を編成1のラッパーにする

Status: accepted

旧 soloist-codex は配役を1奏者に固定しており、explore の並列調査・review の多視点同時批評・implement のファイル分離並列を表現できなかった。配役の一般形 — **編成**（ロール×人数、奏者合計4まで）を宣言するセッションモード — を新設スキル **concertino-codex** に正本として置き、旧 soloist-codex は「指定ロールのすべてを兼任する奏者1人の編成」を組む薄いラッパー **solista-codex** へ置き換える。輸送路プロトコル2本（TUI / CLI）は concertino-codex 配下へ移す — 特殊化（編成1への固定）は参照1行で成立するが、参照による一般化は N 固有の規定（パート譜・集約・複数ペイン管理）を結局一般側に書くことになり、参照の向きが不自然になるため。あわせて接頭辞を伊語 solista- に改め、maestro / concertino / solista の音楽語彙を単一言語に統一する（英語 soloist- の痕跡は ADR 0001 を除き、エイリアスを残さず置換）。

## Considered Options

- **soloist-codex を正本のまま、concertino が参照して N 化** — 却下。移動リスクはゼロだが、一般化の参照方向が不自然になり、N 固有規定の置き場が割れる。
- **concertino に統合し soloist を削除** — 却下。スキル数は減るが、single-writer を名前で運ぶ solista の価値（ADR 0001 の命名判断）を手放す。
- **concertino 正本化＋solista ラッパー（採用）**。

## Consequences

- 編成上限は奏者合計4。根拠は TUI の観戦可能なペイン数・指揮者の検収スループット・concertino（少人数の独奏者群）という名前の含意。超過は fail fast。
- implement と review は奏者を分けても同一編成に共存できない（同一モデルの自己査読）。分業が要る場合はレビューを配役なしの iterate-review に出す。
- **single-writer は「どのファイルも担当奏者は常に一人」へ一般化**（編成1では従来定義と一致）。implement 並列は git worktree を使わず、**パート譜**（排他的な担当ファイル集合）で分離する。パート譜の外が必要になったら停止→質問→指揮者の再配分（拡張または直列化）。
- review 複数奏者の合格は**全奏者の GREEN（AND）・指摘は和集合**。iterate-review は無改修（集約規定は concertino 側が持つ）。
- リポジトリ外フォローアップ: `~/.claude/hooks/codex-exec-rules.md` の soloist-codex 名指しを solista-codex / concertino-codex に書き換え、`~/.claude/skills/` のリンクを張り替える。
