from openai import OpenAI
client = OpenAI()

batch_id = None
batch_id = "batch_67b89de9bf1c8190ac456c1d289e9072"


data = {"id": "batch_req_67b8a9c0ae8c81908ec9172a63cd48f4", "custom_id": "xtraarrows-3.4.2-fabric-mc1.21250", "response": {"status_code": 200, "request_id": "2b8a576919621d0a2c21fc9d696f6be2", "body": {"id": "chatcmpl-B3PPQK5pEoAbAd0bkcLBe5jKJHOan", "object": "chat.completion", "created": 1740152356, "model": "gpt-4o-mini-2024-07-18", "choices": [{"index": 0, "message": {"role": "assistant", "content": "```json\n{\n  \"xtraarrows.text.soul_lantern_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30e9\u30f3\u30bf\u30f3\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.life_steal_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30e9\u30a4\u30d5\u30b9\u30c6\u30a3\u30fc\u30eb\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.magnetic_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30de\u30b0\u30cd\u30c6\u30a3\u30c3\u30af\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.breeding_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u7e41\u6b96\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.cupids_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ad\u30e5\u30fc\u30d4\u30c3\u30c9\u306e\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.golden_apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u91d1\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.enchanted_golden_apple_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30a8\u30f3\u30c1\u30e3\u30f3\u30c8\u3055\u308c\u305f\u91d1\u306e\u30ea\u30f3\u30b4\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.incendiary_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u767a\u706b\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.extinguishing_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u6d88\u706b\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"xtraarrows.text.leashing_disabled\": \"\u00a7c\u3053\u306e\u30b5\u30fc\u30d0\u30fc\u3067\u306f\u3059\u3079\u3066\u306e\u30ea\u30fc\u30d3\u30f3\u30b0\u77e2\u304c\u7121\u52b9\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002\",\n  \"tag.item.xtraarrows.golden_arrows\": \"\u91d1\u306e\u77e2\"\n}\n```", "refusal": None}, "logprobs": None, "finish_reason": "stop"}], "usage": {"prompt_tokens": 405, "completion_tokens": 424, "total_tokens": 829, "prompt_tokens_details": {"cached_tokens": 0, "audio_tokens": 0}, "completion_tokens_details": {"reasoning_tokens": 0, "audio_tokens": 0, "accepted_prediction_tokens": 0, "rejected_prediction_tokens": 0}}, "service_tier": "default", "system_fingerprint": "fp_13eed4fce1"}}, "error": None}



print(data)

print()

print(data["response"]["body"]["choices"][0]["message"]["content"])

import sys
sys.exit(0)



if not batch_id:
    batch_input_file = client.files.create(
        file=open("batch.jsonl", "rb"),
        purpose="batch"
    )

    print(batch_input_file)

    batch_input_file_id = batch_input_file.id
    batch_result = client.batches.create(
        input_file_id=batch_input_file_id,
        endpoint="/v1/chat/completions",
        completion_window="24h",
        metadata={
            "description": "nightly eval job"
        }
    )

    print(batch_result)

else:
    batch = client.batches.retrieve(batch_id)
    print(batch)

    if batch.status == "completed":
        file_response = client.files.content(batch.output_file_id)
        print(file_response.text)

        with open("batch_output.jsonl", "w") as f:
            f.write(file_response.text)
