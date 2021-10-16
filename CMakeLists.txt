cmake_minimum_required(VERSION 3.2)

project(mamba-test)

include(micromamba.cmake)

ensure_micromamba(MICROMAMBA_BIN)

micromamba_environment(
CHANNELS
	conda-forge
	# robostack
DEPENDENCIES
	spdlog
)

set(CMAKE_CXX_STANDARD 17)
find_package(spdlog REQUIRED)

add_executable(test src/test.cpp)
target_link_libraries(test spdlog)