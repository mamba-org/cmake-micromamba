function(mamba_get_native_arch MAMBA_NATIVE_ARCH)
  if (CMAKE_HOST_APPLE)
    if(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "arm")
      set (ARCH "osx-arm64")
    else()
      set (ARCH "osx-64")
    endif()
  elseif(CMAKE_HOST_UNIX)
    if(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "x64|x86_64")
      set (ARCH "linux-64")
    elseif(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "aarch64|arm64")
      set (ARCH "linux-aarch64")
    endif()
  # elseif(CMAKE_HOST_WIN32)
  #   if(${CMAKE_HOST_SYSTEM_PROCESSOR} MATCHES "ARM64")
  #     set (${MAMBA_NATIVE_ARCH} "win-64")
  #   endif()
  endif()

  if(DEFINED ARCH)
    set(${MAMBA_NATIVE_ARCH} ${ARCH} PARENT_SCOPE)
  endif()

endfunction()

# Ensures the micromamba binary is available
# Arguments:
#  MICROMAMBA_BIN: Name of the variable to store the path to the micromamba binary
function(ensure_micromamba MICROMAMBA_BIN)
  set(MICROMAMBA_PATH ${CMAKE_BINARY_DIR}/micromamba_bin)

  find_program(_MICROMAMBA_BIN micromamba
    PATHS ${MICROMAMBA_PATH}/bin
  )
  if (_MICROMAMBA_BIN)
    message("Found micromamba at ${_MICROMAMBA_BIN}")
  else()
    message("Downloading micromamba")
    mamba_get_native_arch(MAMBA_NATIVE_ARCH)
    message("Native arch: ${MAMBA_NATIVE_ARCH}")
    file(MAKE_DIRECTORY ${MICROMAMBA_PATH}/bin)
    file(DOWNLOAD "https://micro.mamba.pm/api/micromamba/${MAMBA_NATIVE_ARCH}/latest" ${MICROMAMBA_PATH}/micromamba.tar.bz2)
    execute_process(COMMAND
      ${CMAKE_COMMAND} -E
      tar xvzf ${MICROMAMBA_PATH}/micromamba.tar.bz2 -- "bin/micromamba"
      WORKING_DIRECTORY ${MICROMAMBA_PATH} )
  endif()
  set (${MICROMAMBA_BIN} ${_MICROMAMBA_BIN} PARENT_SCOPE)
endfunction()

# Checks if a micromamba environment exists
# Arguments:
#   ENV_NAME: Name of the environment
#   OUTVAR: Name of the variable to store the result
function(check_micromamba_environment ENV_NAME OUTVAR)
  set(ENV_PATH ${CMAKE_BINARY_DIR}/environments/${ENV_NAME})
  if (EXISTS "${ENV_PATH}/conda-meta/history" )
    set(${OUTVAR} TRUE PARENT_SCOPE)
  else()
    unset(${OUTVAR} PARENT_SCOPE)
  endif()
endfunction()
  

# Create a micromamba environment
#
# Arguments:
#   NAME: Name of the environment
#   VERBOSE: Verbosity level (0, 1, 2, 3)
#   RUN_CMD: Name of the variable to store the command for running command within the environment
#   ENV_PATH: Name of the variable to store the path to the environment
#   CHANNELS: List of channels to use
#   DEPENDENCIES: List of dependencies to install
#   SPEC_FILE: List of spec files to use
#   NO_PREFIX_PATH: Do not add the environment path to the list of prefix paths
#   NO_DEPENDS: Do not add the spec files to the configuration dependencies
#
function(micromamba_environment)
    cmake_parse_arguments(
        PARSED_ARGS # prefix of output variables
        "NO_PREFIX_PATH;NO_DEPENDS" # list of names of the boolean arguments (only defined ones will be true)
        "NAME;VERBOSE;RUN_CMD;ENV_PATH" # list of names of mono-valued arguments
        "CHANNELS;DEPENDENCIES;SPEC_FILE" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )

  # Parse the arguments
  set(ENV_NAME "environment")
  if(DEFINED PARSED_ARGS_NAME)
    set(ENV_NAME ${PARSED_ARGS_NAME})
  endif()

  set(VERBOSE_FLAG "--quiet")
  if(PARSED_ARGS_VERBOSE EQUAL 0)
    set(VERBOSE_FLAG "--quiet")
  elseif(PARSED_ARGS_VERBOSE EQUAL 1)
    set(VERBOSE_FLAG "")
  elseif(PARSED_ARGS_VERBOSE EQUAL 2)
    set(VERBOSE_FLAG "--verbose")
  elseif(PARSED_ARGS_VERBOSE EQUAL 3)
    set(VERBOSE_FLAG "-vv")
  endif()

  set (CHANNEL_ARG "")
  foreach(C ${PARSED_ARGS_CHANNELS})
    list(APPEND CHANNEL_ARG "-c")
    list(APPEND CHANNEL_ARG ${C})
  endforeach()

  set (FILE_ARG "")
  foreach(F ${PARSED_ARGS_SPEC_FILE})
    list(APPEND FILE_ARG "--file")
    list(APPEND FILE_ARG ${F})
  endforeach()
  
  set(ENV_PATH ${CMAKE_BINARY_DIR}/environments/${ENV_NAME})

  ensure_micromamba(MICROMAMBA_BIN)

  check_micromamba_environment(${ENV_NAME} ENV_EXISTS)

  if(ENV_EXISTS)
    message("Updating micromamba environment '${ENV_NAME}' at ${ENV_PATH}")
    execute_process(COMMAND echo
    ${MICROMAMBA_BIN} install -p ${ENV_PATH} ${CHANNEL_ARG} ${FILE_ARG} ${PARSED_ARGS_DEPENDENCIES} --yes ${VERBOSE_FLAG}
    )
    execute_process(COMMAND
    ${MICROMAMBA_BIN} install -p ${ENV_PATH} ${CHANNEL_ARG} ${FILE_ARG} ${PARSED_ARGS_DEPENDENCIES} --yes ${VERBOSE_FLAG}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
  else()
    message("Creating micromamba environment '${ENV_NAME}' at ${ENV_PATH} - this may take a while")
    execute_process(COMMAND echo
      ${MICROMAMBA_BIN} create -p ${ENV_PATH} ${CHANNEL_ARG} ${FILE_ARG} ${PARSED_ARGS_DEPENDENCIES} --yes ${VERBOSE_FLAG})
    execute_process(COMMAND
      ${MICROMAMBA_BIN} create -p ${ENV_PATH} ${CHANNEL_ARG} ${FILE_ARG} ${PARSED_ARGS_DEPENDENCIES} --yes ${VERBOSE_FLAG}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
  endif()
  
  # Add the spec files to the list of files to watch for changes
  if(NOT DEFINED PARSED_ARGS_NO_DEPENDS)
    set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${PARSED_ARGS_SPEC_FILE})
  endif()

  # Add the environment path to the list of prefix paths
  if(NOT PARSED_ARGS_NO_PREFIX_PATH)
    set(CMAKE_INSTALL_PREFIX ${ENV_PATH} CACHE INTERNAL "CMAKE_INSTALL_PREFIX")
    list(PREPEND CMAKE_PREFIX_PATH ${ENV_PATH})
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} PARENT_SCOPE)
  endif()

  if(DEFINED PARSED_ARGS_RUN_CMD)
    list(APPEND RUN_CMD ${MICROMAMBA_BIN} -p ${ENV_PATH} run )
    set(${PARSED_ARGS_RUN_CMD} ${RUN_CMD} PARENT_SCOPE)
  endif()

  if(DEFINED PARSED_ARGS_ENV_PATH)
    set(${PARSED_ARGS_ENV_PATH} ${ENV_PATH} PARENT_SCOPE)
  endif()

endfunction()
