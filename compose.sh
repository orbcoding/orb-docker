# Containers
# start
declare -A start_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='start single service'
	['-i']='start idle'
	['-r']='stop first'
	['-d']='daemon; DEFAULT: true'
	['-d-']='docker-compose options'
	['-o-']='compose up options'
); function start() { # Start containers
	${_args[-r]} && orb_pass orb docker stop -- -es

	local cmd=($(orb_pass orb docker compose_cmd -- -ei -d-))
	orb_pass -sa cmd up -- -d -o-
	[[ -n ${_args['-s arg']} ]] && cmd+=(--no-deps ${_args['-s arg']})

	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# start
declare -A config_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'
	['-i']='start idle'
	['-d-']='docker-compose options'
	['-o-']='compose config options'
); function config() { # Start containers
	local cmd=($(orb_pass orb docker compose_cmd -- -ei -d-))
	orb_pass -sa cmd config -- -o- 

	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# stop
declare -A stop_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='stop single service'
	['-d-']='docker-compose options'
	['-o-']='compose stop options'
); function stop() { # Stop containers
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -sa cmd stop -- -s -o-

	"${cmd[@]}"
}

# logs
declare -A logs_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='service; DEFAULT: $DEFAULT_SERVICE; REQUIRED'
	['-f']='follow; DEFAULT: true;'
	['-l arg']="lines; DEFAULT: 300"
	['-d-']='docker-compose options'
	['-o-']='docker logs options'
); function logs() { # Get container log
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -sa cmd logs -- -f -o-
	cmd+=(--tail "${_args[-l arg]}" ${_args[-s arg]})

	"${cmd[@]}"
}

# clearlogs
declare -A clearlogs_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='service; REQUIRED'
	['-d-']='docker-compose options'
); function clearlogs() { # Clear container logs
	local id=$(orb_pass orb docker service_id -- -es -d-)
	sudo truncate -s 0 $(docker inspect --format='{{.LogPath}}' "$id")
}

# rm
declare -A rm_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='rm single service'
	['-d-']='docker-compose options'
	['-o-']='compose rm options'
	['--force']='force; DEFAULT: true'
); function rm() { # Rm containers
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
  orb_pass -sa cmd rm -- --force -o- -s

	"${cmd[@]}"
}

# pull
declare -A pull_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-d-']='docker-compose options'
	['-o-']='compose pull options'
); function pull() { # Pull compose project images
	orb_pass -x orb docker set_current_env -- -e
	
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -sa cmd pull -- -o-

	"${cmd[@]}"
}

# service_id
declare -A service_id_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='service; DEFAULT: $DEFAULT_SERVICE; REQUIRED'
	['-d-']='docker-compose options'
	['-o-']='compose ps -q options'
); function service_id() {
	local cmd=($(orb_pass orb docker compose_cmd -- -e -d-))
	orb_pass -sa cmd ps -q -- -o- -s

	"${cmd[@]}"
}

# bash
declare -A bash_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'	
	['-s arg']='service; DEFAULT: $DEFAULT_SERVICE; REQUIRED'
	['-u arg']='user'
	['-d']='detached, using run'
	['-t']='TTY; DEFAULT: true'
	['-i']='interactive (disable if job management error); DEFAULT: true'
	['-d-']='docker-compose options'
	['*']='cmd; OPTIONAL'
); function bash() { # Enter container with bash or exec/run cmd
	# detached
	local cmd=()

	if ${_args[-d]}; then
		orb_pass -x orb docker set_current_env -- -e
		cmd+=( 
			$(orb_pass orb docker compose_cmd -- -e -d-) 
			run --no-deps --rm ${_args['-s arg']}
		)
	else
		cmd+=( docker exec -i )
		orb_pass -a cmd -- -tu
		cmd+=( "$(orb_pass orb docker service_id -- -es -d-)")
	fi
	
	local bash_flags="-c"
	[[ "${_args[-i]}" == "true" ]] && bash_flags+="i"

	# bash
	local bash_cmd=$(${_args['*']} && echo "$bash_flags \"${_orb_wildcard[@]}\"")
	cmd+=( /bin/sh $bash_flags "[ -f /bin/bash ] && bash $bash_cmd || sh $bash_cmd" )
	orb_pass -x orb docker set_current_env -- -e

	"${cmd[@]}"
}

# ssh
declare -A ssh_args=(
	['1']='subpath; IN: production|staging|nginx|adminer; OPTIONAL'
	['-t']='ssh tty; DEFAULT: true'
	['-u arg']='user; DEFAULT: $SRV_USER; REQUIRED'
	['-d arg']='domain; DEFAULT: $SRV_DOMAIN; REQUIRED'
	['-p arg']='path; DEFAULT: $SRV_REPO_PATH; REQUIRED'
	['*']='cmd; OPTIONAL'
); function ssh() { # Run command on remote
	cmd=( /bin/ssh )
	orb_pass -a cmd -- -t

	cmd+=(
		"${SRV_USER}@${SRV_DOMAIN}" PATH="\$PATH:~/.orb-cli/orb-cli"\; 
		cd "${_args['-p arg']}/${_args[1]}" '&&' 
	)

	orb_pass -a cmd -- '*'
	${_args['*']} || cmd+=( /bin/bash )


	"${cmd[@]}"
}

###########
# Remote
###########
function mountremote() { # Mount remote to _remote
	if [ -d _remote ]; then
		sshfs -o follow_symlinks ${SRV_USER}@${SRV_DOMAIN}:${SRV_REPO_PATH} _remote
	else
		echo 'No _remote'
	fi
}

function umountremote() { # Umount _remote
	umount -l _remote
}

function updateremotecli() { # Update remote orb-cli
	orb docker ssh -p ".orb-cli" "orb git pullall"
}

##########
# HELPERS
##########
# compose_cmd
declare -A compose_cmd_args=(
	['-e arg']='env; IN: production|staging|development'
	['-i']='start idle'
	['-o-']='compose options override; DEFAULT: $COMPOSE_OPTIONS_OVERRIDE'
	['-d-']='compose options addition'
); function compose_cmd() { # Init compose_cmd with correct compose files
	local cmd=() 
	orb_pass -sa cmd docker-compose -- -o- -d-

	if [[ -z "${_args[-o-]}" ]]; then
		if [[ -f "docker-compose.${_args[-e arg]}.yml" ]]; then
			cmd+=( -f docker-compose.yml -f docker-compose.${_args[-e arg]}.yml )

			if ${_args[-i]}; then # idle
				[[ -f "docker-compose.idle.yml" ]] && \
				cmd+=( -f docker-compose.idle.yml )
			fi
		fi
	fi

	echo "${cmd[@]}" # return cmd to stdout
}

# set_current_env
declare -A set_current_env_args=(
	['-e arg']='env; DEFAULT: $DEFAULT_ENV|development; IN: production|staging|development'
); function set_current_env() { # export current env vars
	export CURRENT_ENV="${_args[-e arg]}"
	export CURRENT_ID=$(id -u)
	export CURRENT_GID=$(id -g)
}

