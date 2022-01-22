# Move to closest docker-compose
compose_file=$(orb_upfind_closest docker-compose.yml)

if [[ -n  "$compose_file" ]]; then
  # https://stackoverflow.com/a/4170409
	compose_path="${compose_file%\/*}"
	cd "$compose_path"

# compose functions require docker-compose.yml
elif [[ "${_file_with_function##*\/}" == "compose.sh" ]]; then
	orb_raise_error "requires docker-compose.yml"
fi

# Parse .env
if [ -f '.env' ]; then
	orb_parse_env .env
fi
