# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '_ext'))
import spineline

# One tree, one build per plugin line (4.2 -> plugin.spine42, 4.3 -> plugin.spine43).
line = spineline.select_line(os.environ)
version = release = spineline.LINES[line]['release']
tags.add(spineline.LINES[line]['tag'])

project = 'Spine plugin for Solar2D'
copyright = '2024-2026, Denis Pilz'
author = 'Denis Pilz'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_wagtail_theme',
]

templates_path = ['_templates']
exclude_patterns = ['_build', '.venv', 'venv', 'env', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_wagtail_theme'
html_static_path = ['_static']
html_sidebars = { '**': ['globaltoc.html', 'relations.html', 'sourcelink.html', 'searchbox.html'] }

html_baseurl = spineline.base_url(line)

# These are options specifically for the Wagtail Theme.
html_theme_options = dict(
    project_name = "Spine plugin for Solar2D",

    logo = "logo.svg",
    logo_alt = "logo",
    logo_height = 47,
    logo_url = f"{html_baseurl}/index.html",
    logo_width = 42,
    header_links = ",".join([
        f"Home|{html_baseurl}/index.html",
        f"API Reference|{html_baseurl}/api_reference/index.html",
    ]),
    footer_links = ",".join([
        f"About|{html_baseurl}/about.html",
        f"Contact|{html_baseurl}/contact.html",
        f"Legal|{html_baseurl}/legal.html",
    ]),
)
html_last_updated_fmt = "%b %d, %Y"

html_context = {
    'favicon_url': 'favicon.ico',
}

html_favicon = 'favicon.ico'


def setup(app):
    spineline.connect(app, line)
