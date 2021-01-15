# *****************************************************************
# (C) Copyright IBM Corp. 2020, 2021. All Rights Reserved.
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
mv ${SRC_DIR}/tensorflow_pkg/libtensorflow.so ${SP_DIR}/tensorflow/
mv ${SRC_DIR}/tensorflow_pkg/libtensorflow_cc.so ${SP_DIR}/tensorflow/

#Create version sym links
ln -s ${SP_DIR}/tensorflow/libtensorflow_framework.so.[0-9] "${SP_DIR}/tensorflow/libtensorflow_framework.so"
ln -s ${SP_DIR}/tensorflow/libtensorflow.so "${SP_DIR}/tensorflow/libtensorflow.so.${TF_MAJOR_VERSION}"
ln -s ${SP_DIR}/tensorflow/libtensorflow_cc.so "${SP_DIR}/tensorflow/libtensorflow_cc.so.${TF_MAJOR_VERSION}"

# Copy complete headers for libtensorflow C/C++ API
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/cc"
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/c"
mkdir -p "${SP_DIR}/tensorflow/include/tensorflow/cc/ops"

cd ./tensorflow/cc
cp --parents `find -name \*.h*` "${SP_DIR}/tensorflow/include/tensorflow/cc"

cd ../c
cp --parents `find -name \*.h*` "${SP_DIR}/tensorflow/include/tensorflow/c"

cd ../../
if [[ ! -d ${SRC_DIR}/tensorflow/include/tensorflow/cc/ops ]]
then
    echo "ERROR: You need to rebuild tensorflow-base package."
    echo "Please delete the previously generated tensorflow-base package from the output folder and rerun the build."
    exit 1
else
    cp -R "${SRC_DIR}/tensorflow/include/tensorflow/cc/ops/"*.h "${SP_DIR}/tensorflow/include/tensorflow/cc/ops"
fi

