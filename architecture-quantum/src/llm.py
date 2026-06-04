from abc import ABC, abstractmethod
from typing import Optional, List, Dict

import requests

from src.config import (
    YANDEX_API_KEY,
    YANDEX_API_URL,
    YANDEX_FOLDER_ID,
    YANDEX_MAX_TOKENS,
    YANDEX_MODEL,
    YANDEX_MODEL_URI,
    YANDEX_TEMPERATURE,
    YANDEX_TIMEOUT_S,
)


class BaseLLM(ABC):
    @abstractmethod
    def generate(self, messages: List[Dict[str, str]]) -> str:
        ...


class YandexGPTLLM(BaseLLM):
    def __init__(
        self,
        *,
        api_key: str,
        folder_id: str,
        model_uri: Optional[str] = None,
        api_url: str = YANDEX_API_URL,
        temperature: float = YANDEX_TEMPERATURE,
        max_tokens: int = YANDEX_MAX_TOKENS,
        timeout_s: float = YANDEX_TIMEOUT_S,
    ):
        self._api_key = api_key
        self._folder_id = folder_id
        self._api_url = api_url
        self._temperature = temperature
        self._max_tokens = max_tokens
        self._timeout_s = timeout_s
        self._model_uri = model_uri or f"gpt://{folder_id}/{YANDEX_MODEL}"

    def generate(self, messages: List[Dict[str, str]]) -> str:
        payload = {
            "modelUri": self._model_uri,
            "completionOptions": {
                "stream": False,
                "temperature": self._temperature,
                "maxTokens": str(self._max_tokens),
            },
            "messages": messages,
        }

        resp = requests.post(
            self._api_url,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Api-Key {self._api_key}",
                "x-folder-id": self._folder_id,
            },
            json=payload,
            timeout=self._timeout_s,
        )

        if resp.status_code != 200:
            raise RuntimeError(f"YandexGPT request failed: HTTP {resp.status_code}: {resp.text}")

        data = resp.json()
        try:
            return data["result"]["alternatives"][0]["message"]["text"]
        except Exception as e:  # noqa: BLE001
            raise RuntimeError(f"Unexpected YandexGPT response format: {data}") from e


class StubLLM(BaseLLM):
    """Placeholder LLM that echoes the prompt back.
    Replace with a real implementation (OpenAI, Anthropic, local model, etc.)
    """

    def generate(self, messages: List[Dict[str, str]]) -> str:
        rendered = "\n\n".join(
            f"[{m.get('role', 'unknown')}]\n{m.get('text', '')}".strip() for m in messages
        )
        return (
            "[StubLLM] Real LLM is not connected yet.\n"
            "Messages that would be sent:\n"
            "---\n"
            f"{rendered}\n"
            "---"
        )


def create_default_llm() -> BaseLLM:
    if YANDEX_API_KEY and YANDEX_FOLDER_ID:
        return YandexGPTLLM(
            api_key=YANDEX_API_KEY,
            folder_id=YANDEX_FOLDER_ID,
            model_uri=YANDEX_MODEL_URI,
        )
    return StubLLM()
