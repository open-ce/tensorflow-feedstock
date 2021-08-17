#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2018, 2021. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************

set -ex
BAZEL_RC_DIR=$1

#Determine architecture for specific options
ARCH=`uname -p`

## ARCHITECTURE SPECIFIC OPTIMIZATIONS
## These are settings and arguments to pass to GCC for
## optimization settings specific to the target CPU architecture
##
OPTION_1=''
OPTION_2=''
if [[ "${ARCH}" == 'x86_64' ]]; then
    OPTION_1='-march=broadwell'
    OPTION_2='-mtune=broadwell'
    OPTION_3='-mavx'
    OPTION_4='-mavx2'
    OPTION_5='-mfma'
    OPTION_6='-msse4.1'
    OPTION_7='-msse4.2'
    ##TODO: investigate '-mfpmath=both'
fi
if [[ "${ARCH}" == 'ppc64le' ]]; then
    OPTION_1='-mcpu=power8'
    OPTION_2='-mtune=power8'
    OPTION_3=''
    OPTION_4=''
    OPTION_5=''
    OPTION_6=''
    OPTION_7=''
fi

SYSTEM_LIBS_PREFIX=$PREFIX
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
import %workspace%/tensorflow/python_configure.bazelrc
build:xla --define with_xla_support=true
build --config=xla
build:opt --copt="${OPTION_1}"
build:opt --copt="${OPTION_2}"
build:opt --copt="${OPTION_3}"
build:opt --copt="${OPTION_4}"
build:opt --copt="${OPTION_5}"
build:opt --copt="${OPTION_6}"
build:opt --copt="${OPTION_7}"
build:opt --host_copt="${OPTION_1}"
build:opt --host_copt="${OPTION_2}"
build:opt --define with_default_optimizations=true
build --action_env TF_CONFIGURE_IOS="0"
build --action_env TF_SYSTEM_LIBS="org_sqlite"
build --define=PREFIX="$SYSTEM_LIBS_PREFIX"
build --define=LIBDIR="$SYSTEM_LIBS_PREFIX/lib"
build --define=INCLUDEDIR="$SYSTEM_LIBS_PREFIX/include"
build --strip=always
build --color=yes
build --verbose_failures
build --spawn_strategy=standalone
EOF

echo "Building with mkl : $use_mkl"

if [[ $use_mkl == "true" && "${ARCH}" == 'x86_64' ]]; then
# If MKL_FEATURE is set to ON and ARCH is x86_64
echo "Enabled MKL"
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
build --config=mkl
EOF
fi
