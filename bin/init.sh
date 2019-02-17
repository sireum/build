#!/bin/bash -e
#
# Copyright (c) 2019, Robby, Kansas State University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

getVersion() {
  grep "^org.sireum.version.$1=" ${SIREUM_HOME}/versions.properties | cut -d'=' -f2-
}

uncompress() {
  if hash unzip 2>/dev/null; then
    unzip -qo $1
  elif hash 7z 2>/dev/null; then
    7z x -y $1 > /dev/null
  else
    echo "Either unzip or 7z is required, but none found."
    exit 1
  fi
}

download() {
  if hash curl 2>/dev/null; then
    curl -c /dev/null -JLso $1 $2
  elif hash wget 2>/dev/null; then
    wget -qO $1 $2
  else
    echo "Either curl or wget is required, but none found."
    exit 1
  fi
}

: ${SIREUM_CACHE:="$( cd ~ &> /dev/null && pwd )/Downloads/sireum"}
mkdir -p ${SIREUM_CACHE}

#
# Sireum
#
SIREUM_HOME=$( cd "$( dirname "$0" )"/.. &> /dev/null && pwd )
cd ${SIREUM_HOME}
if [[ ! -f bin/sireum.jar ]]; then
  echo "Please wait while downloading Sireum ..."
  $(download bin/sireum.jar http://files.sireum.org/sireum)
  chmod +x bin/sireum.jar
  if [[ ! -f bin/sireum ]]; then
    $(download bin/sireum https://raw.githubusercontent.com/sireum/kekinian/master/bin/sireum)
    chmod +x bin/sireum
  fi
  if [[ ! -f versions.properties ]]; then
    $(download versions.properties https://raw.githubusercontent.com/sireum/kekinian/master/versions.properties)
  fi
  echo
fi


#
# scalac plugin
#
SCALAC_PLUGIN_VER=$(getVersion "scalac-plugin")
cd ${SIREUM_HOME}/bin
SCALAC_PLUGIN_DROP=scalac-plugin-${SCALAC_PLUGIN_VER}.jar
SCALAC_PLUGIN_DROP_URL=https://jitpack.io/org/sireum/scalac-plugin/${SCALAC_PLUGIN_VER}/scalac-plugin-${SCALAC_PLUGIN_VER}.jar
mkdir -p ${SIREUM_HOME}/lib
cd ${SIREUM_HOME}/lib
if [[ ! -f ${SCALAC_PLUGIN_DROP} ]]; then
  if [[ ! -f ${SIREUM_CACHE}/${SCALAC_PLUGIN_DROP} ]]; then
    echo "Please wait while downloading Slang scalac plugin ${SCALAC_PLUGIN_VER} ..."
    $(download ${SIREUM_CACHE}/${SCALAC_PLUGIN_DROP} ${SCALAC_PLUGIN_DROP_URL})
    echo
  fi
  rm -f scalac-plugin-*.jar
  cp ${SIREUM_CACHE}/${SCALAC_PLUGIN_DROP} .
fi


#
# Scala
#
if [[ -n ${SIREUM_PROVIDED_SCALA} ]]; then
  exit
fi
: ${SCALA_VERSION=$(getVersion "scala")}
cd ${SIREUM_HOME}/bin
SCALA_DROP_URL=http://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.zip
SCALA_DROP="${SCALA_DROP_URL##*/}"
grep -q ${SCALA_VERSION} scala/VER &> /dev/null && SCALA_UPDATE=false || SCALA_UPDATE=true
if [[ ! -d "scala" ]] || [[ "${SCALA_UPDATE}" = "true" ]]; then
  if [[ ! -f ${SIREUM_CACHE}/${SCALA_DROP} ]]; then
    echo "Please wait while downloading Scala ${SCALA_VERSION} ..."
    $(download ${SIREUM_CACHE}/${SCALA_DROP} ${SCALA_DROP_URL})
  fi
  echo "Extracting Scala ${SCALA_VERSION} ..."
  $(uncompress ${SIREUM_CACHE}/${SCALA_DROP})
  echo
  rm -fR scala
  mv scala-${SCALA_VERSION} scala
  if [[ -d "scala/bin" ]]; then
    echo "${SCALA_VERSION}" > scala/VER
    chmod +x scala/bin/*
  else
    >&2 echo "Could not install Scala ${SCALA_VERSION}."
    exit 1
  fi
fi


#
# Java
#
if [[ -n ${SIREUM_PROVIDED_JAVA} ]]; then
  exit
fi
if [[ -z "${PLATFORM}" ]]; then
  if [ -n "$COMSPEC" -a -x "$COMSPEC" ]; then
    PLATFORM=win
    JAVA_NAME="Zulu JDK"
    if [[ -z ${JAVA_VERSION} ]]; then
      JAVA_VERSION=$(getVersion "zulu")
    fi
    JAVA_DROP_URL=http://cdn.azul.com/zulu/bin/zulu${JAVA_VERSION}-win_x64.zip
  elif [[ "$(uname)" == "Darwin" ]]; then
    PLATFORM=mac
    JAVA_NAME="Zulu JDK"
    if [[ -z ${JAVA_VERSION} ]]; then
      JAVA_VERSION=$(getVersion "zulu")
    fi
    JAVA_DROP_URL=http://cdn.azul.com/zulu/bin/zulu${JAVA_VERSION}-macosx_x64.zip
    #JAVA_DROP_URL=https://github.com/oracle/graal/releases/download/vm-${JAVA_VERSION}/graalvm-ce-${JAVA_VERSION}-macos-amd64.tar.gz
  elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    PLATFORM=linux
    JAVA_NAME="GraalVM"
    if [[ -z ${JAVA_VERSION} ]]; then
      JAVA_VERSION=$(getVersion "graal")
    fi
    JAVA_DROP_URL=https://github.com/oracle/graal/releases/download/vm-${JAVA_VERSION}/graalvm-ce-${JAVA_VERSION}-linux-amd64.tar.gz
  else
    >&2 echo "Sireum does not support: $(uname). Please set env var SIREUM_PROVIDED_JAVA=true to use pre-installed Java."
    exit 1
  fi
fi
mkdir -p ${PLATFORM}
cd ${PLATFORM}
JAVA_DROP="${JAVA_DROP_URL##*/}"
JAVA_DIR="${JAVA_DROP%.*}"
if [[ ${JAVA_DIR} == *.tar ]]; then
  JAVA_DIR="${JAVA_DIR%.*}"
fi
grep -q ${JAVA_VERSION} java/VER &> /dev/null && JAVA_UPDATE=false || JAVA_UPDATE=true
if [[ ! -d "java" ]] || [[ "${JAVA_UPDATE}" = "true" ]]; then
  if [[ ! -f ${SIREUM_CACHE}/${JAVA_DROP} ]]; then
      echo "Please wait while downloading ${JAVA_NAME} ${JAVA_VERSION} ..."
      $(download  ${SIREUM_CACHE}/${JAVA_DROP} ${JAVA_DROP_URL})
  fi
  echo "Extracting ${JAVA_NAME} ${JAVA_VERSION} ..."
  if [[ ${JAVA_DROP} == *.tar.gz ]]; then
    tar xf ${SIREUM_CACHE}/${JAVA_DROP}
    rm -fR java
    if [[ "${PLATFORM}" == "mac" ]]; then
      mv graalvm-ce-${JAVA_VERSION}/Contents/Home java
      rm -fR graalvm-*
    else 
      mv graalvm-* java
    fi
  else
    $(uncompress ${SIREUM_CACHE}/${JAVA_DROP})
    rm -fR java
    mv ${JAVA_DIR} java
  fi
  echo
  if [[ -d "java/bin" ]]; then
    chmod +x java/bin/*
    chmod -fR u+w java
    echo "${JAVA_VERSION}" > java/VER
  else
    >&2 echo "Could not install ${JAVA_NAME} ${JAVA_VERSION}."
    exit 1
  fi
fi
