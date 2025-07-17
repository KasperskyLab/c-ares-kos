# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

PROJECT (resolver)

FIND_PACKAGE (c-ares REQUIRED)

# Set the linker and compiler flags.
project_header_default ("STANDARD_GNU_17:YES" "EXTRA_STRICT_WARNINGS:YES")

add_nk_edl (NAME_RESOLVER_EDL
    "${RESOURCES}/edl/NameResolver.edl"
    NK_MODULE example
    LANG      "CXX"
)

bind_nk_targets (NAME_RESOLVER_EDL ${RESOLVE_IDLS})

ADD_EXECUTABLE (NameResolver src/main.cpp src/resolver.cpp)
bind_nk_targets (NameResolver NAME_RESOLVER_EDL)
TARGET_COMPILE_FEATURES (NameResolver PRIVATE cxx_std_17)
TARGET_COMPILE_OPTIONS (NameResolver PRIVATE -fexceptions)
TARGET_INCLUDE_DIRECTORIES (NameResolver PRIVATE ${CMAKE_CURRENT_LIST_DIR})
TARGET_LINK_LIBRARIES (NameResolver
    PRIVATE
       ${vfs_CLIENT_LIB}
       ${CMAKE_THREAD_LIBS_INIT}
       $<IF:$<BOOL:${PLATFORM_SUPPORTS_DYNAMIC_LINKING}>,c-ares::cares_shared,c-ares::cares_static>
)

# We do not need default VFS entity here, which comes from ${vfs_CLIENT_LIB}.
SET_TARGET_PROPERTIES (NameResolver PROPERTIES ${vfs_ENTITY}_REPLACEMENT "")
