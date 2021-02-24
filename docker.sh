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
	local cmd=( docker system prune --all --volumes )
	_args_to cmd -x -- -f
}

declare -A prunecontainers_args=(
	['-f']='force'
); function prunecontainers() { # Prune all stopped containers, -f = force
	local cmd=( docker container prune )
	_args_to cmd -x -- -f
}

declare -A pruneimages_args=(
	['-f']='force'
); function pruneimages() { # remove all images, -f = force
	local cmd=( docker image prune )
	_args_to cmd -x -- -f
}

function stopall() { # stop all containers
	local prev=$(docker ps -a -q)
	[[ -n $prev ]] && docker stop "$prev" || echo 'none to stop'
}

# Image
function rebuild() { # Rebuild image $BUILD_IMAGE from _docker (.env)
	local path
	[ -d _docker ] && path=_docker || path=.
	docker build --rm --build-arg PARENT_IMAGE="$PARENT_IMAGE" "$path" -t "$BUILD_IMAGE"
}

function runimage() { # Run built image
	docker run -it --rm "$BUILD_IMAGE" bash -c "${_args[*]}"
}

function push() { # Push rebuilt image $BUILD_IMAGE to docker hub
	docker login
	docker push $BUILD_IMAGE
}
