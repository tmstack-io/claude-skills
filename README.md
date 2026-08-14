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
| memory-dream | Claude Code の全プロジェクト auto-memory を再編・統合する consolidation 手順 |

## agent-skills への移管

roundtable（2026-08・ADR 0005）、concertino / solista / maestro（2026-08・ADR 0006）、deep-pr-review / pr-comment / pr-recheck（2026-08・ADR 0007）、iterate-review（2026-08・ADR 0008。レビュアー既定をハーネスペインへ変更）は、実行エージェント非依存の汎用スキル化のうえ [agent-skills](https://github.com/tmstack-io/agent-skills) へ移管した（各 ADR は agent-skills の docs/adr/）。

## 編集時の前提

- スキルの査読には、Claude Code 上で agent-skills の `/skill-refine` を `--myself` を付けて使う（対象を実行エージェント＝Claude Code の専用スキルとして査読する）。
- スキルを追加・改名・削除したら本 README の収録スキル表を更新する。
