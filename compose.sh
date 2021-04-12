# Containers
# start
declare -A start_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='start single service'
	['-i']='start idle'
	['-r']='stop first'
); function start() { # Start containers
	if ${_args[-r]}; then
		local stop_cmd=( orb docker stop )
		 _args_to stop_cmd -x -- -s 1
	fi

	local compose_cmd=( orb docker compose_cmd )
	_args_to compose_cmd -- -i 1

	local cmd=(
		$("${compose_cmd[@]}")
		up -d
		$([[ -n ${_args[-s arg]} ]] && echo " --no-deps ${_args[-s arg]}")
	)

	orb docker set_current_env $1

	echo "${cmd[@]}"

	"${cmd[@]}"
}

# stop
declare -A stop_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='stop single service'
); function stop() { # Stop containers
	local cmd=( $(orb docker compose_cmd "$1") stop )
	[[ -n ${_args["-s arg"]} ]] && cmd+=( "${_args["-s arg"]}" )
	"${cmd[@]}"
}

# logs
declare -A logs_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: web'
	['-f']='follow; DEFAULT: true;'
	['-l arg']="lines; DEFAULT: 300"
); function logs() { # Get container log
	local cmd=( $(orb docker compose_cmd "$1") logs )
	_args_to cmd -- -f
	cmd+=( --tail "${_args[-l arg]}" ${_args[-s arg]} )
	"${cmd[@]}"
}

# clearlogs
declare -A clearlogs_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: web'
); function clearlogs() { # Clear container logs
	local service_cmd=( orb docker service_id )
	_args_to service_cmd -- 1 -s
	sudo truncate -s 0 $(docker inspect --format='{{.LogPath}}' $( "${service_cmd[@]}" ))
}

# rm
declare -A rm_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='rm single service'
); function rm() { # Rm containers
	local cmd=( $(orb docker compose_cmd "$1") rm --force )
	[[ -n ${_args["-s arg"]} ]] && cmd+=( "${_args["-s arg"]}" )
	"${cmd[@]}"
}

# pull
declare -A pull_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
); function pull() { # Pull compose project images
	orb set_current_env "$1"
	$(orb docker compose_cmd "$1") pull
}


# service_id
declare -A service_id_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; REQUIRED'
); function service_id() {
	$(orb docker compose_cmd "$1") ps -q "${_args[-s arg]}"
}


# bash
declare -A bash_args=(
	['1']='env; DEFAULT: $DEFAULT_ENV|dev; IN: prod|staging|dev'
	['-s arg']='service; DEFAULT: $DEFAULT_SERVICE; REQUIRED'
	['-r']='root'
	['-d']='detached, using run'
	['*']='cmd; OPTIONAL'
); function bash() { # Enter container with bash or exec/run cmd
	local cmd=( $(orb docker compose_cmd $1) )

	# detached
	if ${_args[-d]}; then
		orb docker set_current_env $1
		cmd+=( run --no-deps --rm )
	else
		cmd+=( exec )
	fi
	# root
	${_args[-r]} && cmd+=( --user 0 )
	# service
	cmd+=( ${_args['-s arg']} )
	# bash
	local bash_cmd=$(${_args['*']} && echo "-c \"${_args_wildcard[*]}\"")
	cmd+=( /bin/sh -c "[[ ! -f /bin/bash ]] && alias bash=/bin/sh; bash $bash_cmd")
	# exec
	"${cmd[@]}"
}

# ssh
declare -A ssh_args=(
	['1']='subpath; IN: prod|staging|nginx|adminer; OPTIONAL'
	['-t']='ssh tty; DEFAULT: true'
	['-p arg']='path; DEFAULT: $SRV_REPO_PATH'
	['*']='cmd; OPTIONAL'
); function ssh() { # Run command on remote
	local cmd=( /bin/ssh )
	_args_to cmd -- -t
	cmd+=( "${SRV_USER}@${SRV_DOMAIN}" PATH="\$PATH:~/.orb-cli/orb-cli"\; cd "${_args['-p arg']}/${_args[1]}" '&&' )
	${_args['*']} && cmd+=( ${_args_wildcard[*]} ) || cmd+=( /bin/bash )
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
); function compose_cmd() { # Init compose_cmd with correct compose files
	local cmd

	if [[ ! -f "docker-compose.$1.yml" ]]; then
		cmd=( docker-compose ) # start without envs
	else
		cmd=( docker-compose -f docker-compose.yml -f docker-compose.$1.yml )

		if [[ "${_args[-i]}" == true ]]; then # idle
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

