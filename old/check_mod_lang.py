import os
import zipfile
import json
from pathlib import Path
import asyncio
from dotenv import load_dotenv
from chat_assistant import ChatAssistant, ModelManager
from json_repair import loads
import pickle
import time

load_dotenv()

ai = None
retry = 5


def set_ai(model_names:list=None, temperature:float=0.8, retry_count:int=5):
    global ai, retry
    retry = retry_count
    if ai is None:
        if model_names is None:
            model_names = ["openai/local-lmstudio"]
        model_manager = ModelManager(models=model_names, local_fallback=True)
        ai = ChatAssistant(model_manager=model_manager, temperature=temperature)


def chat(prompt:str) -> str:
    if ai is None:
        set_ai()
    
    if ai is None or len(prompt) == 0:
        return ""

    for c in range(retry):
        try:
            return asyncio.run(ai.chat(prompt))
        except Exception as e:
            print(f"Error: {e}")
            print(f"Retry... {c}/{retry}")
            time.sleep(3)

def check_mod_language(jar_path):
    """
    MODの言語ファイルをチェックする
    戻り値: 
        0: 日本語化済み
        1: 英語のみ
        2: その他
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

batch_result = None
jsonl_data = []

def create_resource_pack_batch(mod_path, en_data, mod_name, resource_pack_path):
    global jsonl_data
    """リソースパックを作成する"""
    zip_path = os.path.join(resource_pack_path, f"{mod_name}_jp.zip")

    if os.path.exists(zip_path):
        print(f"警告: {os.path.basename(zip_path)} は既に存在します")
        return

    translated_data = {}
    items = list(en_data.items())
    for i in range(0, len(items), 50):
        batch = dict(items[i:i+50])

        batch_request = batch_template.copy()
        batch_request["custom_id"] = mod_name + str(i)
        batch_request["body"]["messages"][1]["content"] = f"```json\n{json.dumps(batch, indent=2, ensure_ascii=False)}\n```"

        batch_request_custom_id = str(batch_request["custom_id"]).strip()

        translated_result = ""
        batch_result_found = False

        if batch_result:
            for result in batch_result:
                # result data sample:
                # {"id": "batch_req_67b8a9c0ae8c81908ec9172a63cd48f4", "custom_id": "xtraarrows-3.4.2-fabric-mc1.21250", "response": {"status_code": 200, "request_id": "2b8a576919621d0a2c21fc9d696f6be2", "body": {"id": "chatcmpl-B3PPQK5pEoAbAd0bkcLBe5jKJHOan", "object": "chat.completion", "created": 1740152356, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "```json\n{\n  \"xtraarrows.text.soul_lantern_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30e9\u30f3\u30bf\u30f3\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.life_steal_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30e9\u30a4\u30d5\u30b9\u30c6\u30a3\u30fc\u30eb\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.magnetic_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30de\u30b0\u30cd\u30c6\u30a3\u30c3\u30af\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.breeding_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u7e41\u6b96\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.cupids_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ad\u30e5\u30fc\u30d4\u30c3\u30c9\u306e\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.golden_apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u91d1\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.enchanted_golden_apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30a8\u30f3\u30c1\u30e3\u30f3\u30c8\u3055\u308c\u305f\u91d1\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.incendiary_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u767a\u706b\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.extinguishing_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u6d88\u706b\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.leashing_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ea\u30fc\u30d3\u30f3\u30b0\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"tag.item.xtraarrows.golden_arrows\": \"\u91d1\u306e\u77e2\"\n}\n```", "refusal": null}, "logprobs": null, "finish_reason": "stop"}], "usage": {"prompt_tokens": 405, "completion_tokens": 424, "total_tokens": 829, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_13eed4fce1"}}, "error": null}

                result_custom_id = str(result["custom_id"]).strip()
                if result_custom_id == batch_request_custom_id:
                    batch_result_found = True
                    translated_result = result["response"]["body"]["choices"][0]["message"]["content"]
                    break

        if batch_result_found and translated_result:
            translated_batch = loads(translated_result.replace("```json", "").replace("```", "").strip())
            translated_data.update(translated_batch)

            print(f"翻訳完了: {batch_request_custom_id}")
        else:
            json_str = json.dumps(batch_request, ensure_ascii=False)
            jsonl_data.append(json_str.strip())

            print(f"翻訳リクエスト: {batch_request_custom_id}")


    if translated_data:

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
            with zipfile.ZipFile(mod_path, 'r') as jar:
                en_file = next(f for f in jar.namelist() if f.endswith('en_us.json'))
                asset_path = os.path.dirname(os.path.dirname(en_file))
                
            # 日本語ファイルのパス
            jp_path = f"{asset_path}/lang/ja_jp.json"
            
            # 日本語ファイルを追加
            zf.writestr(jp_path, json.dumps(translated_data, indent=4, ensure_ascii=False))

        print(f"リソースパック作成完了: {zip_path}")


def create_resource_pack(mod_path, en_data, mod_name, resource_pack_path):
    """リソースパックを作成する"""
    zip_path = os.path.join(resource_pack_path, f"{mod_name}_jp.zip")

    if os.path.exists(zip_path):
        print(f"警告: {os.path.basename(zip_path)} は既に存在します")
        return
    
    # pack.mcmetaの内容
    pack_mcmeta = {
        "pack": {
            "description": f"{mod_name} Japanese Translation",
            "pack_format": 34
        }
    }
    
    # 50件ずつ翻訳
    translated_data = {}
    items = list(en_data.items())
    for i in range(0, len(items), 50):
        batch = dict(items[i:i+50])
        
        # 翻訳プロンプトの作成
        prompt = f"""
Minecraft の英語版 MOD の、日本語リソースパックを作成しています。
以下の英文のリソースパックを日本語に翻訳してください。
Java の Format 文字列（%s や %2$s など）は翻訳せずに、意味が通じる適切な位置に移動してください。
翻訳した JSON のみ出力してコメントや補足は出力しないでください。

```json
{json.dumps(batch, indent=2, ensure_ascii=False)}
```
"""
        # 翻訳実行
        try:
            result = chat(prompt)
            translated_batch = loads(result.replace("```json", "").replace("```", "").strip())
            translated_data.update(translated_batch)
            print(f"翻訳完了: {i+1}～{min(i+50, len(items))}/{len(items)}")
        except Exception as e:
            print(f"翻訳エラー: {str(e)}")
            continue

    # ZIPファイル作成
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        # pack.mcmeta
        zf.writestr('pack.mcmeta', json.dumps(pack_mcmeta, indent=4, ensure_ascii=False))
        
        # 言語ファイル
        # MODのアセットパスを取得
        with zipfile.ZipFile(mod_path, 'r') as jar:
            en_file = next(f for f in jar.namelist() if f.endswith('en_us.json'))
            asset_path = os.path.dirname(os.path.dirname(en_file))
            
        # 日本語ファイルのパス
        jp_path = f"{asset_path}/lang/ja_jp.json"
        
        # 日本語ファイルを追加
        zf.writestr(jp_path, json.dumps(translated_data, indent=4, ensure_ascii=False))

    print(f"リソースパック作成完了: {zip_path}")


def translate_mod_language(jar_path, resource_pack_path):
    """MODの言語ファイルを翻訳してリソースパックを作成する"""
    try:
        with zipfile.ZipFile(jar_path, 'r') as jar:
            # 英語ファイルを探す
            en_files = [f for f in jar.namelist() if f.endswith('en_us.json')]
            if not en_files:
                print(f"警告: {os.path.basename(jar_path)} に英語ファイルが見つかりません")
                return
            
            # 英語ファイルの内容を読み込む
            en_data = loads(jar.read(en_files[0]))

            if not en_data:
                print(f"警告: {os.path.basename(jar_path)} の英語ファイルが空です")
                return
            
            # リソースパック作成
            mod_name = os.path.splitext(os.path.basename(jar_path))[0]
            #create_resource_pack(jar_path, en_data, mod_name, resource_pack_path)
            create_resource_pack_batch(jar_path, en_data, mod_name, resource_pack_path)
            
    except Exception as e:
        print(f"エラー: {os.path.basename(jar_path)} の処理中にエラーが発生しました: {str(e)}")
        # print stack trace
        import traceback
        traceback.print_exc()

        print("en_data", en_data)


# batch
# {"custom_id": "request-1", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-3.5-turbo-0125", "messages": [{"role": "system", "content": "You are a helpful assistant."},{"role": "user", "content": "Hello world!"}],"max_tokens": 1000}}
# {"custom_id": "request-2", "method": "POST", "url": "/v1/chat/completions", "body": {"model": "gpt-3.5-turbo-0125", "messages": [{"role": "system", "content": "You are an unhelpful assistant."},{"role": "user", "content": "Hello world!"}],"max_tokens": 1000}}

batch_template = {
    "custom_id": "request-", 
    "method": "POST", "url": 
    "/v1/chat/completions", 
    "body": 
        {
            "model": "gpt-4o-mini-2024-07-18", 
            "messages": 
                [
                    {"role": "system", "content": """日本語のリソースパックを作成しています。
以下の英文のリソースパックを日本語に翻訳して。
英文に Java の Format 文字列（%s や %2$s）が含まれる場合、それは翻訳せずに適切な位置に移動してください。
翻訳したJSON のみ出力してコメントや補足は出力しないでください。"""},
                    {"role": "user", "content": ""}
                ],
            "max_tokens": 2048
        }
    }

def main(modpack_name = "Our Story Earth"):
    global jsonl_data, batch_result
    # MODフォルダのパス
    userprofile = os.environ.get("USERPROFILE")
    mods_path = os.path.join(userprofile, r"curseforge\minecraft\Instances", modpack_name, "mods")
    resource_pack_path = os.path.join(userprofile, r"curseforge\minecraft\Instances", modpack_name, "resourcepacks")
    
    # 結果を格納するリスト
    jp_mods = []    # 日本語化済み
    en_mods = []    # 英語のみ
    other_mods = [] # その他

    mod_lang_cache_file = "mod_lang_cache.pkl"
    cache = {}
    if os.path.exists(mod_lang_cache_file):
        with open(mod_lang_cache_file, "rb") as f:
            cache = pickle.load(f)
    
    # JARファイルを検索して処理
    for file in os.listdir(mods_path):
        if file.endswith('.jar'):
            jar_path = os.path.join(mods_path, file)
            mod_name = os.path.splitext(file)[0]
            zip_path = os.path.join(resource_pack_path, f"{mod_name}_jp.zip")

            if file in cache:
                result = cache[file]
            else:    
                result = check_mod_language(jar_path)
                cache[file] = result
            
            if os.path.exists(zip_path):
                result = 0
            
            if result == 0:
                jp_mods.append(file)
            elif result == 1:
                en_mods.append(file)
            else:
                other_mods.append(file)
    
    with open(mod_lang_cache_file, "wb") as f:
        pickle.dump(cache, f)
    

    batch_result = []
    if os.path.exists("batch_output.jsonl"):
        with open("batch_output.jsonl", "r", encoding="utf-8") as f:
            result_jsonl = f.readlines()
            for line in result_jsonl:
                batch_result.append(loads(line.strip()))


    jsonl_data = []

    # 英語のみのMODを翻訳
    print("\n=== 英語のみMODの翻訳を開始 ===")
    en_mods = sorted(en_mods)
    for i, mod in enumerate(en_mods):
        print(f"\n{mod} の翻訳を開始 ({i+1}/{len(en_mods)})")
        jar_path = os.path.join(mods_path, mod)
        translate_mod_language(jar_path, resource_pack_path)
    
    with open("batch.jsonl", "w", encoding="utf-8") as f:
        f.write("\n".join(jsonl_data))
    
    # 統計情報
    print("\n=== 統計情報 ===")
    print(f"合計MOD数: {len(jp_mods) + len(en_mods) + len(other_mods)}")
    print(f"日本語化済み: {len(jp_mods)}")
    print(f"英語のみ: {len(en_mods)}")
    print(f"その他: {len(other_mods)}")


if __name__ == "__main__":

    set_ai(
        model_names=[
            # "openai/local-lmstudio", # LM Studio (Local GPU), aya-expanse-32b (Q4_K_L) で動作確認
            # "deepseek/deepseek-chat",
            #"openai/gpt-4o-2024-11-20",
            #"anthropic/claude-3.5-haiku-20241022",
            "openai/gpt-4o-mini-2024-07-18",
        ],
        #temperature=0.8,
        retry_count=10
        )

    main(modpack_name="Our Story Earth")

