# Upgrade guidelines

## 0.13.0 to 13.0.0

We improved how promscale image is set to use a de-facto standard way known from other helm charts. If you weren't overriding image, this is no-op for you. However if you were overriding image, now you need to use the format of:

```
image:
  repository: timescale/promscale
  # The default will come from appVersion in Chart.yaml, if you wish to
  # override that value then set the tag version here.
  tag:
  pullPolicy: IfNotPresent
```

Instead of one known from 0.13.0 chart:

```
image: timescale/promscale
imagePullPolicy: IfNotPresent
```

Additionally we also added now a json schema to validate helm values to allow catch issues like the one above.
