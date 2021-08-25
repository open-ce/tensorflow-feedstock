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
## optimization settings specific to the target architecture
##
OPTION_1=''
OPTION_2="-mtune=${cpu_opt_tune}"
if [[ "${ARCH}" == 'x86_64' ]]; then
     OPTION_1="-march=${cpu_opt_arch}"
fi
if [[ "${ARCH}" == 'ppc64le' ]]; then
     OPTION_1="-mcpu=${cpu_opt_arch}"
fi

vecs=$(echo ${vector_settings} | tr "," "\n")
NL=$'\n'
for setting in $vecs
do
	VEC_OPTIONS+="build:opt --copt=-m${setting}${NL}"
done

echo ${OPTION_1}
echo ${OPTION_2}
echo ${VEC_OPTIONS}

SYSTEM_LIBS_PREFIX=$PREFIX
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
import %workspace%/tensorflow/python_configure.bazelrc
build:xla --define with_xla_support=true
build --config=xla
build:opt --copt="${OPTION_1}"
build:opt --copt="${OPTION_2}"
build:opt --host_copt="${OPTION_1}"
build:opt --host_copt="${OPTION_2}"
${VEC_OPTIONS}
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
