# TUI 輸送路 — herdr ペインの奏者と協働する

ペインの奏者（codex）は観戦・介入できる。原則は「**ペイロードはファイル、ペインは信号**」— 長文をペインに流し込まない。奏者が複数のときも、以下の各手順を奏者単位でそのまま適用する。

## ペインの起動（奏者ごと・遅延）

ある奏者への最初の委譲が発生した時点で、その奏者のペインを起動する:

1. `herdr pane list` で **Claude ペイン ID**（フォーカス中の自ペイン）を取得する。以後、全ブリーフの push 先として記載する。
2. 自ペインを分割し、応答 JSON の `result.pane.pane_id` を当該奏者のペイン ID として、**奏者ラベル→ペイン ID の対応表**（セッション内で保持）に記録する（以下、当該奏者のペイン ID を `$CODEX_PANE` と表記する）:
   ```sh
   herdr pane split <ClaudeペインID> --direction right --no-focus
   ```
3. codex を起動する（`--model` / `--effort` は指定時のみ付加。`<作業ディレクトリ>` は SKILL.md の cwd 分離規定に従う）:
   ```sh
   herdr pane run "$CODEX_PANE" "codex --sandbox <mode> -a never -C <作業ディレクトリ>"
   ```
4. `herdr wait agent-status "$CODEX_PANE" --status idle --timeout 60000` で入力待ちを確認する。

完了条件: 当該奏者の codex が入力待ち（idle）に達し、対応表に記録済み。

## タスクの委譲

1. ブリーフを一時領域のファイルに書く（ファイル名に奏者ラベルを含める）。末尾に次のブロックを**一字一句そのままコピー**し、`<>` 内だけ実値に置換する:

   BEGIN-通信規約（ブリーフ末尾へコピー）
   - 完了したら: 本ブリーフに定めた報告フォーマットに従う報告書を <報告書パス> に書き、次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex <奏者ラベル>] done <報告書パス>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - 不明点で作業を続けられないときは、作業を止めて次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex <奏者ラベル>] question: <一行の質問>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - herdr コマンドが失敗した場合（Operation not permitted 等）: 報告書はそのままに、上記と同じ一行（`[codex <奏者ラベル>] done <報告書パス>` または `[codex <奏者ラベル>] question: <一行の質問>`）を最終メッセージとして出力して終了する
   - git のコミット・stash・ブランチ作成はしない。変更は作業ツリーに残す。
   END-通信規約

2. 当該奏者のペインへは起動指示の一行だけを送る: `herdr pane run "$CODEX_PANE" "<ブリーフ絶対パス> を読んで実行せよ"`
3. **pull 安全網**を奏者ごとに仕掛ける: `herdr wait agent-status "$CODEX_PANE" --status done --timeout 1800000` を Bash の `run_in_background` で起動する。

完了条件: ブリーフ送付と安全網起動の両方が、委譲した全奏者について済んでいる。

## 応答の受け取り

push の `[codex <奏者ラベル>]` で発信元の奏者を特定してから処理する:

- **`[codex <奏者ラベル>] done <パス>`** が届いたら報告書を読む。報告書を読まずに検収しない。
- **`[codex <奏者ラベル>] question: ...`** が届いたら、回答を当該奏者のペインへ `herdr pane send-text "$CODEX_PANE" "<回答>"` に続けて `herdr pane send-keys "$CODEX_PANE" Enter` で送る。補足が長くなる場合はファイルに書いてパスを送る。
- **安全網が先に発火**したら当該奏者のペインを `herdr pane read "$CODEX_PANE" --source recent-unwrapped --lines 60` で読み、状況を二分する:
  - まだ作業中（working）→ 安全網を張り直して待機を延長する。延長は奏者ごとに1回まで。2回目の発火はユーザーに相談する。
  - done / idle なのに push が無い → pane read の内容と報告書パスの有無から結果を直接回収する（push 漏れ・送信不能フォールバックは回収漏れであり、失敗規律の「失敗」に数えない）。

完了条件: 委譲した全奏者について、報告書（または直接回収した結果）を読み終えている。

## ペイン ID の揮発性

herdr の ID はペイン増減で振り直される。ペインを増減させる操作（起動・クローズ）を行ったら、直後に `herdr pane list` を取って対応表を更新する。`pane close` / `pane run` / `pane send-text` の直前は `herdr pane list` で ID を取り直す — 複数ペインでは、古い ID への送信が**別の奏者**を撃つ事故になる。取り直しで当該奏者のペインを特定できないときは、送信せずユーザーに確認する。

## クローズ

次の3条件が**当該奏者について**揃ったらそのペインを閉じる:

1. 未着手・未検収の委譲タスクが残っていない
2. その奏者からの未回収の push が無い
3. 作業ツリーの状態を把握済み（閉じた後に奏者へ聞き直すことはできない）

`herdr pane list` で ID を取り直してから `herdr pane close` し、対応表から除く。配役解除時は全奏者分を同様に閉じる。新しい委譲が後から発生したら、ペインの起動（奏者ごと・遅延）を再度実行する（新しい codex セッションになる）。

完了条件: 閉じた奏者のペインが `herdr pane list` に存在しないことを確認した。
