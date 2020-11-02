#!/bin/bash
# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2018, 2019. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
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
build:opt --copt=-DNO_CONSTEXPR_FOR_YOU=1
build:opt --host_copt=-DNO_CONSTEXPR_FOR_YOU=1
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
