# **********************************************************
# Copyright (c) 2010-2012 Google, Inc.    All rights reserved.
# Copyright (c) 2009-2010 VMware, Inc.    All rights reserved.
# **********************************************************

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# * Neither the name of VMware, Inc. nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL VMWARE, INC. OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

cmake_minimum_required (VERSION 2.2)

set(CTEST_PROJECT_NAME "DynamoRIO")
set(cpack_project_name "DynamoRIO")
set(run_tests ON)
set(CTEST_SOURCE_DIRECTORY "${CTEST_SCRIPT_DIRECTORY}/..")
include("${CTEST_SCRIPT_DIRECTORY}/runsuite_common_pre.cmake")

# extra args (note that runsuite_common_pre.cmake has already walked
# the list and did not remove its args so be sure to avoid conflicts).
# none at this time.

if (TEST_LONG)
  set(DO_ALL_BUILDS ON)
  set(base_cache "${base_cache}
    BUILD_TESTS:BOOL=ON
    TEST_LONG:BOOL=ON")
else (TEST_LONG)
  set(DO_ALL_BUILDS OFF)
endif (TEST_LONG)

if (UNIX)
  # For cross-arch execve tests we need to run from an install dir
  set(installpath "${BINARY_BASE}/install")
  set(install_build_args "install")
  set(install_path_cache "CMAKE_INSTALL_PREFIX:PATH=${installpath}
    ")
  # Each individual 64-bit build should also set TEST_32BIT_PATH and one of
  # these.  Note that we put BOTH dirs on the path, so we can run the other test
  # (loader will bypass name match if wrong elf class).
  # FIXME i#145: should we use this dual path as a solution for cross-arch execve?
  # Only if we verify it works on all versions of ld.
  set(use_lib64_debug_cache
    "TEST_LIB_PATH:PATH=${installpath}/lib64/debug:${installpath}/lib32/debug
    ")
  set(use_lib64_release_cache
    "TEST_LIB_PATH:PATH=${installpath}/lib64/release:${installpath}/lib64/release
    ")
else (UNIX)
  set(install_build_args "")
endif (UNIX)

# for short suite, don't build tests for builds that don't run tests
# (since building takes forever on windows): so we only turn
# on BUILD_TESTS for TEST_LONG or debug-internal-{32,64}

# For cross-arch execve test we need to "make install"
testbuild_ex("debug-internal-32" OFF "
  DEBUG:BOOL=ON
  INTERNAL:BOOL=ON
  BUILD_TESTS:BOOL=ON
  ${install_path_cache}
  " OFF ON "${install_build_args}")
testbuild_ex("debug-internal-64" ON "
  DEBUG:BOOL=ON
  INTERNAL:BOOL=ON
  BUILD_TESTS:BOOL=ON
  ${install_path_cache}
  ${use_lib64_debug_cache}
  TEST_32BIT_PATH:PATH=${last_build_dir}/suite/tests/bin
  " OFF ON "${install_build_args}")
testbuild("debug-external-32" OFF "
  DEBUG:BOOL=ON
  INTERNAL:BOOL=OFF
  ")
testbuild("debug-external-64" ON "
  DEBUG:BOOL=ON
  INTERNAL:BOOL=OFF
  ")
testbuild_ex("release-external-32" OFF "
  DEBUG:BOOL=OFF
  INTERNAL:BOOL=OFF
  ${install_path_cache}
  " OFF OFF "${install_build_args}")
testbuild_ex("release-external-64" ON "
  DEBUG:BOOL=OFF
  INTERNAL:BOOL=OFF
  ${install_path_cache}
  ${use_lib64_release_cache}
  TEST_32BIT_PATH:PATH=${last_build_dir}/suite/tests/bin
  " OFF OFF "${install_build_args}")
# ensure extensions built as static libraries work
# no tests needed: we ensure instrcalls and drsyms_bench build
testbuild("debug-i32-static-ext" OFF "
  DEBUG:BOOL=ON
  INTERNAL:BOOL=ON
  DR_EXT_DRWRAP_STATIC:BOOL=ON
  DR_EXT_DRUTIL_STATIC:BOOL=ON
  DR_EXT_DRMGR_STATIC:BOOL=ON
  DR_EXT_DRSYMS_STATIC:BOOL=ON
  ${install_path_cache}
  ")
# we don't really use internal release builds for anything, but keep it working
if (DO_ALL_BUILDS)
  testbuild("release-internal-32" OFF "
    DEBUG:BOOL=OFF
    INTERNAL:BOOL=ON
    ")
  testbuild("release-internal-64" ON "
    DEBUG:BOOL=OFF
    INTERNAL:BOOL=ON
    ")
endif (DO_ALL_BUILDS)
# non-official-API builds
testbuild("vmsafe-debug-internal-32" OFF "
  VMAP:BOOL=OFF
  VMSAFE:BOOL=ON
  DEBUG:BOOL=ON
  INTERNAL:BOOL=ON
  ")
if (DO_ALL_BUILDS)
  testbuild("vmsafe-release-external-32" OFF "
    VMAP:BOOL=OFF
    VMSAFE:BOOL=ON
    DEBUG:BOOL=OFF
    INTERNAL:BOOL=OFF
    ")
endif (DO_ALL_BUILDS)
testbuild("vps-debug-internal-32" OFF "
  VMAP:BOOL=OFF
  VPS:BOOL=ON
  DEBUG:BOOL=ON
  INTERNAL:BOOL=ON
  ")
if (DO_ALL_BUILDS)
  testbuild("vps-release-external-32" OFF "
    VMAP:BOOL=OFF
    VPS:BOOL=ON
    DEBUG:BOOL=OFF
    INTERNAL:BOOL=OFF
    ")
  # Builds we'll keep from breaking but not worth running many tests
  testbuild("callprof-32" OFF "
    CALLPROF:BOOL=ON
    DEBUG:BOOL=OFF
    INTERNAL:BOOL=OFF
    ")
  testbuild("linkcount-32" OFF "
    LINKCOUNT:BOOL=ON
    DEBUG:BOOL=ON
    INTERNAL:BOOL=ON
    ")
  testbuild("nodefs-debug-internal-32" OFF "
    VMAP:BOOL=OFF
    DEBUG:BOOL=ON
    INTERNAL:BOOL=ON
    ")
endif (DO_ALL_BUILDS)

# FIXME: what about these builds?
## defines we don't want to break -- no runs though since we don't currently use these
#    "BUILD::NOSHORT::ADD_DEFINES=\"${D}DGC_DIAGNOSTICS\"",
#    "BUILD::NOSHORT::LIN::ADD_DEFINES=\"${D}CHECK_RETURNS_SSE2\"",

######################################################################
# SUMMARY

# sets ${outvar} in PARENT_SCOPE
function (error_string str outvar)
  string(REGEX MATCHALL "[^\n]*Unrecoverable[^\n]*" crash "${str}")
  string(REGEX MATCHALL "[^\n]*Internal DynamoRIO Error[^\n]*" assert "${str}")
  string(REGEX MATCHALL "[^\n]*CURIOSITY[^\n]*" curiosity "${str}")
  if (crash OR assert OR curiosity)
    string(REGEX REPLACE "[ \t]*<Value>" "" assert "${assert}")
    set(${outvar} "=> ${crash} ${assert} ${curiosity}" PARENT_SCOPE)
  else (crash OR assert OR curiosity)
    set(${outvar} "" PARENT_SCOPE)
  endif (crash OR assert OR curiosity)
endfunction (error_string)

set(build_package OFF)
include("${CTEST_SCRIPT_DIRECTORY}/runsuite_common_post.cmake")
