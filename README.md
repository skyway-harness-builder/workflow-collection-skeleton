# __package_description__

[![Sky lint](https://github.com/__github_org__/__repo_name__/actions/workflows/sky-lint.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/sky-lint.yml)
[![YAML check](https://github.com/__github_org__/__repo_name__/actions/workflows/yaml-check.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/yaml-check.yml)
[![Bash check](https://github.com/__github_org__/__repo_name__/actions/workflows/bash-check.yml/badge.svg)](https://github.com/__github_org__/__repo_name__/actions/workflows/bash-check.yml)

<!--delete-->
---
This repo can be used to scaffold a Skylence workflow library. Follow these steps to get started:

1. Press the "Use this template" button at the top of this repo to create a new repo with the contents of this skeleton.
2. Run `bash configure.sh` to replace all placeholders throughout all the files.
3. Add your workflows under `workflows/<vendor>/` and register them in `manifest.yaml`.
4. Have fun automating things with `.sky` workflows.
---
<!--/delete-->

This is where your description should go. Limit it to a paragraph or two.

## Installation

Install this workflow library via the `sky` CLI:

```bash
sky library add __github_org__/__repo_name__
```

## Workflows

| Name | Trigger | Description |
|------|---------|-------------|
| `hello-world` | manual | Starter workflow — replace with your first automation |

Run a workflow:

```bash
sky run hello-world
```

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Please see [CONTRIBUTING](CONTRIBUTING.md) for details.

## Credits

- [__author_name__](https://github.com/__author_username__)
- [All Contributors](../../contributors)

## License

Please see [License File](LICENSE.md) for more information.
