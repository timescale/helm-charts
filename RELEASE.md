# Helm Chart release guide

## Procedure

Release procedure is a 3 step process that can be described as follows:
1. Update `version` value in `Chart.yaml` file of the chart you want to release.
2. Create a PR with that change (consider bundling it with some other changes you want to do)
3. After PR is merged, create a new tag following tagging schema mentioned below. Tagging can be done either from GitHub UI or from developer machine.
4. From now on GitHub Actions automation takes over and in few minutes release should be ready.

## Tagging schema

Since we have multiple charts in a single repository, we cannot use usual smever tagging method known from other projects. However this problem is solved in helm community by prefixing tag version with chart name as follows:

`<chart-name>-<version>`

ex. `timescaledb-single-0.13.0`

_Note: `<version>` shouldn't contain `v` prefix._