---
name: memory-dream
description: Claude Code に保存された全プロジェクトの auto-memory を再編し重複・矛盾・陳腐化を除去する consolidation 手順。「記憶の整理」「dream」の指示で使用。
argument-hint: [project-slug | project-path]（省略時は全プロジェクト）
---

# memory dream（記憶の整理／consolidation）

Claude Code の記憶階層（全プロジェクトの auto-memory）を定期的に再編し、重複・矛盾・陳腐化を除去する作業の手順書。Anthropic Managed Agents の **Dreams**（別名 auto-dream）を、Claude Code のファイルベース記憶で再現するためのもの。

## これは何か / なぜ必要か

エージェントはセッションごとに記憶へ追記する。追記は局所的・増分的なので、20〜30 セッションを超えると memory store に **重複・矛盾・陳腐化エントリ**が溜まり、ノートが「思い出す助け」から「混乱させるノイズ」へ転落する（相対日付の意味喪失、削除済みファイルを指す古い手順、完了済みなのに「検討中」のままの plan など）。

dream は、過去セッションと既存記憶を読み、**重複をマージ・古い/矛盾する値を最新で置換・繰り返しパターンを簡潔な知見として抽出**する。入力を直接書き換えず、レビューを経てから採用する（本家 Dreams の設計に準拠。詳細は「参考」）。

## 対象（Claude Code の記憶階層）

dream が編集するのは **auto-memory 全体**:

- `~/.claude/projects/<project-slug>/memory/` — プロジェクトごとの auto-memory
  - `MEMORY.md` — 索引（毎セッション自動ロード。1 ファイル 1 行フック）
  - `*.md` — 個別メモリ（frontmatter 付き。関連時に想起）

引数でプロジェクト（slug またはリポジトリパス）を指定した場合はそのプロジェクトのみ。省略時は memory/ を持つ全プロジェクトを列挙して順に処理する:

```bash
ls -d ~/.claude/projects/*/memory 2>/dev/null
```

上位レイヤは **参照のみ**（ルールの定義元として重複判定に使う。dream では編集しない）:

1. `~/.claude/CLAUDE.md`・`~/.claude/rules/*.md` — ユーザーグローバル指示（最上位・ユーザー手動管理）
2. 各リポジトリの `CLAUDE.md`・`.claude/rules/`・`AGENTS.md` — プロジェクト指示(リポジトリ管理)

## 実施モデル（非破壊・レビュー後採用）

auto-memory は git 管理外のため、「入力非破壊・レビュー後採用」は**実行前フルバックアップ＋変更内容の明示報告**で代替する。実行前に必ず取得する:

```bash
BK=~/.claude/backups/memory-dream-$(date +%Y%m%d-%H%M%S)
mkdir -p "$BK"
for d in ~/.claude/projects/*/memory; do
    cp -a "$d" "$BK/$(basename "$(dirname "$d")")"
done
echo "$BK"
```

（単一プロジェクト対象時は該当プロジェクト分のみで良い。）気に入らない結果はここから丸ごと復元できる: `cp -a "$BK/<slug>/" ~/.claude/projects/<slug>/memory/`

### プロジェクト slug → 実リポジトリの特定

「存在しないファイル/シンボル参照の除去」には実リポジトリのパスが要る。slug の機械的復元は一意でない（`/` も `.` も `-` に潰れる）ため、セッション記録の cwd から特定する:

```bash
grep -m1 -o '"cwd":"[^"]*"' ~/.claude/projects/<slug>/*.jsonl 2>/dev/null | head -1
```

リポジトリが手元に無い（削除済み・別マシン）場合、その memory の実体検証は**検証不能**とする — 削除せず保持し、その旨を報告する。

## 4 フェーズ手順（プロジェクトごとに独立して実施）

1. **Mine（採掘）**: 直近セッションの transcript / 作業内容から、繰り返し出た指摘・確定した方針・新事実を抽出する。一回限りのデバッグメモは拾わない。
2. **Consolidate（統合）**: 抽出物を既存記憶へマージ。相対日付（"昨日" 等）は**絶対日付に変換**。矛盾は最新の値で解決し古い記述を置換。存在しないファイル/関数/フラグを指す記述は除去（or 現存確認して更新）。plan・進行中タスクのメモリは実際の進捗（ブランチ・PR・マージ状態）を確認し、完了していれば恒久知見へ再編する。
3. **Dedup & Resolve（重複排除・矛盾解消）**: 階層をまたいだ重複を除去する。**最重要原則: 上位レイヤが定めるルールを下位で再掲しない。** auto-memory は重複を黙って消し、そのプロジェクト固有の知見だけ残す（残し方は後述「成果ファイルの書き方」に従う）。矛盾が真にある場合はユーザーへ確認。
4. **Prune & Index（剪定・索引化）**: `MEMORY.md` は lean な索引に保つ（1 ファイル 1 行フック、目安 200 行未満）。冗長な節・完了済みで価値の無い記述を削除。ファイルの新設・改名・削除をしたら索引と `[[リンク]]` を同期し、最後に整合を検証する:

```bash
MEM=~/.claude/projects/<slug>/memory
# 索引 → 実ファイル
grep -o '([a-z0-9-]*\.md)' "$MEM/MEMORY.md" | tr -d '()' | while read -r f; do [ -f "$MEM/$f" ] || echo "MISSING $f"; done
# 実ファイル → 索引
for f in "$MEM"/*.md; do b=$(basename "$f"); [ "$b" = MEMORY.md ] && continue; grep -q "($b)" "$MEM/MEMORY.md" || echo "UNINDEXED $b"; done
# [[リンク]] の dangling（コードブロック内の TOML `[[...]]` 等は誤検出しうる — 目視で除外）
grep -ho '\[\[[a-z0-9-]*\]\]' "$MEM"/*.md | sort -u | tr -d '[]' | while read -r n; do [ -f "$MEM/$n.md" ] || echo "DANGLING [[$n]]"; done
```

プロジェクト間は独立なので、多数のプロジェクトを対象とする場合は**プロジェクト単位でサブエージェントに委任して並列化**してよい。ただし委任するのは調査・検証（現存確認・進捗確認）までとし、編集の採用判断と最終レビューは本体で行う。

## 重複排除の判定ルール

- 重複は常に「下位（auto-memory）→ 上位（CLAUDE.md / rules）」方向で発生する。**修正は auto-memory 側**で行い、上位（ユーザー・リポジトリ管理物）は触らない。
- 各情報は定義箇所を一つに保つ。上位が定めるルールは auto-memory から単に消す（必要なら所在だけを 1 句で指す。例: 「PR 手順は `.claude/rules/github-pull-request.md` に従う」）。
- リポジトリ自身が記録している事実（コード構造・過去の修正・git 履歴・CLAUDE.md 記載事項）は auto-memory に持たない — 見つけたら削除対象。
- 同種の知見が複数プロジェクトの auto-memory に現れる場合、それはプロジェクト非依存の可能性がある。グローバル昇格（`~/.claude/CLAUDE.md` への追記）は**ユーザー確認事項として報告**し、勝手に昇格しない。

### 成果ファイルの書き方（重要）

auto-memory の形式規約（frontmatter の `name`/`description`/`metadata.type`、feedback/project タイプの **Why:** / **How to apply:**）は維持する。そのうえで:

- **Why:** は行動を変える技術的因果に限定する（「A だと B が壊れるので C する」）。誰がいつ何回指摘したか・セッションの経緯・学習日は書かない。
- 重複回避の注記（「これは X が定める、ここでは再掲しない」等のメタ説明）は書かない。重複は黙って消すだけでよい。
- 自動付与メタデータ（`originSessionId` 等）は既存分をそのまま保持し、dream が新設するファイルには手で付けない。
- 陳腐化した plan は、完了後も価値の残る恒久知見（確定した仕様・残存バグ・環境の落とし穴）へ再編して残す。価値が残らなければファイルごと削除する。

## チェックリスト

- [ ] 実行前フルバックアップを `~/.claude/backups/memory-dream-*/` に取得した
- [ ] 相対日付をすべて絶対日付へ変換した
- [ ] 上位（CLAUDE.md / rules）が定めるルールを auto-memory から削った（重複回避の注記自体も残していない）
- [ ] 成果ファイルから経緯・履歴（失敗談 / 再発回数 / 学習日 / セッション ID の本文記載）を除いた
- [ ] 矛盾を最新値で解決した（曖昧ならユーザー確認）
- [ ] 存在しないファイル/シンボルへの参照を除去 or 現存確認した（リポジトリ不在は検証不能として保持・報告）
- [ ] 完了済み plan を恒久知見へ再編 or 削除した
- [ ] 各プロジェクトの MEMORY.md 索引が lean で、索引・実ファイル・`[[リンク]]` の整合を検証した
- [ ] 変更内容（プロジェクト別の再編・削除・保留）をユーザーがレビューできる形で報告した
- [ ] 採用前に出力をレビュー（dream 出力は hallucination 混入の懸念があるため鵜呑みにしない）

## トリガー条件（いつ実施するか）

- 大規模リファクタ直後（リネーム多数・フレームワーク移行・API 構造変更）— 古いエントリが混乱を増やすため最優先。
- セッション数の蓄積時（本家デフォルト目安 24h かつ 5 セッション、実務的には 20〜30 セッションでノイズ化）。
- ユーザーが「記憶の整理」「dream」と指示したとき。

## 注意点

- 入力非破壊が原則。バックアップ取得前に memory を編集しない。復元は `cp -a` で丸ごと戻す。
- 出力が誤りを混入しうるため、**採用前レビュー必須**。
- 他プロジェクトの memory を編集する際も、検証の基準はそのプロジェクトのリポジトリ・上位レイヤであって、現在開いているプロジェクトではない。

## 参考

- [Dreams — Claude API Docs](https://platform.claude.com/docs/en/managed-agents/dreams)（公式。`managed-agents-2026-04-01` + `dreaming-2026-04-21` beta header、Opus 4.7 / Sonnet 4.6、最大 100 セッション、`instructions` 4096 文字）
- [What Is Claude Dreaming? (MindStudio)](https://www.mindstudio.ai/blog/what-is-claude-dreaming-anthropic-managed-agents)
- [Claude Code Dreams: Auto Dream guide (Supalaunch)](https://supalaunch.com/blog/claude-code-dreams-auto-dream-memory-consolidation-guide)
- [Auto-dream mechanics (claudefa.st)](https://claudefa.st/blog/guide/mechanics/auto-dream)
- [grandamenium/dream-skill（4 フェーズ consolidation の OSS 再現）](https://github.com/grandamenium/dream-skill)
