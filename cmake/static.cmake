INCLUDE("${CMAKE_CURRENT_LIST_DIR}/toolchain.cmake")
STRING(REPLACE "-static" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
STRING(REPLACE "-shared" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
