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

path_remove() {
  local LPATH=$1
  if [[ ! -z "$LPATH" && ! -z "$2" ]]; then
    if echo $LPATH | $GREP -q $2; then
      LPATH=${LPATH//":$2:"/":"} # Delete any instance in the middle
      LPATH=${LPATH/#"$2:"/} # Delete any instance at the beginning
      LPATH=${LPATH/%":$2"/} # Delete any instance at the end
      if [[ $LPATH == "$2" ]]; then
        LPATH=""
      fi
    fi
  fi
  echo "$LPATH"
}

SYS_PYTHON_MAJOR=$(python -c "import sys;print(sys.version_info.major)")
SYS_PYTHON_MINOR=$(python -c "import sys;print(sys.version_info.minor)")
COMPONENT="tensorflow"
TF_PKG_PATH=${CONDA_PREFIX}/lib/python${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}/site-packages/$COMPONENT
GREP=`type -P grep`

LD_LIBRARY_PATH=$(path_remove $LD_LIBRARY_PATH $TF_PKG_PATH)
if [ ! -z "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH
else
  unset LD_LIBRARY_PATH
fi

unset TF_INCLUDE_DIR

unset TF_LIBRARY_DIR

unset OMP_NUM_THREADS

unset CURL_CA_BUNDLE
