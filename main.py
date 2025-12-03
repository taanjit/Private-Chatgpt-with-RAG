#!/usr/bin/env python3
"""
Private GPT - Main Entry Point

This script launches the Streamlit UI for Private GPT.
Make sure Ollama is running before starting the application.
"""

import sys
import os

# Add the project root to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == "__main__":
    import streamlit.web.cli as stcli
    
    # Path to the UI file
    ui_file = os.path.join(os.path.dirname(__file__), "app", "ui.py")
    
    # Run Streamlit
    sys.argv = [
        "streamlit",
        "run",
        ui_file,
        "--server.address", "0.0.0.0",
        "--server.port", "8501",
        "--browser.gatherUsageStats", "false",
    ]
    
    sys.exit(stcli.main())

