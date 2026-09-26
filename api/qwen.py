from api.base import OpenAICompatibleController


class QwenController(OpenAICompatibleController):
    name = "Qwen"
    base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1"
