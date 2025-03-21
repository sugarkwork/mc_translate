import os
import gradio as gr
import sys
sys.path.append(".")

from translate_mods import get_curseforge_instance, get_microsoft_instance, get_en_mods, main
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def save_api_key(api_key):
    """Save OpenAI API key to .env file"""
    with open(".env", "w") as f:
        f.write(f'OPENAI_API_KEY="{api_key}"\n')
    return "APIキーを保存しました"

def get_instances():
    """Get all Minecraft instances"""
    curseforge_instances = get_curseforge_instance()
    microsoft_instances = get_microsoft_instance()
    
    # Extract folder names for CurseForge instances
    curseforge_names = [os.path.basename(path) for path in curseforge_instances]
    
    # Use "Microsoft Minecraft" for the Microsoft instance
    microsoft_names = ["Microsoft Minecraft" if path else "" for path in microsoft_instances]
    microsoft_names = [name for name in microsoft_names if name]  # Remove empty strings
    
    return {
        "CurseForge": curseforge_instances,
        "CurseForge_names": curseforge_names,
        "Microsoft": microsoft_instances,
        "Microsoft_names": microsoft_names
    }

def update_instance_list(instance_type):
    """Update instance list based on selected type"""
    instances = get_instances()
    choices = instances["CurseForge_names"] if instance_type == "CurseForge" else instances["Microsoft_names"]
    return gr.Dropdown(choices=choices, value=None)

def get_instance_path(instance_type, instance_name):
    """Get instance path based on type and name"""
    if not instance_name:
        return None
        
    instances = get_instances()
    if instance_type == "CurseForge":
        return next((path for path in instances["CurseForge"] 
                    if os.path.basename(path) == instance_name), None)
    else:
        return next((path for path in instances["Microsoft"] if path), None)

def update_mods_list(instance_type, instance_name):
    """Update mods list based on selected instance"""
    if not instance_name:
        return "", "インスタンスを選択してください"
    
    instance_path = get_instance_path(instance_type, instance_name)
    if not instance_path:
        return "", "インスタンスが見つかりません"
    
    en_mods = get_en_mods(instance_path)
    if not en_mods:
        return instance_path, "翻訳が必要なMODは見つかりませんでした"
    
    return instance_path, "\n".join([f"- {mod}" for mod in en_mods])

def start_translation(instance_path):
    """Start translation process"""
    if not instance_path:
        return "インスタンスを選択してください"
    
    try:
        main(instance_path)
        return "翻訳処理を開始しました。処理が完了するまでお待ちください。\n完了後、Minecraftのリソースパックに新しい日本語化パックが追加されます。"
    except Exception as e:
        return f"エラーが発生しました: {str(e)}"

def create_ui():
    """Create Gradio interface"""
    instances = get_instances()

    def create_setting_tag():
        with gr.Tab("設定"):
            api_key_input = gr.Textbox(
                label="OpenAI API キー",
                placeholder="sk-...",
                type="password",
                value=os.getenv("OPENAI_API_KEY", "")
            )
            api_key_button = gr.Button("保存", variant="primary")
            api_key_output = gr.Textbox(label="結果")
            
            api_key_button.click(
                fn=save_api_key,
                inputs=api_key_input,
                outputs=api_key_output
            )
    
    with gr.Blocks(title="Minecraft MOD 日本語化ツール") as app:
        gr.Markdown("""
        # Minecraft MOD 日本語化ツール
        
        このツールは、MinecraftのMODを自動で日本語化します。
        
        使い方:
        1. 設定タブでOpenAI APIキーを入力
        2. MOD翻訳タブでインスタンスを選択
        3. 未翻訳MODの一覧を確認
        4. 翻訳開始ボタンをクリック
        """)
        
        if not os.getenv("OPENAI_API_KEY"):
            create_setting_tag()
        
        with gr.Tab("MOD翻訳"):
            with gr.Row():
                instance_type = gr.Radio(
                    choices=["CurseForge", "Microsoft"],
                    label="インスタンスタイプ",
                    value="CurseForge",
                    info="Minecraftのインストールタイプを選択してください"
                )
                instance_dropdown = gr.Dropdown(
                    choices=instances["CurseForge_names"],
                    label="インスタンス",
                    value=None,
                    info="翻訳したいMinecraftインスタンスを選択してください"
                )
            
            instance_path = gr.Textbox(visible=False)
            mods_output = gr.Textbox(
                label="未翻訳MOD一覧",
                lines=10,
                interactive=False,
                info="選択したインスタンスの未翻訳MOD一覧が表示されます"
            )
            
            start_button = gr.Button("翻訳開始", variant="primary")
            result_output = gr.Textbox(
                label="処理結果",
                info="翻訳処理の状態が表示されます"
            )
            
            # Update instance list when type changes
            instance_type.change(
                fn=update_instance_list,
                inputs=instance_type,
                outputs=instance_dropdown
            )
            
            # Update mods list when instance changes
            instance_dropdown.change(
                fn=update_mods_list,
                inputs=[instance_type, instance_dropdown],
                outputs=[instance_path, mods_output]
            )
            
            # Start translation when button is clicked
            start_button.click(
                fn=start_translation,
                inputs=instance_path,
                outputs=result_output
            )
        
        if os.getenv("OPENAI_API_KEY"):
            create_setting_tag()
    
    return app

if __name__ == "__main__":
    app = create_ui()
    app.launch()