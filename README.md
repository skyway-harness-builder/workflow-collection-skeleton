# __vendor_name__ Workflows

[![Sky lint](https://github.com/__github_org__/__repo_name__/actions/workflows/sky-lint.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/sky-lint.yml)
[![YAML check](https://github.com/__github_org__/__repo_name__/actions/workflows/yaml-check.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/yaml-check.yml)
[![Bash check](https://github.com/__github_org__/__repo_name__/actions/workflows/bash-check.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/bash-check.yml)

A [Skylence](https://skylence.io) workflow library by **__author_name__**.

---

> **This is a generated repo.** It was bootstrapped from
> [skylence-be/workflow-skeleton](https://github.com/skylence-be/workflow-skeleton).
> Delete this notice once you've configured the library.

---

## Install

```bash
sky library add __github_org__/__repo_name__
```

Then run any workflow:

```bash
sky run hello-world
```

## Structure

```
workflows/
└── __vendor__/         ← your vendor namespace
    └── hello-world/
        ├── scripts/    ← bash helpers
        └── workflow.sky
manifest.yaml           ← registry of all workflows and skills
scripts/
└── validate-manifest.sh
```

One workflow per directory. Add more workflows, register them in `manifest.yaml`, and the CI gates will keep everything in sync.

## Adding a workflow

1. Create a directory under `workflows/__vendor__/<name>/`
2. Write `workflow.sky` (see [sky format reference](https://skylence.io/docs/sky-format))
3. Add an entry to `manifest.yaml`
4. Run `bash scripts/validate-manifest.sh` to check for drift
5. Commit — `lefthook` lints the `.sky` file before the commit lands

## CI

Three layered gates run on every push and pull request:

| Workflow | Layer 1 | Layer 2 |
|----------|---------|---------|
| `sky-lint.yml` | `sky lint` on `.sky` files | manifest drift check |
| `yaml-check.yml` | `yaml.safe_load` syntax | `yamllint` style |
| `bash-check.yml` | `bash -n` syntax | `shellcheck` static analysis |

`lefthook` mirrors the fast layers locally so broken files never reach the remote.

## Author

__author_name__ — __author_email__

## License

<!-- Add a LICENSE file and update this section. -->
