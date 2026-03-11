# © 2026 AO Kaspersky Lab
# Licensed under the MIT License

cmake_minimum_required (VERSION 3.29)

project (c-ares-kos LANGUAGES C CXX)

include (FetchContent)

option (CARES_INSTALL "Generate installation target" ON)

# Configure the source location and patch application for the c-ares library.
# The official c-ares library repository.
set (GIT_REPOSITORY https://github.com/c-ares/c-ares.git)
# Specific version to fetch.
set (GIT_TAG        cares-1_19_1)
# Apply KasperskyOS adaptation patch after downloading.
set (GIT_PATCH      ${CMAKE_CURRENT_LIST_DIR}/KasperskyOS-CE-adaptation.patch)
set (PATCH_COMMAND  git apply ${GIT_PATCH})

# Prevent redundant patch application on subsequent builds.
if (CARES_CPP_POPULATED)
    # Library has already been fetched — skip patching to avoid conflicts.
    set (PATCH_COMMAND)
else ()
    message (STATUS "Downloading c-ares ${GIT_TAG}")
endif ()

# Declare the external dependency with patch configuration.
FetchContent_Declare (c-ares
                      GIT_REPOSITORY ${GIT_REPOSITORY}
                      GIT_TAG        ${GIT_TAG}
                      GIT_SHALLOW    YES
                      PATCH_COMMAND  ${PATCH_COMMAND})

# Execute the download and integration of the c-ares library into the build system.
FetchContent_MakeAvailable (c-ares)

# Cache the population state to optimize subsequent builds.
set (CARES_CPP_POPULATED ${c-ares_POPULATED} CACHE INTERNAL "")
