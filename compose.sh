# Containers
# start
start_orb=(
	"Start containers"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service "start single service"
	-i = idle
	-r = restart "stop first"
	-d = daemon
		Default: true
	-d- = compose_opts "docker-compose opts"
	-o- = up_opts "docker-compose up options"
);
function start() {
	$restart && orb_pass orb docker stop -- -es

	local cmd=($(orb_pass orb docker compose_cmd -- -ei -d-))
	orb_pass -va cmd up -- -d -o-
	[[ -n $service ]] && cmd+=(--no-deps $service)

	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# start
config_orb=(
	"Container config"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-i = idle
	-d- = compose_opts "docker-compose opts"
	-o- = up_opts "docker-compose up options"
);
function config() {
	local cmd=($(orb_pass orb docker compose_cmd -- -ei -d-))
	orb_pass -va cmd config -- -o-

	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# stop
stop_orb=(
	"Stop containers"
	
	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service "start single service"
	-d- = compose_opts "docker-compose opts"
	-o- = up_opts "docker-compose up options"
);
function stop() {
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -va cmd stop -- -s -o-
	orb_pass -x orb docker set_current_env -- -e


	"${cmd[@]}"
}

# logs
logs_orb=(
	"Get container log"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service
		Default: IfPresent: '$ORB_DEFAULT_SERVICE'
		Required: true
	-f = follow
		Default: true
	-l 1 = lines
		Default: 300
	-d- = compose_opts "docker-compose opts"
	-o- = up_opts "docker-compose up options"
);
function logs() {
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -va cmd logs -- -f -o-
	cmd+=(--tail "$lines" $service)
	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# clearlogs
clearlogs_orb=(
	"Clear container logs"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service
		Required: true
	-d- = compose_opts "docker-compose opts"
);
function clearlogs() { #
	local id=$(orb_pass orb docker service_id -- -es -d-)
	sudo truncate -s 0 $(docker inspect --format='{{.LogPath}}' "$id")
}

# rm
rm_orb=(
	"Rm containers"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service 'rm single service'
	-d- = compose_opts 'docker-compose options'
	-o- = rm_opts 'compose rm options'
	--force = force
		Default: true
);
function rm() {
	orb_pass -x orb docker set_current_env -- -e

	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
  orb_pass -va cmd rm -- --force -o- -s
	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# pull
pull_orb=(
	"Pull compose project images"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-d- = compose_opts 'docker-compose options'
	-o- = pull_opts 'compose pull options'
); 
function pull() {
	orb_pass -x orb docker set_current_env -- -e

	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -va cmd pull -- -o-

	"${cmd[@]}"
}

# service_id
service_id_orb=(
	"Get service id"

		-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service 'service to id'
		Default: IfPresent: '$ORB_DEFAULT_SERVICE'
		Required: true
	-d- = compose_opts 'docker-compose options'
	-o- = ps_opts 'compose ps -q options'
); 
function service_id() {
	orb_pass -x orb docker set_current_env -- -e
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -va cmd ps -q -- -o- -s

	"${cmd[@]}"
}

# bash
bash_orb=(
	"Enter container with bash or exec/run cmd"

	-e 1 = env
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
	-s 1 = service 'service to id'
		Default: "$ORB_DEFAULT_SERVICE"
		Required: true
	-u 1 = user
	-d = detached "detached, using run"
	-t = tty
		Default: true
	-i = interactive "interactive, disable if job management error"
		Default: true
	-d- = compose_opts "docker-compose options"
	... = input_cmd
		Required: false
); 
function bash() {
	# detached
	local cmd=()

	if $detached; then
		orb_pass -x orb docker set_current_env -- -e
		cmd+=(
			$(orb_pass orb docker compose_cmd -- -e -d-)
			run --no-deps --rm $service
		)
	else
		cmd+=( docker exec -i )
		orb_pass -a cmd -- -tu
		cmd+=( "$(orb_pass orb docker service_id -- -es -d-)")
	fi

	local bash_flags="-c"
	$interactive && bash_flags+="i"

	# bash
	local bash_cmd=$([[ -n ${input_cmd[@]} ]] && echo "$bash_flags \"${input_cmd[@]}\"")
	cmd+=( /bin/sh $bash_flags "[ -f /bin/bash ] && bash $bash_cmd || sh $bash_cmd" )
	orb_pass -x orb docker set_current_env -- -e
	
	"${cmd[@]}"
}

# ssh
ssh_orb=(
	"Run command on remote"

	1 = subpath
		In: production staging nginx adminer
		Required: false
	-t = tty Default: true
	-u 1 = user Default: IfPresent: '$ORB_SRV_USER'
		Required: true
	-d 1 = domain Default: IfPresent: '$ORB_SRV_DOMAIN'	
		Required: true
	-P 1 = path Default: IfPresent: '$ORB_SRV_REPO_PATH'
		Required: true
	-p 1 = port Default: IfPresent: '$ORB_SRV_PORT'
	... = input_cmd
		Required: false
); 
function ssh() {
	cmd=( /bin/ssh )
	orb_pass -a cmd -- -tp

	cmd+=(
		"${ORB_SRV_USER}@${ORB_SRV_DOMAIN}" PATH="\$PATH:~/.orb/orb"\;
		cd "$path/$subpath" '&&'
	)

	orb_pass -a cmd -- ...
	[[ -n "${input_cmd[@]}" ]] || cmd+=( /bin/bash )

	"${cmd[@]}"
}

###########
# Remote
###########
mountremote_orb=(
	"Mount remote to _remote"
)
function mountremote() {
	if [ -d _remote ]; then
		sshfs -o follow_symlinks ${ORB_SRV_USER}@${ORB_SRV_DOMAIN}:${ORB_SRV_REPO_PATH} _remote
	else
		echo 'No _remote'
	fi
}

umountremote_orb=(
	"Umount _remote"
)
function umountremote() {
	umount -l _remote
}

updateremotecli_orb=(
	"Update remote orb"
)
function updateremotecli() {
	orb docker ssh -p ".orb" "orb git pullall"
}

##########
# HELPERS
##########
# compose_cmd
compose_cmd_orb=(
	"Init compose_cmd with correct compose files"

	-e 1 = env
		In: production staging development
		Required: true
	-i = idle
	-o- = compose_opts_override
		Default: IfPresent: '$COMPOSE_OPTIONS_OVERRIDE'
	-d- = compose_opts_add
); function compose_cmd() {
	local cmd=()
	orb_pass -va cmd docker-compose -- -o- -d-

	if [[ -z "${compose_opts_override[@]}" ]]; then
		if [[ -f "docker-compose.$env.yml" ]]; then
			cmd+=( -f docker-compose.yml -f docker-compose.$env.yml )

			if $idle; then
				[[ -f "docker-compose.idle.yml" ]] && \
				cmd+=( -f docker-compose.idle.yml )
			fi
		fi
	fi

	echo "${cmd[@]}" # return cmd to stdout
}

# set_current_env
set_current_env_orb=(
	"export current env vars"

	-e 1 = env 
		Default: IfPresent: '$ORB_DEFAULT_ENV || development'
		In: production staging development
); function set_current_env() { # 
	export ORB_CURRENT_ENV="$env"
	export ORB_CURRENT_ID=$(id -u)
	export ORB_CURRENT_GID=$(id -g)
}

