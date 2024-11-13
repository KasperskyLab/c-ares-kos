# © 2024 AO Kaspersky Lab
# Licensed under the MIT License

CMAKE_MINIMUM_REQUIRED (VERSION 3.25)
PROJECT (async_resolver_example)

# Initialize CMake library for the KasperskyOS SDK.
INCLUDE (platform)
initialize_platform ()

# Include the CMake library named nk
# for working with the NK compiler (nk-gen-c).
INCLUDE (platform/nk)

IF (PLATFORM_SUPPORTS_DYNAMIC_LINKING)
    # Add a package with the BlobContainer program implementations.
    FIND_PACKAGE (blob_container)
ENDIF ()

FIND_PACKAGE (Threads REQUIRED)

# Add a package for working with the virtual file system.
FIND_PACKAGE (vfs REQUIRED)
INCLUDE_DIRECTORIES (${vfs_INCLUDE})

# Add a package with the VFS program implementations.
FIND_PACKAGE (precompiled_vfs REQUIRED)
INCLUDE_DIRECTORIES (${precompiled_vfs_INCLUDE})

# Add a package with the Dhcpcd program implementation.
FIND_PACKAGE (rump REQUIRED COMPONENTS DHCPCD_ENTITY)
INCLUDE_DIRECTORIES (${rump_INCLUDE})

# Include the directory with the generated config header files.
INCLUDE_DIRECTORIES (${CMAKE_CURRENT_BINARY_DIR})

# Include the directory with header files.
SET (RESOURCES ${CMAKE_CURRENT_LIST_DIR}/resources)
INCLUDE_DIRECTORIES (${RESOURCES}/INCLUDE ${CMAKE_CURRENT_LIST_DIR})

# Include the directory with header files.
SET (RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/resources)

add_nk_idl (RESOLVER_IDL
    "${RESOURCES}/idl/Resolver.idl"
    NK_MODULE example
    LANG      "CXX"
)

add_nk_idl (RESOLVE_CALLBACK_IDL
    "${RESOURCES}/idl/ResolveCallback.idl"
    NK_MODULE example
    LANG      "CXX"
)

SET (RESOLVE_IDLS RESOLVER_IDL RESOLVE_CALLBACK_IDL)

ADD_SUBDIRECTORY (resolver)
ADD_SUBDIRECTORY (client)
ADD_SUBDIRECTORY (einit)
