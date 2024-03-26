;;! target = "riscv64"
;;! test = "compile"
;;! flags = " -C cranelift-enable-heap-access-spectre-mitigation -W memory64 -O static-memory-forced -O static-memory-guard-size=0 -O dynamic-memory-guard-size=0"

;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;; !!! GENERATED BY 'make-load-store-tests.sh' DO NOT EDIT !!!
;; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

(module
  (memory i64 1)

  (func (export "do_store") (param i64 i32)
    local.get 0
    local.get 1
    i32.store8 offset=0x1000)

  (func (export "do_load") (param i64) (result i32)
    local.get 0
    i32.load8_u offset=0x1000))

;; function u0:0:
;; block0:
;;   ld a1,[const(0)]
;;   sltu a1,a1,a2
;;   ld a4,80(a0)
;;   add a2,a4,a2
;;   lui a4,1
;;   add a2,a2,a4
;;   sub a5,zero,a1
;;   not a1,a5
;;   and a4,a2,a1
;;   sb a3,0(a4)
;;   j label1
;; block1:
;;   ret
;;
;; function u0:1:
;; block0:
;;   ld a1,[const(0)]
;;   sltu a1,a1,a2
;;   ld a3,80(a0)
;;   add a2,a3,a2
;;   lui a3,1
;;   add a2,a2,a3
;;   sub a5,zero,a1
;;   not a1,a5
;;   and a3,a2,a1
;;   lbu a0,0(a3)
;;   j label1
;; block1:
;;   ret