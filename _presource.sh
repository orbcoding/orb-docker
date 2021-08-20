# Move to closest docker-compose
compose_file=$(_upfind_closest docker-compose.yml)

if [[ -n  "$compose_file" ]]; then
  # https://stackoverflow.com/a/4170409
	compose_path="${compose_file%\/*}"
	cd "$compose_path"

	# Parse .env
	if [ -f '.env' ]; then
		_parse_env .env
	fi

# compose functions require docker-compose.yml
elif [[ "${_file_with_function##*\/}" == "compose.sh" ]]; then
	_raise_error "requires docker-compose.yml"
fi

