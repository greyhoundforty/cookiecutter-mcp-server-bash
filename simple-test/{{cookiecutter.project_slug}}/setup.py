### setup.py
```python
from setuptools import setup, find_packages

setup(
    name="{{cookiecutter.project_slug}}",
    version="0.1.0",
    author="{{cookiecutter.author_name}}",
    author_email="{{cookiecutter.author_email}}",
    description="{{cookiecutter.project_name}}",
    packages=find_packages(),
    python_requires=">=3.12",
    install_requires=[
        {% if cookiecutter.additional_tools %}
        {% for tool in cookiecutter.additional_tools.split(',') %}
        "{{tool.strip()}}",
        {% endfor %}
        {% endif %}
    ],
)
