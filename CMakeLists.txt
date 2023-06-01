cmake_minimum_required(VERSION 3.2)

project(mamba-test)

include(micromamba.cmake)

ensure_micromamba(MICROMAMBA_BIN)

# Configure an environment directly
micromamba_environment(
NAME environment
CHANNELS
	conda-forge
	# robostack
DEPENDENCIES
	spdlog
)

# Or configure it with a config file
micromamba_environment(
	NAME configenv
	SPEC_FILE config.yaml
	RUN_CMD CONFIGENV_RUN
	ENV_PATH CONFIGENV_PATH
	NO_PREFIX_PATH
	VERBOSE 3
)

# Now you can run commands within the micromamba environment at configuration or build time
execute_process(
	COMMAND ${CONFIGENV_RUN} python -c "import sys; print('Running this under mamba: ', sys.executable)"
)

set(CMAKE_CXX_STANDARD 17)
find_package(spdlog REQUIRED)


add_executable(test src/test.cpp)
target_link_libraries(test spdlog::spdlog)
