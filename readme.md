# Sireum Mill Build

This repository holds a script to build [mill](https://github.com/lihaoyi/mill)
with [SireumModule](sireum/src/org/sireum/mill/SireumModule.scala) embedded in it to
ease building Sireum modules and with IntelliJ support for SireumModule.

## Standalone Version

Based on mill releases. 
Latest version is available [here](http://files.sireum.org/mill-standalone).

To build:

```bash
./build-standalone.sh <mill-release-version> [<num-sha6>]
```

For example:

```bash
./build-standalone.sh 0.1.4
```

or 

```bash
./build-standalone.sh 0.1.4 23-55ee6e
```

This produces `mill-standalone`, and the mill release version is stored as 
`mill-release`.

## Local Version with IntelliJ Support for SireumModule

Based on mill master branch.

To build:

```bash
./build.sh [<mill-release-version>]
```

It calls `build-standalone.sh` first if `mill-standalone` is not available.

This produces `mill` (and `mill-standalone`).
