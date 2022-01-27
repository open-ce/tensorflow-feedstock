# *****************************************************************
# (C) Copyright IBM Corp. 2020, 20222 All Rights Reserved.
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
#!/bin/bash

set -vex

#
# Include libtensorflow shared libraries and headers
#

TF_MAJOR_VERSION=${PKG_VERSION:0:1}
echo "TF_MAJOR_VERSION: $TF_MAJOR_VERSION"

# Move libtensorflow libs in from SRC_DIR cache

TF_LIBDIR="${PREFIX}/lib"
mkdir -p ${TF_LIBDIR}
mv ${SRC_DIR}/tensorflow_pkg/libtensorflow.so ${TF_LIBDIR}/
mv ${SRC_DIR}/tensorflow_pkg/libtensorflow_cc.so ${TF_LIBDIR}/

#Create version sym links
ln -s ${TF_LIBDIR}/libtensorflow.so "${TF_LIBDIR}/libtensorflow.so.${TF_MAJOR_VERSION}"
ln -s ${TF_LIBDIR}/libtensorflow_cc.so "${TF_LIBDIR}/libtensorflow_cc.so.${TF_MAJOR_VERSION}"

# Copy complete headers for libtensorflow C/C++ API
TF_INCDIR="${PREFIX}/include/tensorflow"
mkdir -p "${TF_INCDIR}/cc"
mkdir -p "${TF_INCDIR}/c"
mkdir -p "${TF_INCDIR}/cc/ops"

cd ./tensorflow/cc
cp --parents `find -name \*.h*` "${TF_INCDIR}/cc"

cd ../c
cp --parents `find -name \*.h*` "${TF_INCDIR}/c"

cd ../../
if [[ ! -d ${SRC_DIR}/tensorflow/include/tensorflow/cc/ops ]]
then
    echo "ERROR: You need to rebuild tensorflow-base package."
    echo "Please delete the previously generated tensorflow-base package from the output folder and rerun the build."
    exit 1
else
    cp -R "${SRC_DIR}/tensorflow/include/tensorflow/cc/ops/"*.h "${TF_INCDIR}/cc/ops"
fi

