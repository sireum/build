abspath0() {
    if [ -d "$1" ]; then
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        case "$1" in
          /*)  echo "$1";;
          */*) echo "$(cd "${1%/*}"; pwd)/${1##*/}";;
          *)   echo "$(pwd)/$1"
        esac
    fi
}
abspath() {
    P=$( abspath0 "$1" )
    case $(uname -s) in
      CYGWIN*) echo "$(cygpath -C OEM -w -a $P)";;
      *) echo $P
    esac
}
