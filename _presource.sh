# Move to closest docker-compose
compose_file=$(_upfind_closest docker-compose.yml)

if [[ -n  "$compose_file" ]]; then
	cd "${compose_file/%\/*}"

	# Parse .env
	if [ -f '.env' ]; then
		_parse_env .env
	fi

# compose functions require docker-compose.yml
elif [[ -f "$_namespace_dir/compose.sh" ]] && _has_public_function "$_function_name" "$_namespace_dir/compose.sh"; then
	_raise_error "requires docker-compose.yml"
fi

