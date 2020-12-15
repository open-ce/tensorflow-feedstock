#!/bin/bash
# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2019. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
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
