# Contributing to Timescale Helm Charts

We'd love your help!

## How to Contribute

1. Fork this repository
1. Develop, and test your changes
1. Submit a pull request

_NOTE_: In order to make testing and merging of PRs easier, please submit changes to multiple charts in separate PRs.

Remember to always work in a branch of your local copy, as you might otherwise
have to contend with conflicts in master.

Please also see [GitHub
flow](https://docs.github.com/en/get-started/quickstart/github-flow).

### Technical Requirements

* Must pass [CLA check](https://cla-assistant.io/timescale/helm-charts)
* Must follow [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/)
* Must pass CI jobs for linting and installing changed charts with the
  [chart-testing](https://github.com/helm/chart-testing) tool
* Any change to a chart requires a version bump following
  [semver](https://semver.org/) principles. See [Immutability](#immutability)
  and [Versioning](#versioning) below

Once changes have been merged, the release job will automatically run to package
and release changed charts.

### Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version
bump even if it is only changed to the documentation.

### Versioning

The chart `version` should follow [semver](https://semver.org/).

Charts should start at `0.1.0` or `1.0.0`. Any breaking (backwards incompatible)
changes to a chart should:

1. Bump the MAJOR version
2. In the README or appropriate document, describe the manual steps necessary to upgrade to the new (specified) MAJOR version
