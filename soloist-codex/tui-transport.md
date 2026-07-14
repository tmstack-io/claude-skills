# TUI 輸送路 — herdr ペインの codex と協働する

ペインの codex は観戦・介入できるソリストである。原則は「**ペイロードはファイル、ペインは信号**」— 長文をペインに流し込まない。

## ペインの起動（遅延）

最初の配役タスクが発生した時点で起動する:

1. `herdr pane list` で **Claude ペイン ID**（フォーカス中の自ペイン）を取得する。以後、全ブリーフの push 先として記載する。
2. 自ペインを分割し、応答 JSON の `result.pane.pane_id` を新ペイン ID（以下 `$CODEX_PANE`）として読み取る:
   ```sh
   herdr pane split <ClaudeペインID> --direction right --no-focus
   ```
3. codex を起動する（`--model` / `--effort` は指定時のみ付加）:
   ```sh
   herdr pane run "$CODEX_PANE" "codex --sandbox <mode> -a never -C <プロジェクトルート>"
   ```
4. `herdr wait agent-status "$CODEX_PANE" --status idle --timeout 60000` で入力待ちを確認する。

完了条件: codex が入力待ち（idle）に達したことを確認した。

## タスクの委譲

1. ブリーフを一時領域のファイルに書く。末尾に次のブロックを**一字一句そのままコピー**し、`<>` 内だけ実値に置換する:

   BEGIN-通信規約（ブリーフ末尾へコピー）
   - 完了したら: 本ブリーフに定めた報告フォーマットに従う報告書を <報告書パス> に書き、次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex] done <報告書パス>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - 不明点で作業を続けられないときは、作業を止めて次を実行する:
     `herdr pane send-text <ClaudeペインID> "[codex] question: <一行の質問>"` に続けて `herdr pane send-keys <ClaudeペインID> Enter`
   - git のコミット・stash・ブランチ作成はしない。変更は作業ツリーに残す。
   END-通信規約

2. ペインへは起動指示の一行だけを送る: `herdr pane run "$CODEX_PANE" "<ブリーフ絶対パス> を読んで実行せよ"`
3. **pull 安全網**を仕掛ける: `herdr wait agent-status "$CODEX_PANE" --status done --timeout 1800000` を Bash の `run_in_background` で起動する。

完了条件: ブリーフ送付と安全網起動の両方が済んでいる。

## 応答の受け取り

- **`[codex] done <パス>`** が届いたら報告書を読む。報告書を読まずに検収しない。
- **`[codex] question: ...`** が届いたら、回答を `herdr pane send-text "$CODEX_PANE" "<回答>"` に続けて `herdr pane send-keys "$CODEX_PANE" Enter` でペインへ送る。補足が長くなる場合はファイルに書いてパスを送る。
- **安全網が先に発火**したら `herdr pane read "$CODEX_PANE" --source recent-unwrapped --lines 60` で状況を二分する:
  - まだ作業中（working）→ 安全網を張り直して待機を延長する。延長は1回まで。2回目の発火はユーザーに相談する。
  - done / idle なのに push が無い → pane read の内容と報告書パスの有無から結果を直接回収する（push 漏れは回収漏れであり、失敗規律の「失敗」に数えない）。

完了条件: 報告書（または直接回収した結果）を読み終えている。

## ペイン ID の揮発性

herdr の ID はペイン増減で振り直される。`pane close` / `pane run` / `pane send-text` の直前は `herdr pane list` で ID を取り直す（古い ID への送信は無関係なペインを撃つ事故になる）。

## クローズ

次の3条件が揃ったらペインを閉じる:

1. 未着手・未検収の配役タスクが残っていない
2. codex からの未回収の push が無い
3. 作業ツリーの状態を把握済み（閉じた後に codex へ聞き直すことはできない）

`herdr pane list` で ID を取り直してから `herdr pane close`。配役解除時にペインが残っていれば同様に閉じる。新しい配役タスクが後から発生したら、ペインの起動（遅延）を再度実行する（新しい codex セッションになる）。

完了条件: `herdr pane list` にペインが存在しないことを確認した。
