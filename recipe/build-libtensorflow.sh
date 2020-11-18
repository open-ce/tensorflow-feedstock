# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2020. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************
#!/bin/bash

set -vex

#
# Include libtensorflow shared libraries and headers
#
# Copy complete headers for libtensorflow C/C++ API
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/cc"
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/c"
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/cc/ops"

cd ./tensorflow/cc
cp --parents `find -name \*.h*` "${SP_DIR}/tensorflow/include/tensorflow/cc"

cd ../c
cp --parents `find -name \*.h*` "${SP_DIR}/tensorflow/include/tensorflow/c"

cd ../../
cp -R "${SRC_DIR}/tensorflow/include/tensorflow/cc/ops/"*.h "${SP_DIR}/tensorflow/include/tensorflow/cc/ops"

TF_MAJOR_VERSION=${PKG_VERSION:0:1}
echo "TF_MAJOR_VERSION: $TF_MAJOR_VERSION"

#Create sym link for libtensorflow_framework
ln -s ${SP_DIR}/tensorflow/libtensorflow_framework.so.[0-9] "${SP_DIR}/tensorflow/libtensorflow_framework.so"
ln -s ${SP_DIR}/tensorflow/libtensorflow.so "${SP_DIR}/tensorflow/libtensorflow.so.${TF_MAJOR_VERSION}"
ln -s ${SP_DIR}/tensorflow/libtensorflow_cc.so "${SP_DIR}/tensorflow/libtensorflow_cc.so.${TF_MAJOR_VERSION}"
