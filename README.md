# yq-go

Packaging for the `yq` lightweight and portable command-line file processor
(<https://github.com/mikefarah/yq.git>).

## Installation

The following below are dependencies for building the packages[^1].

1. Make
2. Docker
3. Git
4. Go (a version that supports Go modules)

[^1]: Additional dependencies may be are required to run the Make targets.

### Ubuntu Linux

#### 22.04

1. Create the `yq-go` `deb` package.

   ```shell
   make OS="ubuntu-22.04" "deb"
   ```

2. Update the `apt` package index, then install `yq-go`.

   ```shell
   sudo apt-get update
   sudo apt-get install --assume-yes ./yq-go_*.deb
   ```

3. Clean the repository's working directory (optional).

   ```shell
   make OS="ubuntu-22.04" "clean"
   ```

#### 24.04

1. Create the `yq-go` `deb` package.

   ```shell
   make OS="ubuntu-24.04" "deb"
   ```

2. Update the `apt` package index, then install `yq-go`.

   ```shell
   sudo apt-get update
   sudo apt-get install --assume-yes ./yq-go_*.deb
   ```

3. Clean the repository's working directory (optional).

   ```shell
   make OS="ubuntu-24.04" "clean"
   ```

## License

See LICENSE.
