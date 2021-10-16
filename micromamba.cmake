function(mamba_get_native_arch MAMBA_NATIVE_ARCH)
  if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "arm")
      set (${MAMBA_NATIVE_ARCH} "osx-arm64" PARENT_SCOPE)
    else()
      set (${MAMBA_NATIVE_ARCH} "osx-64" PARENT_SCOPE)
    endif()
  endif()
endfunction()

function(ensure_micromamba MICROMAMBA_BIN)
	message("Hello micromamba")
  find_program(_MICROMAMBA_BIN micromamba
    PATHS micromamba_bin/bin
  )
  message("Found micromamba at ${_MICROMAMBA_BIN}")
  if (_MICROMAMBA_BIN)
    message("Found micromamba at ${_MICROMAMBA_BIN}")
  else()
    message("Downloading micromamba")
    mamba_get_native_arch(MAMBA_NATIVE_ARCH)
    message("Native arch: ${MAMBA_NATIVE_ARCH}")
    file(MAKE_DIRECTORY "micromamba_bin")
    file(DOWNLOAD "https://micro.mamba.pm/api/micromamba/${MAMBA_NATIVE_ARCH}/latest" micromamba_bin/micromamba.tar.bz2)
    execute_process(COMMAND
      ${CMAKE_COMMAND} -E
      tar xvzf -C micromamba_bin/bin "micromamba_bin/micromamba.tar.bz2" -- "bin/micromamba")
  endif()
  set (MICROMAMBA_BIN ${_MICROMAMBA_BIN} PARENT_SCOPE)
endfunction()

function(micromamba_environment)
  message("Installing dependencies from channels:")

    cmake_parse_arguments(
        PARSED_ARGS # prefix of output variables
        "" # list of names of the boolean arguments (only defined ones will be true)
        "" # list of names of mono-valued arguments
        "CHANNELS;DEPENDENCIES" # list of names of multi-valued arguments (output variables are lists)
        ${ARGN} # arguments of the function to parse, here we take the all original ones
    )

  ensure_micromamba(MICROMAMBA_BIN)

  set (CHANNEL_ARG "")
  foreach(C ${PARSED_ARGS_CHANNELS})
    list(APPEND CHANNEL_ARG "-c")
    list(APPEND CHANNEL_ARG ${C})
  endforeach()

  execute_process(COMMAND echo
    ${MICROMAMBA_BIN} create -p ${CMAKE_BINARY_DIR}/environment ${CHANNEL_ARG} ${PARSED_ARGS_DEPENDENCIES} -v --yes --quiet)
  execute_process(COMMAND
    ${MICROMAMBA_BIN} create -p ${CMAKE_BINARY_DIR}/environment ${CHANNEL_ARG} ${PARSED_ARGS_DEPENDENCIES} --yes --quiet)

  SET(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/environment" CACHE INTERNAL "CMAKE_INSTALL_PREFIX")

  # set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/environment PARENT_SCOPE)
  set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR}/environment PARENT_SCOPE)
endfunction()
