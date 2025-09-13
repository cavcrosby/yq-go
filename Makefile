# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh
export YQ_REPO_PATH = ./yq
TRUTHY_VALUES = \
    true\
    1

# to be (or can be) passed in at make runtime
ifeq (${OS},ubuntu-24.04)
	export IMAGE = deb-yq-go-${OS}:latest
	export VERSION_YQ = v4.45.2
	export VERSION_GO = 1.23
	export CODENAME = noble
	PKG_REVISION = -1ubuntu1

	# vendor container image has a non-root user of uid
	NON_ROOT_UID = 1000
	ifeq (${NON_ROOT_UID},$(shell id --user))
		DOCKERFILE_PATH = ./Dockerfile.ubuntu
	else
		DOCKERFILE_PATH = ./Dockerfile.ubuntu-adduser
	endif
else ifeq (${OS},ubuntu-22.04)
	export IMAGE = deb-yq-go-${OS}:latest
	export VERSION_YQ = v4.45.2
	export VERSION_GO = 1.23
	export CODENAME = jammy
	PKG_REVISION = -1ubuntu1
	DOCKERFILE_PATH = ./Dockerfile.ubuntu-adduser
else
	$(warning CODENAME could not be determined (hint: was OS set?))
endif

# targets
HELP = help
SETUP = setup
DEB = deb
DEB_SIGN = deb-sign
CLEAN = clean

# executables
PYTHON = python
PIP = pip
PRE_COMMIT = pre-commit
NPM = npm
DOCKER = docker
GIT = git
GO = go

# simply expanded variables
executables := \
	${PYTHON}\
	${NPM}\
	${DOCKER}\
	${GIT}\
	${GO}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@printf '%s\n' 'Common make targets:'
>	@printf '%s\n' '  ${SETUP}                 - install the distro-independent dependencies for this'
>	@printf '%s\n' '                          repository'
>	@printf '%s\n' '  ${DEB}                   - make the repository'\''s debian packages'
>	@printf '%s\n' '  ${CLEAN}                 - remove files generated from targets'
>	@printf '%s\n' 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@printf '%s\n' '  OS                        - the operating system (e.g. ubuntu-24.04) to build'
>	@printf '%s\n' '                              packages for'
>	@printf '%s\n' '  DEBUG_PLAIN_STDOUT        - sets docker build to output in plain text'

.PHONY: ${SETUP}
${SETUP}:
>	${NPM} install
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install --requirement "./requirements-dev.txt"
>	${PRE_COMMIT} install

.PHONY: ${DEB}
${DEB}: docker_build_options = --file "${DOCKERFILE_PATH}" \
			--build-arg os="${CODENAME}" \
			--build-arg version_yq="${VERSION_YQ}" \
			--build-arg version_go="${VERSION_GO}" \
			--build-arg pkg_revision="${PKG_REVISION}" \
			--tag "${IMAGE}"
ifneq ($(findstring ${DEBUG_PLAIN_STDOUT},${TRUTHY_VALUES}),)
${DEB}: export BUILDKIT_PROGRESS = plain
${DEB}: docker_build_options += --no-cache
endif
ifneq (${NON_ROOT_UID},$(shell id --user))
${DEB}: docker_build_options += --build-arg host_uid="$$(id --user)"
${DEB}: docker_build_options += --build-arg host_gid="$$(id --group)"
endif
${DEB}:
>	./scripts/build-pkgs-deb ${docker_build_options}

.PHONY: ${DEB_SIGN}
${DEB_SIGN}:
>	${DOCKER} run \
		--rm \
		--tty \
		--interactive \
		--entrypoint "/bin/bash" \
		--env "GNUPGHOME=/build/yq/.gnupg" \
		--mount "type=bind,src=${CURDIR},dst=/build" \
		--mount "type=bind,src=$${HOME}/.gnupg,dst=/build/yq/.gnupg" \
		"${IMAGE}" \
		"-c" \
		'debsign --re-sign -k"1ABD9EFEA4F96AED898658E07F8676EF9143D3E8"'

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force yq-go_${VERSION_YQ#v}*
>	rm --recursive --force "${YQ_REPO_PATH}"
>	${DOCKER} rmi --force "${IMAGE}"
