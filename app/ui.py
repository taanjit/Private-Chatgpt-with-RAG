import sys
import os
from pathlib import Path

# Disable TensorFlow to avoid Keras 3 compatibility issues (must be set before imports)
os.environ["USE_TF"] = "0"
os.environ["USE_TORCH"] = "1"

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import streamlit as st
import tempfile
from backend.chat_engine import OllamaChatEngine, ChatMessage
from backend.rag_engine import SimpleLocalRAG

def init_session_state():
    if "messages" not in st.session_state:
        st.session_state.messages = []  # list[ChatMessage]
    if "engine" not in st.session_state:
        st.session_state.engine = OllamaChatEngine()
    if "rag" not in st.session_state:
        st.session_state.rag = SimpleLocalRAG()
    if "use_rag" not in st.session_state:
        st.session_state.use_rag = False

def sidebar_settings():
    st.sidebar.header("⚙️ Settings")

    model = st.sidebar.text_input("Model name", value=st.session_state.engine.model)
    temperature = st.sidebar.slider("Temperature", 0.0, 1.5, st.session_state.engine.temperature, 0.05)
    system_prompt = st.sidebar.text_area(
        "System prompt",
        value=st.session_state.engine.system_prompt,
        height=120,
    )

    if st.sidebar.button("Apply settings"):
        st.session_state.engine = OllamaChatEngine(
            model=model,
            temperature=temperature,
            system_prompt=system_prompt,
        )
        st.sidebar.success("Settings updated!")
    
    st.sidebar.divider()
    
    # RAG Settings
    st.sidebar.header("📚 RAG (Knowledge Base)")
    
    st.session_state.use_rag = st.sidebar.checkbox(
        "Enable RAG", 
        value=st.session_state.use_rag,
        help="Use uploaded documents to answer questions"
    )
    
    # File uploader
    uploaded_files = st.sidebar.file_uploader(
        "Upload PDF documents",
        type=["pdf"],
        accept_multiple_files=True,
        help="Upload PDF files to add to knowledge base"
    )
    
    if uploaded_files:
        if st.sidebar.button("Process PDFs"):
            with st.spinner("Processing PDFs..."):
                for uploaded_file in uploaded_files:
                    # Save to temp file
                    with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_file:
                        tmp_file.write(uploaded_file.read())
                        tmp_path = tmp_file.name
                    
                    try:
                        st.session_state.rag.add_pdf(tmp_path)
                        st.sidebar.success(f"✅ Added: {uploaded_file.name}")
                    except Exception as e:
                        st.sidebar.error(f"❌ Error with {uploaded_file.name}: {str(e)}")
                    finally:
                        os.unlink(tmp_path)
    
    # Show number of chunks in RAG
    if st.session_state.rag.chunks:
        st.sidebar.info(f"📄 Knowledge base: {len(st.session_state.rag.chunks)} chunks")
    
    if st.sidebar.button("Clear Knowledge Base"):
        st.session_state.rag = SimpleLocalRAG()
        st.sidebar.success("Knowledge base cleared!")
        st.rerun()

def render_chat():
    st.title("🛡️ Private GPT (Local Deepseek-r1 + Ollama)")
    
    # Clear chat button
    col1, col2 = st.columns([6, 1])
    with col2:
        if st.button("🗑️ Clear Chat"):
            st.session_state.messages = []
            st.rerun()

    # Show history
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])

    # Input box
    if user_input := st.chat_input("Type your message here..."):
        user_msg: ChatMessage = {"role": "user", "content": user_input}
        st.session_state.messages.append(user_msg)

        # Display immediately
        with st.chat_message("user"):
            st.markdown(user_input)

        with st.chat_message("assistant"):
            with st.spinner("Thinking..."):
                engine = st.session_state.engine
                
                # Prepare the message (with RAG context if enabled)
                final_message = user_input
                
                if st.session_state.use_rag and st.session_state.rag.chunks:
                    # Query RAG for relevant context
                    rag_results = st.session_state.rag.query(user_input, top_k=3)
                    
                    if rag_results:
                        # Build context from RAG results
                        context = "\n\n".join([chunk for chunk, score in rag_results])
                        final_message = f"""Based on the following context, please answer the question.

Context:
{context}

Question: {user_input}

Answer:"""
                        
                        # Show what context was used (optional, in expander)
                        with st.expander("📚 Retrieved Context", expanded=False):
                            for i, (chunk, score) in enumerate(rag_results, 1):
                                st.markdown(f"**Chunk {i}** (distance: {score:.2f})")
                                st.text(chunk[:300] + "..." if len(chunk) > 300 else chunk)
                                st.divider()
                
                reply = engine.chat(
                    user_message=final_message,
                    history=st.session_state.messages[:-1],  # past msgs excluding current
                    stream=False,
                )
                st.markdown(reply)

        st.session_state.messages.append({"role": "assistant", "content": reply})

def main():
    st.set_page_config(page_title="Private GPT", page_icon="🛡️", layout="wide")
    init_session_state()
    sidebar_settings()
    render_chat()

if __name__ == "__main__":
    main()
