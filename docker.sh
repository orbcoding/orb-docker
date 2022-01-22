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
	orb_pass docker system prune --all --volumes -- -f
}

declare -A prunecontainers_args=(
	['-f']='force'
); function prunecontainers() { # Prune all stopped containers, -f = force
	orb_pass docker container prune -- -f
}

declare -A pruneimages_args=(
	['-f']='force'
); function pruneimages() { # remove all images, -f = force
	orb_pass docker image prune -- -f
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
