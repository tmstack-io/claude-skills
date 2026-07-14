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
| deep-pr-review | GitHub PR の高精度レビュー（多エージェント＋codex＋architect メタ検証を統合レビュー1本に集約） |
| iterate-review | レビュー→修正→再レビューを GREEN までループする品質ゲート（レビュアーはセッションの配役に従う） |
| maestro | 高性能モデルを非実装の指揮者に固定し、実装・調査をサブエージェントへ委譲するセッションモード（`--deep` / `--fast` で検収深度を上書き） |
| memory-dream | Claude Code の全プロジェクト auto-memory を再編・統合する consolidation 手順 |
| soloist-codex | 指定ロール（implement / review / explore）を codex に配役するセッションモード（herdr 環境では TUI ペイン、無ければ headless CLI） |

## 依存: agent-skills の clarify-ja

deep-pr-review は最終出力の明快化に [agent-skills](https://github.com/tmstack-io/agent-skills) の clarify-ja を使う。clarify-ja が見つからない場合、deep-pr-review はレビューを開始せずに中止して復旧手順を案内する。復旧:

```sh
npx skills add tmstack-io/agent-skills --skill clarify-ja
# または agent-skills を clone して ~/.claude/skills/clarify-ja にシンボリックリンク
```

## 編集時の前提

- スキルの査読には、Claude Code 上で agent-skills の `/skill-refine` を `--myself` を付けて使う（対象を実行エージェント＝Claude Code の専用スキルとして査読する）。
- スキルを追加・改名・削除したら本 README の収録スキル表を更新する。
