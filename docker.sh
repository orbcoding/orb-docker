#!/bin/bash
list_orb=("List containers and images")
function list()  {
	docker ps -a
	echo
	docker images
}

df_orb=("Get docker disk usage")
function df() {
	docker system df
}

pruneall_orb=(
	"Prune all stopped and unused including volumes"
	-f = force
); 
function pruneall() {
	orb_pass docker system prune --all --volumes -- -f
}

prunecontainers_orb=(
	"Prune all stopped containers"

	-f = force
); 
function prunecontainers() {
	orb_pass docker container prune -- -f
}

pruneimages_orb=(
	"remove all images"

	-f = force
); function pruneimages() {
	orb_pass docker image prune -- -f
}

stopall_orb=(
	"stop all containers"
)
function stopall() {
	local prev=$(docker ps -a -q)
	[[ -n $prev ]] && docker stop "$prev" || echo 'none to stop'
}

# Image
rebuild_orb=(
	'Rebuild image $ORB_BUILD_IMAGE from _docker (.env)'
)
function rebuild() {
	local path
	[ -d _docker ] && path=_docker || path=.
	docker build --rm --build-arg BUILD_PARENT_IMAGE="$ORB_BUILD_PARENT_IMAGE" --build-arg BUILD_ENV="$ORB_BUILD_ENV" "$path" -t "$(build_image_name)"
}


runimage_orb=(
	"Run built image"
	... = cmd
)
function runimage() {
	docker run -it --rm $(build_image_name) bash -c "${cmd[@]}"
}

push_orb=(
	'Push rebuilt image $ORB_BUILD_IMAGE to docker hub'
)
function push() {
	docker login
	docker push "$(build_image_name)"
}

build_image_name() {
	local name="$ORB_BUILD_IMAGE"
	[[ -n $ORB_BUILD_ENV ]] && name+="_$ORB_BUILD_ENV"
	echo "$name"
	docker push $ORB_BUILD_IMAGE
}
