import requests
import os
from typing import List, Dict, Optional

# Auto-detect: Use localhost for local runs, host.docker.internal for Docker
OLLAMA_BASE_URL = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")

class ChatMessage(Dict):
    """Simple alias: { 'role': 'user'|'assistant'|'system', 'content': '...' }"""
    pass

class OllamaChatEngine:
    def __init__(
        self,
        model: str = "deepseek-r1:8b",
        temperature: float = 0.7,
        system_prompt: str = "You are a helpful AI assistant.",
    ):
        self.model = model
        self.temperature = temperature
        self.system_prompt = system_prompt

    def _build_messages(
        self,
        user_message: str,
        history: Optional[List[ChatMessage]] = None,
    ) -> List[ChatMessage]:
        msgs: List[ChatMessage] = []

        # System message first
        if self.system_prompt:
            msgs.append({"role": "system", "content": self.system_prompt})

        # Previous history
        if history:
            msgs.extend(history)

        # New user message
        msgs.append({"role": "user", "content": user_message})
        return msgs

    def chat(
        self,
        user_message: str,
        history: Optional[List[ChatMessage]] = None,
        stream: bool = False,
    ):
        """
        Returns either a full string or a generator of chunks (if stream=True).
        """
        msgs = self._build_messages(user_message, history)

        payload = {
            "model": self.model,
            "messages": msgs,
            "options": {
                "temperature": self.temperature,
            },
            "stream": stream,
        }

        # Use Ollama's native API endpoint
        url = f"{OLLAMA_BASE_URL}/api/chat"

        if stream:
            # Return the streaming generator
            return self._stream_chat(url, payload)
        else:
            # Non-streaming response
            resp = requests.post(url, json=payload, timeout=600)
            resp.raise_for_status()
            data = resp.json()
            return data["message"]["content"]

    def _stream_chat(self, url: str, payload: dict):
        """
        Separate generator function for streaming responses.
        """
        import json
        with requests.post(url, json=payload, stream=True, timeout=600) as r:
            r.raise_for_status()
            for line in r.iter_lines():
                if not line:
                    continue
                try:
                    chunk_data = json.loads(line.decode("utf-8"))
                    if "message" in chunk_data:
                        yield chunk_data["message"]["content"]
                except Exception:
                    continue
