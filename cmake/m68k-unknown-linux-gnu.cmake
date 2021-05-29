SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR m68k)

# COMPILERS
# ---------
SET(prefix m68k-linux-gnu)
SET(CMAKE_C_COMPILER "${prefix}-gcc-10")
SET(CMAKE_CXX_COMPILER "${prefix}-g++-10")
SET(CMAKE_COMPILER_PREFIX "${prefix}-")

# PATHS
# -----
SET(CMAKE_FIND_ROOT_PATH "/usr/${prefix}/")
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# OTHER
# -----
SET(ARCH 32)
