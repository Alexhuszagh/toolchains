#!/bin/bash
# Simple shortcuts to call executables.

BIN=/usr/local/bin

# Can't guarantee all files are compiled binaries, might be
# scripts that use positional arguments. Make it a script
# that called the argument. Only export shortcut if the
# command exists, which may either be a command in the path,
# or an absolute path.
shortcut() {
    if command -v "$1" &> /dev/null; then
        echo '#!/bin/bash' >> "$2"
        echo "args=\"$ARGS\"" >> "$2"
        for value in "${FLAGS[@]}"; do
            local flag="${value%\/*}"
            local ident="${value#*\/}"
            echo "if [ \"\$$ident\" != \"\" ]; then" >> "$2"
            echo "    args=\"\$args $flag\$$ident\"" >> "$2"
            echo "fi" >> "$2"
        done
        echo "$1 \$args \"\$@\"" >> "$2"
        chmod +x "$2"
        for file in "${@:3}"; do
            ln -s "$2" "$file"
        done
    fi
}

# Create a utility to list the CPUs for the GCC compiler.
shortcut_gcc_cpu_list() {
    # Detect if we need to use run-cpu-list
    # Certain architectures have bugs where gcc
    # does not list the valid architectures. Some other
    # architectures have a single, hard-coded value.
    use_run=no
    use_hardcoded=no
    if [[ "$PREFIX" = alpha* ]]; then
        use_run=yes
    fi
    if [[ "$PREFIX" = riscv* ]]; then
        use_run=yes
    fi
    if [[ "$PREFIX" = sh4-* ]]; then
        use_run=yes
    fi
    if [[ "$PREFIX" = hppa* ]]; then
        use_hardcoded=yes
    fi

    echo '#!/bin/bash' >> "$BIN/cc-cpu-list"
    if [ "$use_run" = yes ]; then
        echo 'run-cpu-list' >> "$BIN/cc-cpu-list"
    elif [ "$use_hardcoded" = yes ]; then
        echo "echo \"$HARDCODED\"" >> "$BIN/cc-cpu-list"
    else
        echo "cpus=\$(echo \"int main() { return 0; }\" | CPU=unknown c++ -x c++ - 2>&1)" >> "$BIN/cc-cpu-list"
        echo "filtered=\$(echo \"\$cpus\" | grep note)" >> "$BIN/cc-cpu-list"
        echo "names=(\${filtered#* are: })" >> "$BIN/cc-cpu-list"
        echo "IFS=$'\n' sorted=(\$(sort <<<\"\${names[*]}\"))" >> "$BIN/cc-cpu-list"
        echo "if ((\${#sorted[@]})); then" >> "$BIN/cc-cpu-list"
        echo "    echo \"\${sorted[@]}\"" >> "$BIN/cc-cpu-list"
        echo "fi" >> "$BIN/cc-cpu-list"
    fi
    chmod +x "$BIN/cc-cpu-list"
}

# Create a utility to list the CPUs for the compiler.
shortcut_clang_cpu_list() {
    echo '#!/bin/bash' >> "$BIN/cc-cpu-list"
    echo "cpus=\$(c++ -print-targets)" >> "$BIN/cc-cpu-list"
    echo "readarray -t lines <<<\"\$cpus\"" >> "$BIN/cc-cpu-list"
    echo "names=()" >> "$BIN/cc-cpu-list"
    echo "for line in \"\${lines[@]:1}\"; do" >> "$BIN/cc-cpu-list"
    echo "    name=\$(echo \"\$line\" | cut -d ' ' -f 5)" >> "$BIN/cc-cpu-list"
    echo "    names+=(\"\$name\")" >> "$BIN/cc-cpu-list"
    echo "done" >> "$BIN/cc-cpu-list"
    echo "IFS=$'\n' sorted=(\$(sort <<<\"\${names[*]}\"))" >> "$BIN/cc-cpu-list"
    echo "if ((\${#sorted[@]})); then" >> "$BIN/cc-cpu-list"
    echo "    echo \"\${sorted[@]}\"" >> "$BIN/cc-cpu-list"
    echo "fi" >> "$BIN/cc-cpu-list"
    chmod +x "$BIN/cc-cpu-list"
}

# Generate the shortcut for any compiler.
shortcut_compiler() {
    local cc_base="$1"
    local cxx_base="$2"

    local prefix
    if [ "$DIR" = "" ]; then
        prefix="$PREFIX"
    else
        prefix="$DIR/bin/$PREFIX"
    fi

    local cc="$cc_base"
    local cxx="$cxx_base"
    if [ "$PREFIX" != "" ]; then
        cc="$prefix"-"$cc"
        cxx="$prefix"-"$cxx"
    fi

    # -mcpu is deprecated on x86.
    local cpu="mcpu"
    if [[ "$PREFIX" = i[3-7]86-* ]] || [[ "$PREFIX" = x86_64-* ]] || [ "$PREFIX" = "" ]; then
        cpu="march"
    fi
    # only -march works on MIPS architectures.
    if [[ "$PREFIX" = mips* ]]; then
        cpu="march"
    fi
    # HPPA only supports a single arch: 1.0.
    if [[ "$PREFIX" = hppa* ]]; then
        cpu="march"
    fi
    # only -march works on nios2 architectures.
    if [[ "$PREFIX" = nios2* ]]; then
        cpu="march"
    fi
    # only -march works on s390 architectures.
    if [[ "$PREFIX" = s390* ]]; then
        cpu="march"
    fi

    cc_alias=("$BIN/$cc_base" "$BIN/cc")
    cxx_alias=("$BIN/$cxx_base" "$BIN/c++" "$BIN/cpp")
    ARGS="$CFLAGS" FLAGS="-$cpu=/CPU" shortcut "$cc" "${cc_alias[@]}"
    ARGS="$CFLAGS" FLAGS="-$cpu=/CPU" shortcut "$cxx" "${cxx_alias[@]}"

    if [ "$VER" != "" ]; then
        ARGS="$CFLAGS" FLAGS="-$cpu=/CPU" shortcut "$cc"-"$VER" "${cc_alias[@]}"
        ARGS="$CFLAGS" FLAGS="-$cpu=/CPU" shortcut "$cxx"-"$VER" "${cxx_alias[@]}"
    fi
}

# Shortcut for a GCC-based compiler.
shortcut_gcc() {
    shortcut_compiler "gcc" "g++"
    PREFIX="$PREFIX" HARDCODED="$HARDCODED" shortcut_gcc_cpu_list
}

# Shortcut for a Clang-based compiler.
shortcut_clang() {
    shortcut_compiler "clang" "clang++"
    PREFIX="$PREFIX" HARDCODED="$HARDCODED" shortcut_clang_cpu_list
}

# Shortcut for all the utilities.
shortcut_util() {
    if [ "$PREFIX" = "" ]; then
        echo "Error: must set a prefix for the utilities."
        exit 1
    fi

    local prefix
    if [ "$DIR" = "" ]; then
        prefix="$PREFIX"
    else
        prefix="$DIR/bin/$PREFIX"
    fi

    # Make arrays of all our arguments.
    local ver_utils=("gcov" "gcov-dump" "gcov-tool" "lto-dump")
    local utils=(
        "${ver_utils[@]}"
        "addr2line"
        "ar"
        "as"
        "c++filt"
        "dwp"
        "elfedit"
        "embedspu"
        "gcov"
        "gcov-dump"
        "gcov-tool"
        "gprof"
        "ld"
        "ld.bfd"
        "ld.gold"
        "lto-dump"
        "nm"
        "objcopy"
        "objdump"
        "ranlib"
        "readelf"
        "size"
        "strings"
        "strip"
    )

    # Some of these might not exist, but it's fine.
    # Shortcut does nothing if the file doesn't exist.
    for util in "${utils[@]}"; do
        shortcut "$prefix"-"$util" "$BIN/$util"
    done
    if [ "$VER" != "" ]; then
        for util in "${ver_utils[@]}"; do
            shortcut "$prefix"-"$util"-"$VER" "$BIN/$util"
        done
    fi
}

# Create a utility to list the CPUs for Qemu emulation.
shortcut_run_cpu_list() {
    # Detect if we need to use a single, hard-coded value.
    use_cc=no
    use_hardcoded=no
    skip_first=yes
    # HPPA has a single, hard-coded valid arch (1.0).
    if [ "$ARCH" = hppa ]; then
        use_hardcoded=yes
    fi
    # SH4 does not have an entry line.
    if [ "$ARCH" = sh4 ]; then
        skip_first=no
    fi
    # Sparc has an incorrect output format.
    if [[ "$ARCH" = sparc* ]]; then
        use_cc=yes
    fi

    echo '#!/bin/bash' >> "$BIN/run-cpu-list"
    if [ "$use_cc" = yes ]; then
        echo 'cc-cpu-list' >> "$BIN/run-cpu-list"
    elif [ "$use_hardcoded" = yes ]; then
        echo "echo \"$HARDCODED\"" >> "$BIN/run-cpu-list"
    else
        echo "cpus=\"\$(run -cpu help)\"" >> "$BIN/run-cpu-list"
        echo "readarray -t lines <<<\"\$cpus\"" >> "$BIN/run-cpu-list"
        echo "names=()" >> "$BIN/run-cpu-list"
        if [ "$skip_first" = yes ]; then
            echo "for line in \"\${lines[@]:1}\"; do" >> "$BIN/run-cpu-list"
        else
            echo "for line in \"\${lines[@]}\"; do" >> "$BIN/run-cpu-list"
        fi
        echo "    if [ \"\$line\" != \"\" ]; then" >> "$BIN/run-cpu-list"
        echo "        name=\$(echo \"\$line\" | cut -d ' ' -f 2)" >> "$BIN/run-cpu-list"
        echo "        if [ \"\$name\" = \"\" ]; then" >> "$BIN/run-cpu-list"
        echo "          name=\$(echo \"\$line\" | cut -d ' ' -f 3)" >> "$BIN/run-cpu-list"
        echo "        fi" >> "$BIN/run-cpu-list"
        echo "        names+=(\"\$name\")" >> "$BIN/run-cpu-list"
        echo "    else" >> "$BIN/run-cpu-list"
        echo "        break" >> "$BIN/run-cpu-list"
        echo "    fi" >> "$BIN/run-cpu-list"
        echo "done" >> "$BIN/run-cpu-list"
        echo "" >> "$BIN/run-cpu-list"
        echo "IFS=$'\n' sorted=(\$(sort <<<\"\${names[*]}\"))" >> "$BIN/run-cpu-list"
        echo "if ((\${#sorted[@]})); then" >> "$BIN/run-cpu-list"
        echo "    echo \"\${sorted[@]}\"" >> "$BIN/run-cpu-list"
        echo "fi" >> "$BIN/run-cpu-list"
    fi
    chmod +x "$BIN/run-cpu-list"
}

# Create a runner for the Qemu binary.
shortcut_run() {
    if [ "$ARCH" = "" ]; then
        echo "Error: Architecture for Qemu must be specified."
        exit 1
    fi

    local args=
    if [ "$LIBPATH" != "" ]; then
        # Add support for executables linked to a shared libc/libc++.
        for libpath in "${LIBPATH[@]}"; do
            args="$args -L $libpath"
        done
    fi
    FLAGS="-cpu /CPU" ARGS="$args" shortcut "qemu-$ARCH-static" "$BIN/run"
    ARCH="$ARCH" HARDCODED="$HARDCODED" shortcut_run_cpu_list
}
