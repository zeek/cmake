set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CheckCompilers)
include(ProhibitInSourceBuild)
include(AddUninstallTarget)
include(SetupRPATH)
include(SetDefaultCompileFlags)
include(MacDependencyPaths)
