#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2018, 2022. All Rights Reserved.
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

XNNPACK_STATUS=true
if [[ "${ARCH}" == 'ppc64le' || "${ARCH}" == 's390x' ]]; then
     XNNPACK_STATUS=false
fi

## 
## Use centralized optimization settings
##
NL=$'\n'
BUILD_COPT="build:opt --copt="
BUILD_HOST_COPT="build:opt --host_copt="
if [ -z "${cpu_opt_tune}"]; then
     CPU_ARCH_OPTION='';
     CPU_ARCH_HOST_OPTION='';
else
     if [[ "${ARCH}" == 'x86_64' || "${ARCH}" == 's390x' ]]; then
          CPU_ARCH_FRAG="-march=${cpu_opt_arch}"
     fi
     if [[ "${ARCH}" == 'ppc64le' ]]; then
          CPU_ARCH_FRAG="-mcpu=${cpu_opt_arch}"
     fi

     CPU_ARCH_OPTION=${BUILD_COPT}${CPU_ARCH_FRAG}
     CPU_ARCH_HOST_OPTION=${BUILD_HOST_COPT}${CPU_ARCH_FRAG}
fi

if [ -z "${cpu_opt_tune}"]; then
     CPU_TUNE_OPTION='';
     CPU_TUNE_HOST_OPTION='';
else
     CPU_TUNE_FRAG="-mtune=${cpu_opt_tune}";
     CPU_TUNE_OPTION=${BUILD_COPT}${CPU_TUNE_FRAG}
     CPU_TUNE_HOST_OPTION=${BUILD_HOST_COPT}${CPU_TUNE_FRAG}
fi

if [ -z "${vector_settings}"]; then
     VEC_OPTIONS='';
else
     vecs=$(echo ${vector_settings} | tr "," "\n")
     for setting in $vecs
     do
          VEC_OPTIONS+="build:opt --copt=-m${setting}${NL}"
     done
fi

SYSTEM_LIBS_PREFIX=$PREFIX
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
import %workspace%/tensorflow/python_configure.bazelrc
build:xla --define with_xla_support=true
build --config=xla
${CPU_ARCH_OPTION}
${CPU_ARCH_HOST_OPTION}
${CPU_TUNE_OPTION}
${CPU_TUNE_HOST_OPTION}
${VEC_OPTIONS}
build:opt --define with_default_optimizations=true

build --action_env TF_CONFIGURE_IOS="0"
build --action_env TF_SYSTEM_LIBS="org_sqlite"
build --define=PREFIX="$SYSTEM_LIBS_PREFIX"
build --define=LIBDIR="$SYSTEM_LIBS_PREFIX/lib"
build --define=INCLUDEDIR="$SYSTEM_LIBS_PREFIX/include"
build --define=tflite_with_xnnpack="$XNNPACK_STATUS"
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

if [[ "${ARCH}" == 's390x' ]]; then
echo "Building with more compiler flag for ${ARCH}"
# extra compiler flag added for further optimization
cat >> $BAZEL_RC_DIR/tensorflow.bazelrc << EOF
build:opt --copt=-O3
build:opt --copt=-funroll-loops
EOF
fi
