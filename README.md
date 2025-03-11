# mc_translate
Minecraft Java 版の Mod を、AI を使って日本語翻訳リソースパックを作るためのコードです。

[cache](/cache) ディレクトリに、私が AI で生成した日本語翻訳リソースパックがあります。

# 使用方法
前提として curseforge で Minecraft をインストールしている事を前提としています。

コードの一番最後

    if __name__ == "__main__":
        main("Prodigium Reforged (Terraria Pack)")

このメイン関数の引数に Modpack のディレクトリ名を入れます。

この名前はインスタンス名というよりは、ただのフォルダ名なので

    %USERPROFILE%\curseforge\minecraft\Instances\

をエクスプローラーなどで見て、翻訳したい Modpack あるいはインスタンスのフォルダ名をコピペします。

また OpenAI の API キーを取得した上で .env ファイルを作成し、

    OPENAI_API_KEY="sk-*****"

というように記載する事で、OpenAI の AI を使って翻訳を依頼します。

# 翻訳について

翻訳では API 費用の削減のためにバッチ処理を採用しており、いつ終わるかは分かりません。

- スクリプトを実行すると自動的に翻訳が必要な Mod を調査して OpenAI にバッチ処理を依頼
- 再度スクリプトを実行すると、バッチ処理の状況を確認
- 翻訳が完了していればリソースパックをインスタンスフォルダの resourcepack フォルダに作成
- Minecraft 上でリソースパックを読み込むように設定する

これにより翻訳が完了します。

もし既に翻訳済みのリソースパックが cache ディレクトリにあれば、それを自動的にコピーします。

