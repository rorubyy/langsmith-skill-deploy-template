import os

from deepagents import create_deep_agent
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from deepagents.backends.local_shell import LocalShellBackend

load_dotenv()

llm = ChatOpenAI(
    model=os.environ["MODEL_NAME"],
    use_responses_api=False,
)

graph = create_deep_agent(
    model=llm,
    memory=["./memories/AGENTS.md"],
    skills=["./skills"],
    backend=LocalShellBackend(root_dir=".", inherit_env=True),
)
