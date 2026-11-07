# LibNodeGraphStd

Standard node types for [LibNodeGraph](https://github.com/adamk33n3r/rs3-LibNodeGraph).

## Installation

Depends on [LibNodeGraph](https://github.com/adamk33n3r/rs3-LibNodeGraph). Declare both in `plugin.json`. The client injects the `LibNodeGraphStd` global.

```json
{
  "requiredDependencies": {
    "LibNodeGraph": "LibNodeGraph",
    "LibNodeGraphStd": "LibNodeGraphStd"
  }
}
```

## Usage

After you build a registry, call `LibNodeGraphStd.Register(registry)`.

## Tests

From this folder:

```shell
lua tests/run.lua
```

## Contributing

### LLM/AI Usage Policy

When contributing to LibNodeGraphStd we permit the use of AI tools to assist in writing code. However, all contributions must be reviewed and approved by a human maintainer to ensure quality and adherence to project standards.

**DO NOT**

- Let LLMs generate your documentation for you.
- Submit Pull Requests generated solely by LLMs without human review.
- Have an LLM generate your Pull Request body.
