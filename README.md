# mc_translate
Minecraft Java 版の Mod を、AI を使って日本語翻訳リソースパックを作るためのコードです。

[cache](/cache) ディレクトリに、私が AI で生成した日本語翻訳リソースパックがあります。

# 使用方法 (Windows)

[app_start.bat](windows/app_start.bat) をダウンロードして、適当なディレクトリに入れて実行します。

![image](https://github.com/user-attachments/assets/aecda3f5-e108-4db7-8a95-0863de3fce0c)

リンククリック後、画面右上のこのボタンでダウンロード出来ます。

app_start.bat を実行すると、実行したフォルダ上にファイルをダウンロードするので、適当な名前のフォルダを作ってその中で実行してください。

実行すると以下のように自動的に Python やらをダウンロードして、mc_translate をダウンロードして実行してくれます。

![image](https://github.com/user-attachments/assets/045ea1e7-96dc-40ac-9169-47d6d661c1d8)

この画面の最後の

![image](https://github.com/user-attachments/assets/175d800c-d947-4bc1-90fb-d345cb5f2eac)

https ～～～ の URL を、Ctrl ＋ クリックで、アプリの画面が開きます。

![image](https://github.com/user-attachments/assets/d06f6e75-6447-474b-8d4e-0eafd3356e99)

翻訳には OpenAI を使用しているので OpenAI の API キーが必要です。

[OpenAI API](https://platform.openai.com/api-keys)

API キーを取得した後、は入力して保存ボタンを押します。

![image](https://github.com/user-attachments/assets/dba28eb8-d2a3-4bcf-ad3a-c5f86d567301)

MOD 翻訳　→　インスタンスタイプ　→　インスタンス　を選択し、翻訳開始をクリックします。

[OpenAI のサイト](https://platform.openai.com/batches) で、翻訳の進捗が見えます。

![image](https://github.com/user-attachments/assets/1e621e14-afec-473f-8dfd-9ab114c32cde)

Status が Completed になっていれば完了です。

再度、MOD 翻訳　→　インスタンスタイプ　→　インスタンス　を選択し、翻訳開始をクリックします。

すると、自動的に OpenAI 側から翻訳結果をダウンロードして、日本語化リソースパックを作成して、インスタンスのリソースパックフォルダに保存します。

Microsoft のゲームを起動します。

![image](https://github.com/user-attachments/assets/8dd3e223-eb7a-41e2-89d7-fb38bd26b983)

all_in_one_インスタンス名_jp というリソースパックが見えるので、それを追加します。

![image](https://github.com/user-attachments/assets/d8d83a2b-d8df-4941-9d22-bf8d1d8aa327)

本当に大丈夫なんか？と聞かれますが、ハイを押し、完了を押します。

今まで英語だった Mod が日本語化されます。ただし、意訳というよりは、AI が直訳しているので、不正確な翻訳がふくまれるかもしれません。

![image](https://github.com/user-attachments/assets/03a53f64-3fb8-4a4e-b749-9725e6e8d63f)



# 翻訳について

翻訳では API 費用の削減のためにバッチ処理を採用しており、いつ終わるかは分かりません。

- スクリプトを実行すると自動的に翻訳が必要な Mod を調査して OpenAI にバッチ処理を依頼
- 再度翻訳処理を実行すると、バッチ処理の状況を確認
- 翻訳が完了していればリソースパックをインスタンスフォルダの resourcepack フォルダに作成
- Minecraft 上でリソースパックを読み込むように設定する

これにより翻訳が完了します。

もし既に翻訳済みのリソースパックが cache ディレクトリにあれば、それを自動的にコピーします。

# バッチ処理について

OpenAI のバッチ処理は、AI の API 費用を大きく減らす事の出来る機能です。

バッチ処理の状況は、OpenAI のサイトにログインした上で [ここ](https://platform.openai.com/batches) を見ると確認出来ます。

何件中何件が完了したかが分かります。

バッチ処理の AI には「gpt-4o-mini-2024-07-18」を使用しています。これは単純に API 費用をケチるためですが、必要に応じてより上位モデルにすると、翻訳結果が良くなるかもしれません。

# 翻訳されない Mod について

まだ調査中ですが、たまに翻訳されない Mod があります。

たぶんコードに直接書かれていたり、リソースパックで翻訳出来ないような位置に書かれていると、このスクリプトでは翻訳出来ません。
