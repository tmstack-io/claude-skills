# claude-skills

自作 Claude Code **専用**スキルの正本リポジトリ。`~/.claude/skills/` からは各スキルディレクトリへのシンボリックリンクで参照する。

ここに置くスキルは、サブエージェントの並列実行・独立コンテキストの多角性・codex との相互チェックなど、Claude Code での運用構造そのものが品質の源泉であり、意図的に他エージェント向けの汎用化をしない。汎用スキル（plainify ほか）は [agent-skills](https://github.com/tmstack-io/agent-skills) を参照。

## 使い方（新しいマシンでの展開）

```sh
git clone git@github.com:tmstack-io/claude-skills.git <任意のパス>
cd <任意のパス>
for s in "$PWD"/*/; do
  ln -s "${s%/}" ~/.claude/skills/"$(basename "$s")"
done
```

`npx skills add tmstack-io/claude-skills` でもインストールできる（シンボリックリンク運用との併用は同名エントリが衝突するため、マシンごとにどちらか一方に統一する）。

## 収録スキル

| スキル | 概要 |
|---|---|
| concertino | 指定ロール（implement / review / explore）を複数ハーネス奏者の編成（合計4まで）に配役するセッションモード（TUI マルチプレクサ環境専用。奏者ごとにハーネスを指定可、既定 codex） |
| deep-pr-review | GitHub PR の高精度レビュー（多エージェント＋外部ハーネス独立レビュー＋architect メタ検証を統合レビュー1本に集約。TUI マルチプレクサ環境専用・投稿は pr-comment） |
| iterate-review | レビュー→修正→再レビューを GREEN までループする品質ゲート（レビュアーはセッションの配役に従う） |
| maestro | 高性能モデルを非実装の指揮者に固定し、実装・調査をサブエージェントへ委譲するセッションモード（`--deep` / `--fast` で検収深度を上書き） |
| memory-dream | Claude Code の全プロジェクト auto-memory を再編・統合する consolidation 手順 |
| pr-comment | 同一セッションの deep-pr-review 統合レビューから、ユーザーが選んだ指摘だけを GitHub PR のレビューコメントとして投稿（publish-polish で公開整形・行アンカー／会話コメント） |
| pr-recheck | 投稿済みの指摘コメントが PR の新しい head で解消されているかを検証（修正検証）し、選別を経て判定つきの返信を投稿（解消は resolve 併実施。セッションを跨いで動作） |
| solista | 編成1の concertino — 指定ロールを単独の奏者に配役するセッションモード（既定 codex） |

## 依存: agent-skills のスキル

- deep-pr-review は最終出力の明快化に [agent-skills](https://github.com/tmstack-io/agent-skills) の plainify を使う。plainify が見つからない場合、deep-pr-review はレビューを開始せずに中止して復旧手順を案内する。
- pr-comment は投稿文面の公開整形に agent-skills の publish-polish を使う（必須依存）。見つからない場合、pr-comment は投稿を開始せずに中止して復旧手順を案内する。
- pr-recheck も返信文面の公開整形に publish-polish を使う（必須依存）。見つからない場合、pr-recheck は検証を開始せずに中止して復旧手順を案内する。
- concertino（solista は concertino 経由）/ deep-pr-review は、ハーネス起用の共通基盤として agent-skills の tui-harness を使う（必須依存。2026-08 に本リポジトリから agent-skills へ移管）。見つからない場合、各スキルは開始せずに中止して復旧手順を案内する。
- roundtable（円卓会議）は 2026-08 に本リポジトリから agent-skills へ移管した（議長非依存の汎用スキル化。経緯は agent-skills の ADR 0005）。

復旧:

```sh
npx skills add tmstack-io/agent-skills --skill plainify
npx skills add tmstack-io/agent-skills --skill publish-polish
npx skills add tmstack-io/agent-skills --skill tui-harness
# または agent-skills を clone して ~/.claude/skills/ 配下にシンボリックリンク
```

## 編集時の前提

- スキルの査読には、Claude Code 上で agent-skills の `/skill-refine` を `--myself` を付けて使う（対象を実行エージェント＝Claude Code の専用スキルとして査読する）。
- スキルを追加・改名・削除したら本 README の収録スキル表を更新する。
