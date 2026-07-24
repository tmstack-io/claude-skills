# TUI 輸送路 — herdr ペインの奏者と協働する

ペインの奏者（codex）は観戦・介入できる。原則は2つ。「**ペイロードはファイル、ペインは信号**」— 長文をペインに流し込まない。「**待ちは確定待ち**」— 状態の完了を `sleep` で推測せず、`herdr pane wait-output` / `herdr agent wait` による観測をもって次へ進む（入力ペーシングの短い `sleep` は状態待ちではない）。奏者が複数のときも、以下の各手順を奏者単位でそのまま適用する。

## ペインの起動（奏者ごと・遅延）

ある奏者への最初の委譲が発生した時点で、その奏者のペインを起動する:

1. `herdr pane list` で **Claude ペイン ID**（フォーカス中の自ペイン）を取得する。以後、全ブリーフの push 先として記載する。
2. 分割から入力待ちの確認までを**単一の Bash 実行**で回す。`<>` は実値に置換する: `<mode>` は SKILL.md の `--sandbox`、`<プロジェクトルート>` は SKILL.md の cwd 規定（全奏者ともプロジェクトルート）、`<policy>` / `<裁定者>` は SKILL.md の `--approval` / `--reviewer` に従い、`--model` / `--effort` は指定時のみ codex コマンドへ付加する。承認の未指定時の既定は `on-request` + `auto_review` — 承認要求（sandbox 昇格・MCP ツール承認等）を codex のリスク評価サブエージェントに裁定させる公式機構で、無人運用の成立要件。`never` は承認要求を裁定に乗せないため、cwd 外への書き込みが「writing outside of the project」として自動拒否され、承認必須の MCP ツール等はペインのダイアログでブロックする:

   ```sh
   CODEX_PANE=$(herdr pane split "<ClaudeペインID>" --direction right --no-focus \
     | sed -n 's/.*"pane_id"[[:space:]]*:[[:space:]]*"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/p' | head -n1)
   [ -n "$CODEX_PANE" ] || { echo "pane split の応答から pane_id を取得できない"; exit 1; }
   herdr pane run "$CODEX_PANE" "codex --sandbox <mode> -c approval_policy=<policy> -c approvals_reviewer=<裁定者> -C '<プロジェクトルート>'" \
     || { echo "codex 起動コマンドの送出に失敗"; exit 1; }
   if herdr pane wait-output "$CODEX_PANE" --match "Do you trust" --timeout 15000; then
     herdr pane send-text "$CODEX_PANE" "1" && sleep 1 && herdr pane send-keys "$CODEX_PANE" Enter
   fi
   herdr agent wait "$CODEX_PANE" --until idle --timeout 60000
   echo "CODEX_PANE=$CODEX_PANE"
   ```

   - **コマンド形の事前判別**: 確定待ちのコマンドは herdr のバージョンで体系が変わる（herdr 0.7 系は `herdr pane wait-output` / `herdr agent wait --until <status>`。それ以前は `herdr wait output` / `herdr wait agent-status --status <status>`）。セッション最初の起動の前に `herdr pane wait-output --help` の成否でコマンド形を判別し、通らない場合は `herdr --help` / `herdr pane --help` で相当コマンドを特定して以降の全手順を読み替える（`unknown command` のまま進めると、起動確認だけが静かに失敗して「起動したのに観測できない」状態になる）。
   - **trust ダイアログの確定待ち**（`if` ブロック）: codex の TUI は、cwd の trust が `~/.codex/config.toml` に未記録だと、git リポジトリでも初回起動時に trust ダイアログ（"Do you trust the contents of this directory?"）を出す。確定待ちがマッチしたら「Yes, continue」（`1` + Enter）で通過する。この Yes は config.toml にプロジェクトの `trust_level = "trusted"` を永続記録するが、cwd はユーザーが既に作業対象にしているプロジェクトのため許容する。確定待ちのタイムアウト（= ダイアログなし。trust 記録済みの場合）は正常分岐で、そのまま idle の確定待ちへ進む。Yes 送信後にダイアログが残った場合（Enter がペースト処理に吸収された等）でも idle の確定待ちは成功しうるが、続く委譲の手順 3（working 未遷移 → pane read の二分）で捕捉される。
   - 以後の起動では `if` ブロックを省いてよい。省けるのは、**このセッションで同一プロジェクトの Yes 通過、またはダイアログなしの起動成功を観測済みの場合のみ**（= trust 記録済み） — agent-status の idle は trust ダイアログ表示中にも報告されるため、未 trust のまま省くとダイアログが残ったまま起動完了と誤認する。
   - 末尾の idle 確定待ちが 60 秒でタイムアウトしたら、`herdr pane read "$CODEX_PANE" --source visible --lines 20` で画面を読み、原因（予期せぬダイアログ・起動失敗等）を特定してから対処する。
3. `echo` された `CODEX_PANE` の値を、**奏者ラベル→ペイン ID の対応表**（セッション内で保持）に記録する（以下、当該奏者のペイン ID を `$CODEX_PANE` と表記する）。

完了条件: 当該奏者の codex が入力待ち（idle）に達し、対応表に記録済み。

## タスクの委譲

1. ブリーフを当該奏者の成果物置き場 `.concertino/<奏者ラベル>/`（SKILL.md の `--sandbox` 規定）にファイルとして書く。報告書パスも同じ成果物置き場の配下で指定する。末尾に次のブロックを**一字一句そのままコピー**し、`<>` 内だけ実値に置換する:

   BEGIN-通信規約（ブリーフ末尾へコピー）
   - 完了したら: 本ブリーフに定めた報告フォーマットに従う報告書を <報告書パス> に書き、次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex <奏者ラベル>] done <報告書パス>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - 不明点で作業を続けられないときは、作業を止めて次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex <奏者ラベル>] question: <一行の質問>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - herdr コマンドが失敗した場合（Operation not permitted 等）: 報告書はそのままに、上記と同じ一行（`[codex <奏者ラベル>] done <報告書パス>` または `[codex <奏者ラベル>] question: <一行の質問>`）を最終メッセージとして出力して終了する
   - git のコミット・stash・ブランチ作成はしない。変更は作業ツリーに残す。
   END-通信規約

2. 送信から受理の確定待ちまでを単一の Bash 実行で回す。ペインへ送るのは起動指示の一行だけで、テキストと Enter は別コマンドに分けて間を置く（同一バーストで届いた Enter はペースト処理に吸収される）:
   ```sh
   herdr pane send-text "$CODEX_PANE" "<ブリーフ絶対パス> を読んで実行せよ" \
     && sleep 1 && herdr pane send-keys "$CODEX_PANE" Enter \
     && herdr agent wait "$CODEX_PANE" --until working --timeout 15000
   ```
   受理完了の条件は2つ: 終了コード 0（working への遷移）に加え、応答 JSON の agent に `agent_session`（codex セッション ID）が含まれていること。working でも `agent_session` が無ければ、TUI 初期化中の描画を working と誤検知した空振り（送ったテキストは破棄済み）とみなし、受理としない。
3. 受理完了にならなければ（working 未遷移、または `agent_session` 無しの working）`herdr pane read "$CODEX_PANE" --lines 40` で入力欄を見て二分する:
   - 指示テキストが入力欄に残っている → Enter のみ再送する
   - 入力欄が空 → 手順 2 からやり直す（agent-status の idle は入力受付可能より先に報告されることがあり、TUI 初期化中に送ったテキストは丸ごと捨てられる）

   再送・やり直しは当該奏者につき合計 2 回まで。それでも受理完了にならなければ、SKILL.md の失敗規律に従い当該奏者のタスクを終了する（`herdr pane read` の内容を原因分析に添える）。
4. **pull 安全網**を奏者ごとに仕掛ける: `herdr agent wait "$CODEX_PANE" --timeout 1800000` を Bash の `run_in_background` で起動する（`--until` 無し = idle / done / blocked のいずれかで発火。codex の TUI は完了後 idle に戻るだけで done を報告しないことがあり、`--until done` に絞ると完了を取り逃がしてタイムアウトする）。安全網は手順 2 の受理完了の確認後に張る（agent-status は画面からの推定であり、受理前の無活動ペインは done と誤検知され即発火する）。

完了条件: 委譲した全奏者について、受理完了の確認と安全網の起動が済んでいる。

## 応答の受け取り

push の `[codex <奏者ラベル>]` で発信元の奏者を特定してから処理する:

- **`[codex <奏者ラベル>] done <パス>`** が届いたら報告書を読む。報告書を読まずに検収しない。
- **`[codex <奏者ラベル>] question: ...`** が届いたら、回答を当該奏者のペインへ `herdr pane send-text "$CODEX_PANE" "<回答>"` に続けて `herdr pane send-keys "$CODEX_PANE" Enter` で送る。補足が長くなる場合はファイルに書いてパスを送る。
- **安全網が先に発火**したら当該奏者のペインを `herdr pane read "$CODEX_PANE" --source recent-unwrapped --lines 60` で読み、状況を二分する:
  - まだ作業中（working）→ 安全網を張り直して待機を延長する。延長は奏者ごとに1回まで。2回目の発火はユーザーに相談する。
  - done / idle なのに push が無い → pane read の内容と報告書パスの有無から結果を直接回収する（push 漏れ・送信不能フォールバックは回収漏れであり、失敗規律の「失敗」に数えない）。

完了条件: 委譲した全奏者について、報告書（または直接回収した結果）を読み終えている。

## ペイン ID の揮発性

herdr の ID はペイン増減で振り直される。ペインを増減させる操作（起動・クローズ）を行ったら、直後に `herdr pane list` を取って対応表を更新する。`pane close` / `pane run` / `pane send-text` / `pane send-keys`（send-text と一体の送信は一式で1回）の直前は `herdr pane list` で ID を取り直す — 複数ペインでは、古い ID への送信が**別の奏者**を撃つ事故になる。取り直しで当該奏者のペインを特定できないときは、送信せずユーザーに確認する。

## クローズ

次の3条件が**当該奏者について**揃ったらそのペインを閉じる:

1. 未着手・未検収の委譲タスクが残っていない
2. その奏者からの未回収の push が無い
3. 作業ツリーの状態を把握済み（閉じた後に奏者へ聞き直すことはできない）

`herdr pane list` で ID を取り直してから `herdr pane close` し、対応表から除く。あわせて当該奏者の成果物置き場 `.concertino/<奏者ラベル>/` を、SKILL.md の `--sandbox` 規定の後始末に従って削除する。配役解除時は全奏者分を同様に閉じ、後始末を完了させる。新しい委譲が後から発生したら、ペインの起動（奏者ごと・遅延）を再度実行する（新しい codex セッションになる）。

完了条件: 閉じた奏者のペインが `herdr pane list` に存在しないことと、当該奏者の `.concertino/<奏者ラベル>/` が削除済みであることを確認した。
