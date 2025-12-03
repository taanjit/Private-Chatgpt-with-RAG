from typing import List, Tuple
import os
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
from pypdf import PdfReader

class SimpleLocalRAG:
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.embedder = SentenceTransformer(model_name)
        self.index = None
        self.chunks: List[str] = []

    def _chunk_text(self, text: str, chunk_size: int = 500, overlap: int = 100) -> List[str]:
        words = text.split()
        chunks = []
        start = 0
        while start < len(words):
            end = start + chunk_size
            chunk = " ".join(words[start:end])
            chunks.append(chunk)
            start = end - overlap
        return chunks

    def add_pdf(self, file_path: str):
        reader = PdfReader(file_path)
        full_text = ""
        for page in reader.pages:
            full_text += page.extract_text() + "\n"
        self.add_text(full_text)

    def add_text(self, text: str):
        new_chunks = self._chunk_text(text)
        new_embeddings = self.embedder.encode(new_chunks, convert_to_numpy=True)
        if self.index is None:
            dim = new_embeddings.shape[1]
            self.index = faiss.IndexFlatL2(dim)
            self.index.add(new_embeddings)
            self.chunks = new_chunks
        else:
            self.index.add(new_embeddings)
            self.chunks.extend(new_chunks)

    def query(self, question: str, top_k: int = 4) -> List[Tuple[str, float]]:
        if self.index is None:
            return []
        q_emb = self.embedder.encode([question], convert_to_numpy=True)
        D, I = self.index.search(q_emb, top_k)
        results = []
        for score, idx in zip(D[0], I[0]):
            results.append((self.chunks[idx], float(score)))
        return results
