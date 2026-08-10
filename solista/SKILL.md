---
name: solista
description: セッション中の指定ロール（implement / review / explore）を単独の奏者に配役するセッションモード（編成1の concertino）。
disable-model-invocation: true
argument-hint: "--implement|--review|--explore（1つ以上・併用可。implement×review の併用は不可） [--harness <CLI名>] [--model <モデル>] [--sandbox <mode>] [--approval <policy>] [--reviewer <裁定者>] [--effort <level>]"
---

# solista — ソリストは同時に一人

編成1の concertino。名前が規律である: ソリスト（ハーネスは concertino の規定に従い指定可・既定 codex）が立っている間、同じパートを弾く者はいない。

本スキルと同じ収録場所の concertino の SKILL.md を Read し、**指定ロールのすべてを兼任する奏者1人の編成**として適用する（奏者ラベルは `solista`。人数指定を除く全パラメータをそのまま透過し、ロール間の禁則・規律・ハーネス起用も concertino の規定がそのまま生きる。`--harness <CLI名>` / `--model <モデル>` / `--effort <level>` は concertino の `--harness solista=<CLI名>` / `--model solista=<モデル>` / `--effort solista=<level>` として適用する）。解決順: `../concertino/SKILL.md` → `.claude/skills/concertino/SKILL.md` → `~/.claude/skills/concertino/SKILL.md`。見つからない場合は配役を開始せず、claude-skills リポジトリのリンク復旧（README の展開手順）を案内して中止する。

複数ロールを兼務する場合、実行中の作業が属するロールの規律を適用する（implement 作業中はパート譜の書き込み範囲、explore / review 作業中は成果物置き場への読み取り専用規律）。
