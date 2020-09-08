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
# Set python path variables from conda build environment
BAZEL_RC_DIR=$1
cat > $BAZEL_RC_DIR/python_configure.bazelrc << EOF
build --action_env PYTHON_BIN_PATH="$PYTHON"
build --action_env PYTHON_LIB_PATH="$SP_DIR"
build --python_path="$PYTHON"
EOF
