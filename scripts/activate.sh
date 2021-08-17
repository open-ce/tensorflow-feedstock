#!/bin/bash
# *****************************************************************
# (C) Copyright IBM Corp. 2019, 2021. All Rights Reserved.
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
SYS_PYTHON_MAJOR=$(python -c "import sys;print(sys.version_info.major)")
SYS_PYTHON_MINOR=$(python -c "import sys;print(sys.version_info.minor)")
COMPONENT="tensorflow"
TF_PKG_PATH=${CONDA_PREFIX}/lib/python${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}/site-packages/$COMPONENT
GREP=`type -P grep`

# Will not set PATH - conda activate adds <environment>/bin to PATH

# Will not set PYTHONPATH - Python path set by conda environment

if ! echo $LD_LIBRARY_PATH | $GREP -q $TF_PKG_PATH; then
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH${LD_LIBRARY_PATH:+:}$TF_PKG_PATH
fi
export LD_LIBRARY_PATH

TF_INCLUDE_DIR=$TF_PKG_PATH/include
export TF_INCLUDE_DIR

TF_LIBRARY_DIR=$TF_PKG_PATH
export TF_LIBRARY_DIR

OMP_NUM_THREADS=16
export OMP_NUM_THREADS

#https://github.com/tensorflow/tensorflow/issues/40065
CURL_CA_BUNDLE=${CONDA_PREFIX}/ssl/cacert.pem
export CURL_CA_BUNDLE
