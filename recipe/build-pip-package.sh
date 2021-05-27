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
#!/bin/bash

set -vex

# Build Tensorflow from source
SCRIPT_DIR=$RECIPE_DIR/../buildscripts

# expand PREFIX in BUILD file - PREFIX is from conda build environment
sed -i -e "s:\${PREFIX}:${PREFIX}:" tensorflow/core/platform/default/build_config/BUILD

# Pick up additional variables defined from the conda build environment
$SCRIPT_DIR/set_python_path_for_bazelrc.sh $SRC_DIR/tensorflow
if [[ $build_type == "cuda" ]]
then
  # Pick up the CUDA and CUDNN environment
  $SCRIPT_DIR/set_tensorflow_nvidia_bazelrc.sh $SRC_DIR/tensorflow $PY_VER
fi
# Build the bazelrc
$SCRIPT_DIR/set_tensorflow_bazelrc.sh $SRC_DIR/tensorflow

#Clean up old bazel cache to avoid problems building TF
bazel clean --expunge
bazel shutdown

#BAZEL_CXXOPTS=-std=c++17

bazel --bazelrc=$SRC_DIR/tensorflow/tensorflow.bazelrc build \
    --local_cpu_resources=HOST_CPUS-10 \
    --local_ram_resources=HOST_RAM*0.50 \
    --config=opt \
    --config=numa \
    --curses=no \
    //tensorflow/tools/pip_package:build_pip_package

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

mkdir -p "${SRC_DIR}/tensorflow/include/tensorflow/cc/ops"
cp -R "bazel-bin/tensorflow/cc/ops/"*.h  "${SRC_DIR}/tensorflow/include/tensorflow/cc/ops"

# install using pip from the whl file
pip install --no-deps $SRC_DIR/tensorflow_pkg/*p${CONDA_PY}*.whl

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard

echo "PREFIX: $PREFIX"
echo "RECIPE_DIR: $RECIPE_DIR"

# Cache libtensorflow libs in SRC_DIR so they can be picked up by
# the libtensorflow output
mv ${SP_DIR}/tensorflow/libtensorflow.so ${SRC_DIR}/tensorflow_pkg/
mv ${SP_DIR}/tensorflow/libtensorflow_cc.so ${SRC_DIR}/tensorflow_pkg/
#mv ${SP_DIR}/tensorflow/libtensorflow_framework.so.2 ${SRC_DIR}/tensorflow_pkg/

# Install the activate / deactivate scripts that set environment variables
mkdir -p "${PREFIX}"/etc/conda/activate.d
mkdir -p "${PREFIX}"/etc/conda/deactivate.d
cp "${RECIPE_DIR}"/../scripts/activate.sh "${PREFIX}"/etc/conda/activate.d/activate-${PKG_NAME}.sh
cp "${RECIPE_DIR}"/../scripts/deactivate.sh "${PREFIX}"/etc/conda/deactivate.d/deactivate-${PKG_NAME}.sh

bazel clean --expunge
bazel shutdown
