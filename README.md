# Born Gosu Gaming

A collection of bots and tools, as well as eventually a co-server for the website.

## Developing

### First Time
```bash
> ./scripts/provision.sh
```

### Running Locally

```bash
> iex -S mix
```

### Testing Locally

```bash
> mix test
```

## Secrets

To work:
```bash
> ./scripts/decrypt-secrets.sh
```

To cleanup:
```bash
> rm -rf config/secret/*.exs
```

## Deploying

### First time per server

Run this once per server, plus once every time you change the provision scripts

```bash
> ./scripts/deploy-source.sh mynewserver.com
> ssh root@mynewserver.com "/tmp/born-gosu-gaming/build/scripts/provision.sh"
```

### Deploying code to a provisioned server

```bash
> ./scripts/deploy-source.sh mynewserver.com
> ssh root@mynewserver.com "/tmp/born-gosu-gaming/build/scripts/build-release.sh"
```
