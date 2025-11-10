# -*- coding: utf-8 -*-
"""
Legacy setup.py for backward compatibility.

For modern installation, use:
    pip install .

Or for development:
    pip install -e .

For building distributions:
    python -m build

The project configuration is now in pyproject.toml (PEP 517/518/621).
"""

from setuptools import setup

# All configuration is now in pyproject.toml
# This setup.py exists only for backward compatibility
setup()
