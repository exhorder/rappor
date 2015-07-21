#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

setup() {
  # need libprotobuf-dev for headers to compile against.
  sudo apt-get install protobuf-compiler libprotobuf-dev
}

init() {
  mkdir --verbose -p _tmp
}

rappor-sim() {
  make _tmp/rappor_sim
  _tmp/rappor_sim "$@"
}

protobuf-encoder-test() {
  make _tmp/protobuf_encoder_demo
  _tmp/protobuf_encoder_demo "$@"
}

rappor-sim-demo() {
  rappor-sim 8 2 128 0.25 0.75 0.5 <<EOF
client,cohort,value
1,1,v1
1,1,v2
2,2,v3
2,2,v4
EOF
}

protobuf-encoder-demo() {
  protobuf-encoder-test 8 2 128 0.25 0.75 0.5 <<EOF
client,cohort,value
1,1,v1
1,1,v2
2,2,v3
2,2,v4
EOF
}

empty-input() {
  echo -n '' | rappor-sim 58 2 128 .025 0.75 0.5
}

# This outputs an HMAC and MD5 value.  Compare with Python/shell below.

openssl-hash-impl-test() {
  make _tmp/openssl_hash_impl_test
  _tmp/openssl_hash_impl_test "$@"
}

test-hmac-sha256() {
  #echo -n foo | sha256sum
  python -c '
import hashlib
import hmac
import sys

secret = sys.argv[1]
body = sys.argv[2]
m = hmac.new(secret, body, digestmod=hashlib.sha256)
print m.hexdigest()
' "key" "value"
}

test-md5() {
  echo -n value | md5sum
}

# -M: all headers
# -MM: exclude system headers

# -MF: file to write the dependencies to

# -MD: like -M -MF
# -MMD: -MD, but only system headers

# -MP: workaround

deps() {
  gcc -I _tmp -MM protobuf_encoder_test.cc unix_kernel_rand_impl.cc
  #gcc -I _tmp -MMD -MP protobuf_encoder_test.cc unix_kernel_rand_impl.cc
}

obj() {
  # -c: compile only
  gcc -c -o _tmp/rappor_sim.o rappor_sim.cc 
  ls *.o
}

"$@"
