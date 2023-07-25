# cmake-micromamba

🚨🚨🚨 WIP WIP WIP 🚨🚨🚨

Create mamba environments directly in your CMake.

The scripts here are meant to check if micromamba is available on the system. If not, it will be downloaded.

Then, micromamba is used to install the dependencies.

## Usage:

```
micromamba_environment(
    [NAME name]
    [SPEC_FILE [files...]]
    [CHANNELS [channels...]]
    [DEPENDENCIES [dependencies...]]
    [VERBOSE verbosity (0,1,2,3)]
    [RUN_CMD var]
    [ENV_PATH var]
    [NO_PREFIX_PATH]
    [NO_DEPENDS]
)
```

* `NAME` - Name of the environment to create. Defaults to `environment`
* `SPEC_FILE` - A spec file specifying what should go in the environment - see mamba documentation for details. This file will also become a configuration dependency, so that changing it will cause cmake to reconfigure (and update the environment) - unless `NO_DEPENDS` is specified (see below)
* `CHANNELS` - A list of channels to search for packages
* `DEPENDENCIES` - A directly specified list of dependencies
* `VERBOSE` - Verbosity level (0,1,2,3)
* `RUN_CMD` - Variable that will be populated with a command line that can be used to run commands within the environment (essentially it will contain `micromamba run`, with the environment fully specified). It can then be used like `execute_command(COMMAND ${RUN_CMD_OUT} python foo.py)`
* `ENV_PATH` - Full path to the environment that was created. This will be within the build folder.
* `NO_PREFIX_PATH` - Do not add the new environment to any cmake search paths. I.e. `find_package` will not search within this environment for packages.
* `NO_DEPENDS` - Do not add a configuration dependency on the spec file. Users will need to explicitly re-run cmake to configure the project after a spec file change.
