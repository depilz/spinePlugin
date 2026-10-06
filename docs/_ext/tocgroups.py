"""Group labels in the sidebar: above each toctree's first member on an object index page with several toctrees, a
non-link item naming the section the toctree sits under (Sphinx drops the captions of toctrees outside the root doc)."""
import re

from docutils import nodes
from sphinx import addnodes
from sphinx.environment.adapters.toctree import TocTree

OBJECT_INDEX = re.compile(r"api_reference/.+/index")


def heading(toctree):
    """The title of the section a toctree sits under in its page's toc, or None when it sits under the page title."""
    item = toctree.parent.parent
    if isinstance(item, nodes.list_item) and isinstance(item.parent.parent, nodes.list_item):
        return item[0].astext()
    return None


def collect(app, env):
    """env.tocgroups: {object index docname: [(label, first member docname)]}, one per toctree with an entry."""
    env.tocgroups = {}
    for docname, toc in env.tocs.items():
        toctrees = list(toc.findall(addnodes.toctree))
        if OBJECT_INDEX.fullmatch(docname) and len(toctrees) > 1:
            env.tocgroups[docname] = [(heading(t), t["entries"][0][1]) for t in toctrees if t["entries"] and heading(t)]


def members(tree, uri):
    for ref in tree.findall(nodes.reference):
        if ref["refuri"] == uri and not ref["anchorname"] and isinstance(ref.parent.parent, nodes.list_item):
            return next((child for child in ref.parent.parent.children if isinstance(child, nodes.bullet_list)), None)
    return None


def label_item(member, label):
    level = [c for c in member["classes"] if c.startswith("toctree-l")]
    text = nodes.inline("", label, classes=["toc-group-label"])
    return nodes.list_item("", addnodes.compact_paragraph("", "", text), classes=level + ["toc-group"])


def insert_labels(tree, groups, uri_of):
    for owner, entries in groups.items():
        items = members(tree, uri_of(owner))
        if items is None:
            continue
        by_uri = {item.next_node(nodes.reference)["refuri"]: item for item in items.children}
        for label, first in entries:
            item = by_uri.get(uri_of(first))
            if item is not None:
                items.insert(items.index(item), label_item(item, label))


def on_page_context(app, pagename, templatename, context, doctree):
    builder = app.builder

    def uri_of(docname):
        return builder.get_relative_uri(pagename, docname)

    # the builder's own toctree() renders at once; this one resolves the same tree and labels it first
    def toctree(collapse=True, **kwargs):
        kwargs.setdefault("includehidden", False)
        if kwargs.get("maxdepth") == "":
            kwargs.pop("maxdepth")
        tree = TocTree(app.env).get_toctree_for(pagename, builder, collapse, **kwargs)
        if tree is not None:
            insert_labels(tree, app.env.tocgroups, uri_of)
        return builder.render_partial(tree)["fragment"]

    context["toctree"] = toctree


def connect(app):
    app.connect("env-updated", collect)
    app.connect("html-page-context", on_page_context)
