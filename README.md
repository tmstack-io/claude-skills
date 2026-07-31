# claude-skills

自作 Claude Code **専用**スキルの正本リポジトリ。`~/.claude/skills/` からは各スキルディレクトリへのシンボリックリンクで参照する。

ここに置くスキルは、サブエージェントの並列実行・独立コンテキストの多角性・codex との相互チェックなど、Claude Code での運用構造そのものが品質の源泉であり、意図的に他エージェント向けの汎用化をしない。汎用スキル（clarify-ja ほか）は [agent-skills](https://github.com/tmstack-io/agent-skills) を参照。

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
| concertino-codex | 指定ロール（implement / review / explore）を複数 codex 奏者の編成（合計4まで）に配役するセッションモード（herdr 環境では奏者ごとの TUI ペイン、無ければ headless CLI） |
| deep-pr-review | GitHub PR の高精度レビュー（多エージェント＋codex＋architect メタ検証を統合レビュー1本に集約） |
| iterate-review | レビュー→修正→再レビューを GREEN までループする品質ゲート（レビュアーはセッションの配役に従う） |
| maestro | 高性能モデルを非実装の指揮者に固定し、実装・調査をサブエージェントへ委譲するセッションモード（`--deep` / `--fast` で検収深度を上書き） |
| memory-dream | Claude Code の全プロジェクト auto-memory を再編・統合する consolidation 手順 |
| roundtable | 与えられた合議の主題を異系統の3 LLM（Claude 固定＋起動ごとに選ぶ2席）で合議し、最終回答に統合する円卓会議（TUI マルチプレクサ環境専用〔現行 herdr〕。議事録を `.roundtable/` に永続保存） |
| solista-codex | 編成1の concertino-codex — 指定ロールを単独の codex 奏者に配役するセッションモード |

## 依存: agent-skills のスキル

- deep-pr-review は最終出力の明快化に [agent-skills](https://github.com/tmstack-io/agent-skills) の clarify-ja を使う。clarify-ja が見つからない場合、deep-pr-review はレビューを開始せずに中止して復旧手順を案内する。
- roundtable は最終提示後の実装プロンプト書き出し（求められた場合のみ）に agent-skills の session-to-prompt を使う。見つからない場合は書き出しのみ中止して復旧手順を案内する（合議自体は完了する）。

復旧:

```sh
npx skills add tmstack-io/agent-skills --skill clarify-ja
npx skills add tmstack-io/agent-skills --skill session-to-prompt
# または agent-skills を clone して ~/.claude/skills/ 配下にシンボリックリンク
```

## 編集時の前提

- スキルの査読には、Claude Code 上で agent-skills の `/skill-refine` を `--myself` を付けて使う（対象を実行エージェント＝Claude Code の専用スキルとして査読する）。
- スキルを追加・改名・削除したら本 README の収録スキル表を更新する。
