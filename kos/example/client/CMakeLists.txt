# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

PROJECT (client)

# Set the linker and compiler flags.
project_header_default ("STANDARD_GNU_11:YES" "EXTRA_STRICT_WARNINGS:YES")

add_nk_edl (CLIENT_EDL
    "${RESOURCES}/edl/Client.edl"
    NK_MODULE  example
    LANG       "CXX"
)

bind_nk_targets (CLIENT_EDL ${RESOLVE_IDLS})

ADD_EXECUTABLE (Client src/main.cpp)
bind_nk_targets (Client CLIENT_EDL)

TARGET_COMPILE_FEATURES (Client PRIVATE cxx_std_17)
TARGET_COMPILE_OPTIONS (Client PRIVATE -fexceptions)
TARGET_INCLUDE_DIRECTORIES (Client PRIVATE ${CMAKE_CURRENT_LIST_DIR})
TARGET_LINK_LIBRARIES (Client PRIVATE ${CMAKE_THREAD_LIBS_INIT})

# We do not need default VFS entity here, which comes from ${vfs_CLIENT_LIB}.
SET_TARGET_PROPERTIES (Client PROPERTIES ${vfs_ENTITY}_REPLACEMENT "")
