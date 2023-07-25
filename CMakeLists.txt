cmake_minimum_required(VERSION 3.2)

project(mamba-test)

include(micromamba.cmake)

ensure_micromamba(MICROMAMBA_BIN)

# Configure an environment directly
micromamba_environment(
NAME environment		# Name of the environment
CHANNELS				# Channels to pull packages from
	conda-forge
	# robostack
DEPENDENCIES			# List of dependencies to install
	spdlog
)

# Or configure it with a spec file
micromamba_environment(
	NAME configenv			# Name of the environment
	SPEC_FILE config.yaml   # Spec file to create the environment with
	RUN_CMD CONFIGENV_RUN   # On return - ${CONFIGENV_RUN} will be a command that runs commands within the environment
	ENV_PATH CONFIGENV_PATH # On return - ${CONFIGENV_PATH} will be the path to the environment
	NO_PREFIX_PATH			# Do not add this environment to the CMAKE_PREFIX_PATH
)

# Now you can run commands within the micromamba environment at configuration or build time
execute_process(
	COMMAND ${CONFIGENV_RUN} python -c "import sys; print('Running this under mamba: ', sys.executable)"
)

set(CMAKE_CXX_STANDARD 17)
find_package(spdlog REQUIRED)


add_executable(test src/test.cpp)
target_link_libraries(test spdlog::spdlog)
