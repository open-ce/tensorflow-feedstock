# *****************************************************************
# (C) Copyright IBM Corp. 2018, 2023. All Rights Reserved.
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

source open-ce-common-utils.sh

export TF_PYTHON_VERSION=$PY_VER
  
if [[ $ppc_arch == "p10" ]]
then 
    if [[ -z "${GCC_HOME}" ]];
    then
	echo "Please set GCC_HOME to the install path of gcc-toolset-12"
        exit 1
    else
        export PATH=$GCC_HOME/bin:$PATH
        export CC=$GCC_HOME/bin/gcc
        export CXX=$GCC_HOME/bin/g++
        export BAZEL_LINKLIBS=-l%:libstdc++.a
    fi
fi

ARCH=`uname -p`
if [[ "${ARCH}" == 'ppc64le' ]]; then
    # remove -fno-plt as it causes failure with numpy installation
    # https://github.com/numpy/numpy/issues/25436
    export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
    export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"
    # fix for 'pip install h5py' to find libhdf5.so and hdf5.h
    export HDF5_INCLUDEDIR=$PREFIX/include
    export HDF5_LIBDIR=$PREFIX/lib
fi

 ARCH=`uname -p`
 if [[ "${ARCH}" == 's390x' ]]; then
     # fix for h5py installation to find libhdf5.so
    export HDF5_INCLUDEDIR=$PREFIX/include
    export HDF5_LIBDIR=$PREFIX/lib
 fi

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

ARCH=`uname -p`
if [[ "${ARCH}" == 's390x' ]];
then
cd $SRC_DIR
export ICU_MAJOR_VERSION="69"
export ICU_RELEASE="release-69-1"
git clone  --depth 1 --single-branch --branch release-69-1 https://github.com/unicode-org/icu.git
cd icu/icu4c/source/
git branch
# create ./filters.json
cat << 'EOF' > filters.json
{
  "localeFilter": {
    "filterType": "language",
    "includelist": [
      "en"
    ]
  }
}
EOF
ICU_DATA_FILTER_FILE=filters.json ./runConfigureICU Linux
pwd
make clean && make
# Workaround makefile issue where not all of the resource files may have been processed
find data/out/build/ -name '*pool.res' -print0 | xargs -0 touch
make
cd data/out/tmp
LD_LIBRARY_PATH=../../../lib ../../../bin/genccode "icudt${ICU_MAJOR_VERSION}b.dat"
echo "U_CAPI const void * U_EXPORT2 uprv_getICUData_conversion() { return icudt69b_dat.bytes; }" >> "icudt69b_dat.c"
cp icudt69b_dat.c icu_conversion_data_big_endian.c
gzip icu_conversion_data_big_endian.c
split -a 3 -b 100000 icu_conversion_data_big_endian.c.gz icu_conversion_data_big_endian.c.gz.
cp ${SRC_DIR}/icu/icu4c/source/data/out/tmp/icu_conversion_data_big_endian.c.gz.* ${SRC_DIR}/third_party/icu/data/
fi


#export BAZEL_LINKLIBS=-l%:libstdc++.a

# On x86, use of new compilers (gcc8) gives "ModuleNotFoundError: No module named '_sysconfigdata_x86_64_conda_linux_gnu'"# This is due to the target triple difference with which python and conda-build are built. Below is the work around to this problem.
# Conda-forge's python-feedstock has a patch https://github.com/conda-forge/python-feedstock/blob/master/recipe/patches/0010-Add-support-for-_CONDA_PYTHON_SYSCONFIGDATA_NAME-if-.patch which may address this problem.

ARCH=`uname -m`
if [[ $ARCH == "x86_64" ]]; then
  cp $PREFIX/lib/python${PY_VER}/_sysconfigdata__linux_x86_64-linux-gnu.py $PREFIX/lib/python${PY_VER}/_sysconfigdata_x86_64_conda_linux_gnu.py
  cp $PREFIX/lib/python${PY_VER}/_sysconfigdata__linux_x86_64-linux-gnu.py $PREFIX/lib/python${PY_VER}/_sysconfigdata_x86_64_conda_cos7_linux_gnu.py
fi

BAZEL_JOBS="HOST_CPUS*0.5"
if [ -z ${LIMIT_BUILD_RESOURCES+x} ];
then
    echo "ERROR: LIMIT_BUILD_RESOURCES is unset. Please set it to 1 if the build system is low in resources, else set it to 0"
    exit 1
else
    echo "LIMIT_BUILD_RESOURCES is set to $LIMIT_BUILD_RESOURCES"
    if [[ ${LIMIT_BUILD_RESOURCES} == true || ${LIMIT_BUILD_RESOURCES} == 1 ]];
    then
        BAZEL_JOBS="32"
    fi
fi

bazel --bazelrc=$SRC_DIR/tensorflow/tensorflow.bazelrc build \
    --local_cpu_resources=HOST_CPUS*0.50 \
    --local_ram_resources=HOST_RAM*0.50 \
    --jobs=$BAZEL_JOBS   \
    --config=opt \
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
TF_MAJOR_VERSION=${PKG_VERSION:0:1}
echo "TF_MAJOR_VERSION: $TF_MAJOR_VERSION"

mv ${SP_DIR}/tensorflow/libtensorflow.so ${SRC_DIR}/tensorflow_pkg/
mv ${SP_DIR}/tensorflow/libtensorflow_cc.so ${SRC_DIR}/tensorflow_pkg/
ln -s ${SP_DIR}/tensorflow/libtensorflow_framework.so.${TF_MAJOR_VERSION} ${SP_DIR}/tensorflow/libtensorflow_framework.so

# Install the activate / deactivate scripts that set environment variables
mkdir -p "${PREFIX}"/etc/conda/activate.d
mkdir -p "${PREFIX}"/etc/conda/deactivate.d
cp "${RECIPE_DIR}"/../scripts/activate.sh "${PREFIX}"/etc/conda/activate.d/activate-${PKG_NAME}.sh
cp "${RECIPE_DIR}"/../scripts/deactivate.sh "${PREFIX}"/etc/conda/deactivate.d/deactivate-${PKG_NAME}.sh

PID=$(bazel info server_pid)
echo "PID: $PID"
cleanup_bazel $PID
