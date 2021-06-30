# Containers
# start
declare -A start_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='start single service'
	['-i']='start idle'
	['-r']='stop first'
	['-d']='daemon; DEFAULT: true'
	['-d-']='docker-compose options'
	['-o-']='compose up options'
); function start() { # Start containers
	${_args[-r]} && _args_to orb docker stop -- -s 1

	local cmd=(
		$(_args_to orb docker compose_cmd -- -i 1 -d-)
		$(_args_to -es up -- -d -o-)
		$([[ -n ${_args[-s arg]} ]] && echo " --no-deps ${_args[-s arg]}")
	)

	orb docker set_current_env $1

	"${cmd[@]}"
}

# start
declare -A config_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-i']='start idle'
	['-d-']='docker-compose options'
	['-o-']='compose config options'
); function config() { # Start containers

	local cmd=(
		$(_args_to orb docker compose_cmd -- -i 1 -d-)
		$(_args_to -es config -- -o-)
	)

	orb docker set_current_env $1

	"${cmd[@]}"
}

# stop
declare -A stop_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='stop single service'
	['-d-']='docker-compose options'
	['-o-']='compose stop options'
); function stop() { # Stop containers
	local cmd=(
		$(_args_to orb docker compose_cmd -- 1 -d-)
		$(_args_to -es stop -- -o-)
		$([[ -n ${_args["-s arg"]} ]] && echo "${_args["-s arg"]}")
	)

	"${cmd[@]}"
}

# logs
declare -A logs_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: web'
	['-f']='follow; DEFAULT: true;'
	['-l arg']="lines; DEFAULT: 300"
	['-d-']='docker-compose options'
	['-o-']='docker logs options'
); function logs() { # Get container log
	local cmd=(
		$(_args_to orb docker compose_cmd -- 1 -d-)
		logs
		$(_args_to -es -- -f -o-)
		--tail "${_args[-l arg]}" ${_args[-s arg]}
	)

	"${cmd[@]}"
}

# clearlogs
declare -A clearlogs_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: web'
	['-d-']='docker-compose options'
); function clearlogs() { # Clear container logs
	local id=$(_args_to orb docker service_id -- 1 -s -d-)
	sudo truncate -s 0 $(docker inspect --format='{{.LogPath}}' "$id")
}

# rm
declare -A rm_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='rm single service'
	['-d-']='docker-compose options'
	['-o-']='compose rm options'
	['--force']='force; DEFAULT: true'
); function rm() { # Rm containers
	local cmd=(
		$(_args_to orb docker compose_cmd -- 1 -d-)
		$(_args_to -es rm -- --force -o-)
		$([[ -n ${_args["-s arg"]} ]] && echo "${_args["-s arg"]}")
	)

	"${cmd[@]}"
}

# pull
declare -A pull_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-d-']='docker-compose options'
	['-o-']='compose pull options'
); function pull() { # Pull compose project images
	orb set_current_env "$1"
	
	local cmd=(
		$(_args_to orb docker compose_cmd -- 1 -d-)
		$(_args_to -es pull -- -o-)
	)

	"${cmd[@]}"
}

# service_id
declare -A service_id_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; REQUIRED'
	['-d-']='docker-compose options'
	['-o-']='compose ps -q options'
); function service_id() {
	local cmd=(
		$(_args_to orb docker compose_cmd -- 1 -d-)
		$(_args_to -es ps -q -- -o- -s)
	)

	"${cmd[@]}"
}

# bash
declare -A bash_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: $DEFAULT_SERVICE; REQUIRED'
	['-r']='root'
	['-d']='detached, using run'
	['-d-']='docker-compose options'
	['*']='cmd; OPTIONAL'
); function bash() { # Enter container with bash or exec/run cmd
	# detached
	if ${_args[-d]}; then
		orb docker set_current_env $1
		cmd=( 
			$(_args_to orb docker compose_cmd -- 1 -d-) 
			run --no-deps --rm ${_args['-s arg']}
		)
	else
		cmd=( docker exec -it "$(_args_to orb docker service_id -- 1 -s -d-)")
	fi

	# root
	${_args[-r]} && cmd+=( --user 0 )
	
	# bash
	local bash_cmd=$(${_args['*']} && echo "-c \"${_args_wildcard[@]}\"")
	cmd+=( /bin/sh -c "[ -f /bin/bash ] && bash $bash_cmd || sh $bash_cmd" )
	orb docker set_current_env $1

	"${cmd[@]}"
}

# ssh
declare -A ssh_args=(
	['1']='subpath; IN: prod|staging|nginx|adminer; OPTIONAL'
	['-t']='ssh tty; DEFAULT: true'
	['-p arg']='path; DEFAULT: $SRV_REPO_PATH'
	['*']='cmd; OPTIONAL'
); function ssh() { # Run command on remote
	cmd+=(
		$(_args_to -e /bin/ssh -- -t)
		"${SRV_USER}@${SRV_DOMAIN}" PATH="\$PATH:~/.orb-cli/orb-cli"\; cd "${_args['-p arg']}/${_args[1]}" '&&' 
		$(_args_to -e -- '*')
	)
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
	['1']='env; IN: prod|staging|dev'
	['-i']='start idle'
	['-d-']='docker-compose options'
); function compose_cmd() { # Init compose_cmd with correct compose files
	_args_to -sa cmd docker-compose -- -d-

	if [[ -f "docker-compose.$1.yml" ]]; then
		cmd+=( -f docker-compose.yml -f docker-compose.$1.yml )

		if ${_args[-i]}; then # idle
			[[ -f "docker-compose.idle.yml" ]] && \
			cmd+=( -f docker-compose.idle.yml )
		fi
	fi

	echo "${cmd[@]}" # return cmd to stdout
}

# set_current_env
declare -A set_current_env_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
); function set_current_env() { # export current env vars
	export CURRENT_ENV=$1
	export CURRENT_ID=$(id -u)
	export CURRENT_GID=$(id -g)
}

