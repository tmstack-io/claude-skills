---
name: solista-codex
description: セッション中の指定ロール（implement / review / explore）を単独の codex 奏者に配役するセッションモード（編成1の concertino-codex）。
disable-model-invocation: true
argument-hint: "--implement|--review|--explore（1つ以上・併用可。implement×review の併用は不可） [--sandbox <mode>] [--model <model>] [--effort <level>] [--timeout <秒>]"
---

# solista-codex — ソリストは同時に一人

編成1の concertino-codex。名前が規律である: ソリスト（codex）が立っている間、同じパートを弾く者はいない。

本スキルと同じ収録場所の [`../concertino-codex/SKILL.md`](../concertino-codex/SKILL.md) を Read し、**指定ロールのすべてを兼任する奏者1人の編成**として適用する（奏者ラベルは `solista`。人数指定を除く全パラメータをそのまま透過し、ロール間の禁則・規律・輸送路も concertino-codex の規定がそのまま生きる）。concertino-codex が見つからない場合は配役を開始せず、claude-skills リポジトリのリンク復旧（README の展開手順）を案内して中止する。
