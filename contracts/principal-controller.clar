
;; title: principal-controller
;; version: 1.0.0
;; summary: Enforces principal-only access for decision changes and transfers
;; description: Contract that manages party control and ensures only principals can make changes

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_PRINCIPAL_NOT_FOUND (err u201))
(define-constant ERR_INVALID_PRINCIPAL (err u202))
(define-constant ERR_TRANSFER_TO_SELF (err u203))
(define-constant ERR_PRINCIPAL_ALREADY_EXISTS (err u204))

;; data vars
(define-data-var principal-counter uint u0)

;; data maps
(define-map principals
  { principal-id: uint }
  {
    principal-address: principal,
    is-active: bool,
    created-at: uint,
    updated-at: uint,
    metadata: (string-ascii 256)
  }
)

(define-map principal-lookup
  { principal-address: principal }
  { principal-id: uint }
)

(define-map delegated-permissions
  { delegator: principal, delegatee: principal }
  {
    can-make-decisions: bool,
    can-transfer-control: bool,
    expires-at: (optional uint),
    created-at: uint
  }
)

;; public functions

;; Register a new principal
(define-public (register-principal (metadata (string-ascii 256)))
  (let
    (
      (caller tx-sender)
      (new-id (+ (var-get principal-counter) u1))
      (current-height block-height)
    )
    (asserts! (is-none (map-get? principal-lookup { principal-address: caller })) ERR_PRINCIPAL_ALREADY_EXISTS)
    (map-set principals
      { principal-id: new-id }
      {
        principal-address: caller,
        is-active: true,
        created-at: current-height,
        updated-at: current-height,
        metadata: metadata
      }
    )
    (map-set principal-lookup
      { principal-address: caller }
      { principal-id: new-id }
    )
    (var-set principal-counter new-id)
    (ok new-id)
  )
)

;; Transfer principal control to another address
(define-public (transfer-principal-control (new-principal principal) (principal-id uint))
  (let
    (
      (caller tx-sender)
      (principal-data (unwrap! (map-get? principals { principal-id: principal-id }) ERR_PRINCIPAL_NOT_FOUND))
    )
    (asserts! (not (is-eq caller new-principal)) ERR_TRANSFER_TO_SELF)
    (asserts! (is-eq caller (get principal-address principal-data)) ERR_UNAUTHORIZED)
    (asserts! (get is-active principal-data) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? principal-lookup { principal-address: new-principal })) ERR_PRINCIPAL_ALREADY_EXISTS)
    
    ;; Remove old lookup
    (map-delete principal-lookup { principal-address: caller })
    ;; Update principal data
    (map-set principals
      { principal-id: principal-id }
      (merge principal-data { principal-address: new-principal, updated-at: block-height })
    )
    ;; Set new lookup
    (map-set principal-lookup
      { principal-address: new-principal }
      { principal-id: principal-id }
    )
    (ok true)
  )
)

;; Delegate permissions to another principal
(define-public (delegate-permissions (delegatee principal) (can-make-decisions bool) (can-transfer-control bool) (expires-at (optional uint)))
  (let
    (
      (caller tx-sender)
      (current-height block-height)
    )
    (asserts! (not (is-eq caller delegatee)) ERR_TRANSFER_TO_SELF)
    (asserts! (is-registered-principal caller) ERR_UNAUTHORIZED)
    (map-set delegated-permissions
      { delegator: caller, delegatee: delegatee }
      {
        can-make-decisions: can-make-decisions,
        can-transfer-control: can-transfer-control,
        expires-at: expires-at,
        created-at: current-height
      }
    )
    (ok true)
  )
)

;; Revoke delegated permissions
(define-public (revoke-delegation (delegatee principal))
  (let
    (
      (caller tx-sender)
    )
    (asserts! (is-registered-principal caller) ERR_UNAUTHORIZED)
    (map-delete delegated-permissions { delegator: caller, delegatee: delegatee })
    (ok true)
  )
)

;; Deactivate a principal (only the principal themselves can do this)
(define-public (deactivate-principal (principal-id uint))
  (let
    (
      (caller tx-sender)
      (principal-data (unwrap! (map-get? principals { principal-id: principal-id }) ERR_PRINCIPAL_NOT_FOUND))
    )
    (asserts! (is-eq caller (get principal-address principal-data)) ERR_UNAUTHORIZED)
    (map-set principals
      { principal-id: principal-id }
      (merge principal-data { is-active: false, updated-at: block-height })
    )
    (ok true)
  )
)

;; read only functions

;; Check if an address is a registered principal
(define-read-only (is-registered-principal (principal-address principal))
  (is-some (map-get? principal-lookup { principal-address: principal-address }))
)

;; Check if a principal can make decisions (either directly or through delegation)
(define-read-only (can-make-decisions (principal-address principal) (target-principal principal))
  (or
    (is-eq principal-address target-principal)
    (match (map-get? delegated-permissions { delegator: target-principal, delegatee: principal-address })
      delegation (and
                  (get can-make-decisions delegation)
                  (match (get expires-at delegation)
                    expiry (< block-height expiry)
                    true
                  )
                )
      false
    )
  )
)

;; Check if a principal can transfer control (either directly or through delegation)
(define-read-only (can-transfer-control (principal-address principal) (target-principal principal))
  (or
    (is-eq principal-address target-principal)
    (match (map-get? delegated-permissions { delegator: target-principal, delegatee: principal-address })
      delegation (and
                  (get can-transfer-control delegation)
                  (match (get expires-at delegation)
                    expiry (< block-height expiry)
                    true
                  )
                )
      false
    )
  )
)

;; Get principal data
(define-read-only (get-principal (principal-id uint))
  (map-get? principals { principal-id: principal-id })
)

;; Get principal ID by address
(define-read-only (get-principal-id (principal-address principal))
  (map-get? principal-lookup { principal-address: principal-address })
)

;; Get delegation info
(define-read-only (get-delegation (delegator principal) (delegatee principal))
  (map-get? delegated-permissions { delegator: delegator, delegatee: delegatee })
)

;; Get current principal counter
(define-read-only (get-principal-counter)
  (var-get principal-counter)
)

;; private functions
;;
