# 全奏者の cwd をプロジェクトルートに統一し、プロジェクト保護をブリーフ規律に移す

Status: accepted（ADR 0003 の「cwd 分離」を置き換える。全奏者 workspace-write は維持）

codex CLI 0.144.5 の実機検証で次が確定した: TUI（対話起動の `codex`）は cwd が git リポジトリでも trust 未記録なら初回に必ず trust ダイアログを出す。`-c projects."<path>".trust_level="trusted"` の注入は TUI / exec とも trust 判定に効かない。trust は cwd 単位で配下に継承しない。したがって ADR 0003 の cwd 分離（review / explore の cwd を OS 一時領域に置く）は TUI 輸送路で trust ダイアログを回避できず成立しない。対策として全奏者の cwd をプロジェクトルートに統一し、TUI の trust ダイアログは「出たら Yes」（config.toml にプロジェクト1エントリを永続記録）で通過する。成果物はプロジェクト直下の `.concertino/<奏者ラベル>/`（成果物置き場。本スキル専用の名前空間とし、既存ディレクトリとの衝突を設計から除く）に置き、クローズ/解除時に後始末する。review / explore のプロジェクト本体への書き込み遮断は、sandbox からブリーフの読み取り専用規律（「成果物は `.concertino/<奏者ラベル>/` にのみ書く」の肯定形主文）に移す。

## Considered Options

- **一時領域を git init して TUI のダイアログを回避** — 却下。TUI は git リポジトリでも初回ダイアログを出すと実測で確定（git であることは抑止にならない）。
- **config.toml へ trust を機械追記し、クローズ時に削除** — 却下。機械編集の競合・TOML 破損のリスクがあり、cwd=プロジェクト方式なら不要。
- **review / explore の cwd を成果物置き場（`<proj>/.concertino/<奏者>` 等のプロジェクト配下サブディレクトリ）にする** — 却下。trust は cwd 単位で継承せず、奏者ごとに trust エントリが増える。
- **cwd=プロジェクトルート＋ブリーフ規律（採用）** — ADR 0003 で却下した案の再採用。当時の却下理由「single-writer の sandbox 保証が消える」は、auto_review が sandbox 昇格を承認し得ると判明した時点で絶対の保証ではなくなっていた。Claude のサブエージェント（Explore 等）が指示で読み取り専用を守るのと同型の規律として許容する。

## Consequences

- trust の記録はプロジェクト1エントリに集約される。ユーザーが既に作業対象にしているプロジェクトのため、config.toml への記録は許容する。
- cwd がプロジェクトルートになり、codex のプロジェクト文脈（AGENTS.md 等）が全奏者に自動で載る（ADR 0003 の Consequence を打ち消す）。
- プロジェクト直下に `.concertino` が生じるため、後始末（クローズ/解除時）と `.git/info/exclude` への追記提案を規定する。
- CLI 輸送路も同じ cwd 規則に統一する（`--skip-git-repo-check` と `-C` の明示は維持。非 git プロジェクトで trust チェックに止まらないために必要で、git リポジトリでは無害）。
