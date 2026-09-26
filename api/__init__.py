from api.base import APIError
from api.openai import OpenAIController
from api.anthropic import AnthropicController
from api.xai import XAIController
from api.google import GoogleController
from api.deepseek import DeepSeekController
from api.moonshot import MoonshotController
from api.qwen import QwenController
from api.mistral import MistralController

CLOUD_PREFIX = "cloud"

CONTROLLERS = {
    "ChatGPT":  OpenAIController(),
    "Claude":   AnthropicController(),
    "Grok":     XAIController(),
    "Gemini":   GoogleController(),
    "DeepSeek": DeepSeekController(),
    "Kimi":     MoonshotController(),
    "Qwen":     QwenController(),
    "Mistral":  MistralController(),
}

PROVIDERS = list(CONTROLLERS.keys())


def cloud_code(provider: str, model: str) -> str:
    return f"{CLOUD_PREFIX}:{provider}:{model}"


def is_cloud(code: str) -> bool:
    return code.startswith(f"{CLOUD_PREFIX}:")


def parse_cloud(code: str):
    _, provider, model = code.split(":", 2)
    return provider, model


def list_models(provider: str, api_key: str) -> list:
    return CONTROLLERS[provider].list_models(api_key)


def chat(provider: str, api_key: str, model: str, prompt: str) -> str:
    return CONTROLLERS[provider].chat(api_key, model, prompt)


__all__ = [
    "APIError",
    "CONTROLLERS",
    "PROVIDERS",
    "CLOUD_PREFIX",
    "cloud_code",
    "is_cloud",
    "parse_cloud",
    "list_models",
    "chat",
]
