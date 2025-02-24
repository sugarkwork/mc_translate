from openai import OpenAI
client = OpenAI()

batch_id = None
batch_id = "batch_67b89de9bf1c8190ac456c1d289e9072"


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
    # sample:
    """{
  "id": "batch_abc123",
  "object": "batch",
  "endpoint": "/v1/chat/completions",
  "errors": null,
  "input_file_id": "file-abc123",
  "completion_window": "24h",
  "status": "validating",
  "output_file_id": null,
  "error_file_id": null,
  "created_at": 1714508499,
  "in_progress_at": null,
  "expires_at": 1714536634,
  "completed_at": null,
  "failed_at": null,
  "expired_at": null,
  "request_counts": {
    "total": 0,
    "completed": 0,
    "failed": 0
  },
  "metadata": null
}"""

else:
    batch = client.batches.retrieve(batch_id)
    print(batch)

    if batch.status == "completed":
        file_response = client.files.content(batch.output_file_id)
        print(file_response.text)

        with open("batch_output.jsonl", "w") as f:
            f.write(file_response.text)
