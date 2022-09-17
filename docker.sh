#!/bin/bash
function list()  { # List containers and images
	docker ps -a
	echo
	docker images
}

function df() { # Get docker disk usage
	docker system df
}

declare -A pruneall_args=(
	['-f']='force'
); function pruneall() { # Prune all stopped and unused including volumes
	_args_to docker system prune --all --volumes -- -f
}

declare -A prunecontainers_args=(
	['-f']='force'
); function prunecontainers() { # Prune all stopped containers, -f = force
	_args_to docker container prune -- -f
}

declare -A pruneimages_args=(
	['-f']='force'
); function pruneimages() { # remove all images, -f = force
	_args_to docker image prune -- -f
}

function stopall() { # stop all containers
	local prev=$(docker ps -a -q)
	[[ -n $prev ]] && docker stop "$prev" || echo 'none to stop'
}

# Image
function rebuild() { # Rebuild image $BUILD_IMAGE from _docker (.env)
	local path
	[ -d _docker ] && path=_docker || path=.
	docker build --rm --build-arg BUILD_PARENT_IMAGE="$BUILD_PARENT_IMAGE" --build-arg BUILD_ENV="$BUILD_ENV" "$path" -t "$(build_image_name)"
}

function runimage() { # Run built image
	docker run -it --rm $(build_image_name) bash -c "${_args[*]}"
}

function push() { # Push rebuilt image $BUILD_IMAGE to docker hub
	docker login
	docker push "$(build_image_name)"
}

build_image_name() {
	local name="$BUILD_IMAGE"
	[[ -n $BUILD_ENV ]] && name+="_$BUILD_ENV"
	echo "$name"
}
