import os
import zipfile
import json
import pickle
import tempfile
from pathlib import Path
from json_repair import loads
from openai import OpenAI
import shutil

from dotenv import load_dotenv
load_dotenv()


# OpenAI クライアントの初期化
client = OpenAI()

resource_packs = []


def extract_nested_jars(jar_path, temp_dir):
    """
    JARファイル内のネストされたJARファイルを抽出する
    戻り値: 抽出されたJARファイルのパスのリスト
    """
    nested_jars = []
    
    try:
        with zipfile.ZipFile(jar_path, 'r') as jar:
            # META-INF/jars/ 内のJARファイルを探す
            jar_files = [f for f in jar.namelist() if f.startswith('META-INF/jars/') and f.endswith('.jar')]
            
            for jar_file in jar_files:
                # 一時ディレクトリに抽出
                jar.extract(jar_file, temp_dir)
                extracted_path = os.path.join(temp_dir, jar_file)
                nested_jars.append(extracted_path)
                
    except Exception as e:
        print(f"警告: ネストされたJARファイルの抽出中にエラーが発生しました: {str(e)}")
    
    return nested_jars

def check_mod_language(jar_path):
    """
    MODの言語ファイルをチェックする
    戻り値: 
        0: 日本語化済み
        1: 英語のみ
        2: その他
    """
    try:
        # 一時ディレクトリを作成
        with tempfile.TemporaryDirectory() as temp_dir:
            # メインのJARファイルをチェック
            result = check_jar_language(jar_path)
            if result != 2:  # 日本語化済みまたは英語のみの場合
                return result
                
            # ネストされたJARファイルを抽出してチェック
            nested_jars = extract_nested_jars(jar_path, temp_dir)
            for nested_jar in nested_jars:
                result = check_jar_language(nested_jar)
                if result == 1:  # 英語のみのファイルが見つかった
                    return 1
                elif result == 0:  # 日本語化済みのファイルが見つかった
                    return 0
            
            return 2  # すべてのチェックで該当なし
            
    except Exception as e:
        print(f"エラー: {os.path.basename(jar_path)} の処理中にエラーが発生しました: {str(e)}")
        return 2

def check_jar_language(jar_path):
    global mod_jp_cache
    """
    単一のJARファイルの言語ファイルをチェックする
    """
    try:
        with zipfile.ZipFile(jar_path, 'r') as jar:
            # すべてのファイルリストを取得
            files = jar.namelist()
            
            # assets/*/lang/ パターンに一致するパスを探す
            lang_paths = [f for f in files if '/lang/' in f]
            
            # 日本語ファイルの確認
            jp_files = [f for f in lang_paths if f.endswith('ja_jp.json')]
            if jp_files:
                result = {}
                for jp_file in jp_files:
                    with jar.open(jp_file) as f:
                        data = f.read().decode('utf-8')
                        result[jp_file] = data
                mod_jp_cache[jar_path] = result
                return 0  # 日本語化済み
            
            # 英語ファイルの確認
            en_files = [f for f in lang_paths if f.endswith('en_us.json')]
            if en_files:
                return 1  # 英語のみ
            
            return 2  # その他
            
    except zipfile.BadZipFile:
        print(f"警告: {os.path.basename(jar_path)} は不正なZIPファイルです")
        return 2
    except Exception as e:
        print(f"エラー: {os.path.basename(jar_path)} の処理中にエラーが発生しました: {str(e)}")
        return 2

def create_translation_batch(jar_path, en_data, mod_name):
    """翻訳バッチリクエストを作成する"""
    jsonl_data = []
    
    # テンプレート
    batch_template = {
        "custom_id": "request-", 
        "method": "POST",
        "url": "/v1/chat/completions", 
        "body": {
            "model": "gpt-4o-mini-2024-07-18", 
            "messages": [
                {
                    "role": "system",
                    "content": """日本語のリソースパックを作成しています。
以下の英文のリソースパックを日本語に翻訳して。
英文に Java の Format 文字列（%s や %2$s）が含まれる場合、それは翻訳せずに適切な位置に移動してください。
翻訳したJSON のみ出力してコメントや補足は出力しないでください。"""
                },
                {"role": "user", "content": ""}
            ],
            "max_tokens": 2048
        }
    }

    # 50件ずつ分割して翻訳リクエストを作成
    items = list(en_data.items())
    for i in range(0, len(items), 50):
        batch = dict(items[i:i+50])
        
        batch_request = batch_template.copy()
        batch_request["custom_id"] = mod_name + str(i)
        batch_request["body"]["messages"][1]["content"] = f"```json\n{json.dumps(batch, indent=2, ensure_ascii=False)}\n```"
        
        json_str = json.dumps(batch_request, ensure_ascii=False)
        jsonl_data.append(json_str)
    
    return jsonl_data

mod_jp_cache = {}

def create_resource_pack(jar_path, translated_data, mod_name, resource_pack_path, cache_dir):
    """リソースパックを作成する"""
    zip_path = os.path.join(resource_pack_path, f"{mod_name}_jp.zip")

    if os.path.exists(zip_path):
        print(f"警告: {os.path.basename(zip_path)} は既に存在します")
        return
    
    pack_mcmeta = {
        "pack": {
            "description": f"{mod_name} Japanese Translation",
            "pack_format": 34
        }
    }
    
    # ZIPファイル作成
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        # pack.mcmeta
        zf.writestr('pack.mcmeta', json.dumps(pack_mcmeta, indent=4, ensure_ascii=False))
        
        # 言語ファイル
        # MODのアセットパスを取得
        with zipfile.ZipFile(jar_path, 'r') as jar:
            # メインのJARファイルとネストされたJARファイルの両方をチェック
            with tempfile.TemporaryDirectory() as temp_dir:
                en_file = None
                
                # メインのJARファイルをチェック
                en_files = [f for f in jar.namelist() if f.endswith('en_us.json')]
                if en_files:
                    en_file = en_files[0]
                else:
                    # ネストされたJARファイルをチェック
                    nested_jars = extract_nested_jars(jar_path, temp_dir)
                    for nested_jar in nested_jars:
                        with zipfile.ZipFile(nested_jar, 'r') as nested:
                            en_files = [f for f in nested.namelist() if f.endswith('en_us.json')]
                            if en_files:
                                en_file = en_files[0]
                                break
                
                if not en_file:
                    raise Exception("英語ファイルが見つかりません")
                    
                asset_path = os.path.dirname(os.path.dirname(en_file))
            
        # 日本語ファイルのパス
        jp_path = f"{asset_path}/lang/ja_jp.json"
        
        # 日本語ファイルを追加
        zf.writestr(jp_path, json.dumps(translated_data, indent=4, ensure_ascii=False))
        
    shutil.copy(zip_path, os.path.join(cache_dir, f"{mod_name}_jp.zip"))
    
    global resource_packs
    resource_packs.append(zip_path)

    print(f"リソースパック作成完了: {zip_path}")

def process_batch_results(batch_results, jar_path, mod_name, resource_pack_path, cache_dir):
    """バッチ処理結果を処理してリソースパックを作成する"""
    translated_data = {}
    
    for result in batch_results:
        if not result["custom_id"].startswith(mod_name):
            continue
            
        if "response" not in result or "body" not in result["response"]:
            print(f"警告: 不正な結果形式: {result}")
            continue
            
        try:
            content = result["response"]["body"]["choices"][0]["message"]["content"]
            translated_batch = loads(content.replace("```json", "").replace("```", "").strip())
            translated_data.update(translated_batch)
        except Exception as e:
            print(f"警告: 翻訳結果の解析に失敗: {str(e)}")
            continue
    
    if translated_data:
        create_resource_pack(jar_path, translated_data, mod_name, resource_pack_path, cache_dir)
        return True
    return False

def main(modpack_name="Our Story Earth"):
    # パスの設定
    userprofile = os.environ.get("USERPROFILE")
    instance_path = os.path.join(userprofile, r"curseforge\minecraft\Instances", modpack_name)
    mods_path = os.path.join(instance_path, "mods")
    resource_pack_path = os.path.join(instance_path, "resourcepacks")
    
    global resource_packs
    resource_packs = []

    batch_id_file = "batch_id.txt"
    cache = {}
    
    # バッチIDの読み込み
    batch_id = None
    if os.path.exists(batch_id_file):
        with open(batch_id_file, "r") as f:
            batch_id = f.read().strip()
    
    cache_dir = "cache"
    if not os.path.exists(cache_dir):
        os.mkdir(cache_dir)
    
    
    
    # MODの言語状態をチェック
    print("=== MODの言語状態をチェック中 ===")
    en_mods = []
    for file in os.listdir(mods_path):
        if not file.endswith('.jar'):
            continue
            
        jar_path = os.path.join(mods_path, file)
        mod_name = os.path.splitext(file)[0]
        zip_path = os.path.join(resource_pack_path, f"{mod_name}_jp.zip")
        
        if os.path.exists(zip_path):
            resource_packs.append(zip_path)
            continue
            
        cache_name = os.path.join(cache_dir, f"{mod_name}_jp.zip")
        if os.path.exists(cache_name):
            shutil.copy(cache_name, zip_path)
            print(f"リソースパックのキャッシュを利用: {zip_path}")
            resource_packs.append(zip_path)
            continue
        
        if file in cache:
            result = cache[file]
        else:
            result = check_mod_language(jar_path)
            cache[file] = result
        
        if result == 1:  # 英語のみ
            en_mods.append(file)
    
    if not en_mods:
        print("翻訳が必要なMODは見つかりませんでした")
        return
    
    print(f"\n=== 英語のみのMOD: {len(en_mods)}個 ===")
    for mod in en_mods:
        print(f"- {mod}")
    
    # バッチ処理の状態チェックと実行
    if batch_id:
        print(f"\n=== バッチ処理の状態をチェック中 (ID: {batch_id}) ===")
        batch = client.batches.retrieve(batch_id)
        
        if batch.status == "completed":
            print("バッチ処理が完了しました")
            
            # 結果の取得と保存
            file_response = client.files.content(batch.output_file_id)
            results = [json.loads(line) for line in file_response.text.strip().split("\n")]
            
            # リソースパックの作成
            print("\n=== リソースパックの作成中 ===")
            for file in en_mods:
                jar_path = os.path.join(mods_path, file)
                mod_name = os.path.splitext(file)[0]
                if process_batch_results(results, jar_path, mod_name, resource_pack_path, cache_dir):
                    cache[file] = 0  # 日本語化済みとしてマーク
            
            # バッチIDの削除
            os.remove(batch_id_file)
            print("\n=== 処理が完了しました ===")
            
        elif batch.status in ["failed", "expired"]:
            print(f"バッチ処理が失敗しました: {batch.status}")
            os.remove(batch_id_file)  # 失敗したバッチIDを削除
            
        else:
            print(f"バッチ処理は現在 {batch.status} 状態です")
            return
    
    # 新しいバッチの作成
    if not batch_id or batch.status in ["failed", "expired"]:
        print("\n=== 新しい翻訳バッチを作成中 ===")
        all_requests = []
        
        for file in en_mods:
            jar_path = os.path.join(mods_path, file)
            mod_name = os.path.splitext(file)[0]
            
            try:
                with tempfile.TemporaryDirectory() as temp_dir:
                    en_file_content = None
                    en_file_path = None
                    
                    # メインのJARファイルをチェック
                    with zipfile.ZipFile(jar_path, 'r') as jar:
                        en_files = [f for f in jar.namelist() if f.endswith('en_us.json')]
                        if en_files:
                            en_file_content = jar.read(en_files[0]).decode('utf-8')
                            en_file_path = en_files[0]
                        else:
                            # ネストされたJARファイルをチェック
                            nested_jars = extract_nested_jars(jar_path, temp_dir)
                            for nested_jar in nested_jars:
                                with zipfile.ZipFile(nested_jar, 'r') as nested:
                                    en_files = [f for f in nested.namelist() if f.endswith('en_us.json')]
                                    if en_files:
                                        en_file_content = nested.read(en_files[0]).decode('utf-8')
                                        en_file_path = en_files[0]
                                        break
                    
                    if not en_file_content:
                        print(f"警告: {file} に英語ファイルが見つかりません")
                        continue
                    
                    print(f"デバッグ - {file} の英語ファイルパス: {en_file_path}")
                    print(f"デバッグ - ファイル内容の一部: {en_file_content[:200]}...")
                    
                    en_data = loads(en_file_content)
                    if not en_data:
                        print(f"警告: {file} の英語ファイルが空です")
                        continue
                    
                    print(f"デバッグ - 読み込んだデータ: {dict(list(en_data.items())[:2])}...")
                    
                    requests = create_translation_batch(jar_path, en_data, mod_name)
                    all_requests.extend(requests)
                    print(f"- {file} の翻訳リクエストを作成しました")
                    
            except Exception as e:
                print(f"エラー: {file} の処理中にエラーが発生しました: {str(e)}")
                continue
        
        if all_requests:
            # バッチファイルの作成
            with open("batch.jsonl", "w", encoding="utf-8") as f:
                f.write("\n".join(all_requests))
            
            # バッチの作成
            batch_input_file = client.files.create(
                file=open("batch.jsonl", "rb"),
                purpose="batch"
            )
            
            batch_result = client.batches.create(
                input_file_id=batch_input_file.id,
                endpoint="/v1/chat/completions",
                completion_window="24h",
                metadata={
                    "description": "Minecraft MOD translation batch"
                }
            )
            
            # バッチIDの保存
            with open(batch_id_file, "w") as f:
                f.write(batch_result.id)
            
            print(f"\nバッチを作成しました (ID: {batch_result.id})")
            print("次回の実行時に翻訳結果を確認します")
    
    # all in one resourcepack
    all_in_one_pack_path = os.path.join(resource_pack_path, f"all_in_one_{modpack_name}_jp.zip")
    pack_mcmeta = {
        "pack": {
            "description": f"{modpack_name} Japanese Translation",
            "pack_format": 34
        }
    }
    with zipfile.ZipFile(all_in_one_pack_path, 'w', zipfile.ZIP_DEFLATED) as zfout:
        zfout.writestr('pack.mcmeta', json.dumps(pack_mcmeta, indent=4, ensure_ascii=False))
        for i, pack in enumerate(resource_packs):
            with zipfile.ZipFile(pack, 'r') as zfin:
                for file in zfin.namelist():
                    if file.endswith(".json"):
                        data = zfin.read(file).decode('utf-8')
                        zfout.writestr(file, data)
                        print(f"Added {file} to all_in_one pack (1)")
        for mod_name, mod_langs in mod_jp_cache.items():
            for lang_file, data in mod_langs.items():
                zfout.writestr(lang_file, data)
                print(f"Added {lang_file} to all_in_one pack (2)")

if __name__ == "__main__":
    main("Prodigium Reforged (Terraria Pack)")
