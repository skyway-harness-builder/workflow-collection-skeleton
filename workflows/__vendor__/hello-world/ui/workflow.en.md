---
short_description: Starter workflow for __vendor_name__ that prints a greeting.
long_description: A one-node, pure-bash example of a collection workflow. Replace the script, the workflow and these docs with your first automation.
changelog:
  - version: "1.0.0"
    date: "__today__"
    note: "Initial release."
---

The skyway dashboard shows `short_description` and `long_description` from this
frontmatter, and this body on the workflow's page. Keep a workflow's docs in a
`ui/` folder next to its `workflow.sky`, one file per language
(`workflow.en.md`, `workflow.nl.md`), and point `ui` in `⊕meta⊕` at it. Quote any
frontmatter value that contains `: `, or skyway ignores the frontmatter.
