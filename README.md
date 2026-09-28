<!-- markdownlint-disable MD033 MD045 MD013 -->
<p align="center">
  <img src="assets/back.png" width="100%" alt="Slotty">
</p>

<h1 align="center">Slotty</h1>

<p align="center">
  <strong>時間枠（スロット）にタスクをセットして集中する、シンプルなTodo＆タイマーアプリ</strong>
</p>

<p align="center">
  <a href="https://github.com/kmcahfne/slotty/releases/latest">
    <img src="https://img.shields.io/github/v/release/kmcahfne/slotty?color=blue&label=release" alt="Release" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/kmcahfne/slotty?color=green" alt="License" />
  </a>
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey" alt="Platform" />
</p>

<p align="center">
  <a href="https://skillicons.dev">
    <img src="https://skillicons.dev/icons?i=flutter,dart,apple" alt="Skills" />
  </a>
</p>

---

## 概要

**Slotty** は、30分などの時間枠（スロット）単位で断続的に進めるルーティンワーク（同じタスクを時間を空けて何度も繰り返す作業）を管理するためのデスクトップアプリです。

「次」という専用の概念を持たず、常に**「今このスロットでやるタスク」**を明確に見せることをコアバリューとして設計されています。

## 特徴

- **「今」やるタスクに集中**: 事前にセットしたタスク群を対象にセッションを開始。タスク間の複雑な優先度や順序に悩まされることなく集中に入れます。
- **直感的なワンタップ操作**: タスク行をクリックするだけで「セット / アンセット」を切り替え。セットされたタスクは自動的に上部にグルーピング。
- **5色のカラープリセット**: タスク追加時に識別しやすい5色（みかん、ピーコック、コバルト、バジル、レモン）を選択可能。
- **クイック時間調整**: タイマー横の鉛筆アイコンから、作業時間（分・秒）をその場で自由に編集可能。
- **ローカル自動保存**: タスク一覧や変更した時間はローカルストレージへ自動保存され、アプリ再起動後も状態を維持。
- **セッション完了通知**: カウントダウン終了時にアラーム音でお知らせ。完了と同時にアクティブタスクが自動でアンセットされ、次回のスロットへスムーズに移行。

## インストール（macOS）

1. [最新の Releases ページ](https://github.com/kmcahfne/slotty/releases/latest) から `slotty-macos.dmg` をダウンロードします。
2. ダウンロードした `.dmg` ファイルをダブルクリックして開きます。
3. `Slotty` アイコンを `Applications`（アプリケーション）フォルダへドラッグ＆ドロップします。

<details>
<summary><strong>初回起動時の注意（macOS Gatekeeper 警告について）</strong></summary>

本アプリはオープンソースの未署名バイナリとして配布されているため、初回起動時に「開発元を検証できないため開けません」等の警告が表示される場合があります。

以下の手順で起動を許可してください：

1. Finder で **「アプリケーション」** フォルダを開きます。
2. `Slotty.app` を **Control キーを押しながらクリック（右クリック）** し、メニューから **「開く」** を選択します。
3. 確認ダイアログが表示されたら **「開く」** をクリックします（2回目以降は通常通り起動できます）。

※ ターミナルから以下のコマンドを実行して隔離属性を解除することも可能です：
```bash
xattr -cr /Applications/Slotty.app
```
</details>

## ライセンス

[MIT License](LICENSE)
