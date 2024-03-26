#!/usr/bin/env bash

# This script generates the `load_store_*.clif` test files.
#
# Usage:
#
#     $ ./make-load-store-tests.sh

set -e
cd $(dirname "$0")

function main {
    for spectre in "yes" "no"; do
        for guard in "0" "0xffffffff"; do
            for index_type in "i32" "i64"; do
                for kind in "static" "dynamic"; do
                    for access_type in "i32" "i8"; do
                        for offset in "0" "0x1000" "0xffff0000"; do
                            generate_one_test $kind $index_type $guard $spectre $access_type $offset x86_64 clif
                            for target in "x86_64" "aarch64" "s390x" "riscv64"; do
                                generate_one_test $kind $index_type $guard $spectre $access_type $offset $target compile
                            done
                        done
                    done
                done
            done
        done
    done
    echo "Done!"
}

function generate_one_test() {
    local kind=$1
    local index_type=$2
    local guard=$3
    local spectre=$4
    local access_type=$5
    local offset=$6
    local target=$7
    local test_kind=$8

    local filename="load_store_${kind}_kind_${index_type}_index_${guard}_guard_${spectre}_spectre_${access_type}_access_${offset}_offset.wat"
    if [[ $test_kind == "compile" ]]; then
        local target_dir=${target}
        if [[ $target == "x86_64" ]]; then
            target_dir="x64"
        fi
        mkdir -p "${target_dir}"
        filename="${target_dir}/${filename}"
    fi
    echo "Generating $filename..."

    local flags=""
    if [[ $spectre == "yes" ]]; then
        flags="$flags -C cranelift-enable-heap-access-spectre-mitigation"
    else
        flags="$flags -C cranelift-enable-heap-access-spectre-mitigation=false"
    fi

    if [[ $index_type == "i64" ]]; then
        flags="$flags -W memory64"
    fi

    local store_op=
    local load_op=
    case $access_type in
        "i32")
            store_op="i32.store"
            load_op="i32.load"
            ;;
        "i8")
            store_op="i32.store8"
            load_op="i32.load8_u"
            ;;
    esac

    local bound_global=""
    local style=""
    case $kind in
        "dynamic")
            flags="$flags -O static-memory-maximum-size=0"
            ;;
        "static")
            flags="$flags -O static-memory-forced"
        ;;
    esac
    flags="$flags -O static-memory-guard-size=$(($guard))"
    flags="$flags -O dynamic-memory-guard-size=$(($guard))"

    cat <<EOF > "$filename"
;;! target = "${target}"
;;! test = "${test_kind}"
;;! flags = "${flags}"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory ${index_type} 1)

  (func (export "do_store") (param ${index_type} i32)
    local.get 0
    local.get 1
    ${store_op} offset=${offset})

  (func (export "do_load") (param ${index_type}) (result i32)
    local.get 0
    ${load_op} offset=${offset}))

;; TODO: run with the 'CRANELIFT_TEST_BLESS=1' env var set to update this test's
;; expected output.
EOF
}

main