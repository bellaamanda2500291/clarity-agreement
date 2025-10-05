
;; title: agreement-manager
;; version: 1.0.0
;; summary: Manages agreement state and tracks party decisions
;; description: Contract for two-party agreements where only principals can change decisions or transfer party control

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_AGREEMENT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARTY (err u102))
(define-constant ERR_AGREEMENT_ALREADY_EXISTS (err u103))
(define-constant ERR_AGREEMENT_FINALIZED (err u104))

;; data vars
(define-data-var agreement-counter uint u0)

;; data maps
(define-map agreements
  { agreement-id: uint }
  {
    party-a: principal,
    party-b: principal,
    party-a-decision: (optional bool),
    party-b-decision: (optional bool),
    agreement-data: (string-ascii 256),
    is-finalized: bool,
    created-at: uint,
    updated-at: uint
  }
)

(define-map party-agreements
  { party: principal }
  { agreement-ids: (list 100 uint) }
)

;; public functions

;; Create a new agreement between two parties
(define-public (create-agreement (party-a principal) (party-b principal) (agreement-data (string-ascii 256)))
  (let
    (
      (new-id (+ (var-get agreement-counter) u1))
      (current-height stacks-block-height)
    )
    (asserts! (not (is-eq party-a party-b)) ERR_INVALID_PARTY)
    (map-set agreements
      { agreement-id: new-id }
      {
        party-a: party-a,
        party-b: party-b,
        party-a-decision: none,
        party-b-decision: none,
        agreement-data: agreement-data,
        is-finalized: false,
        created-at: current-height,
        updated-at: current-height
      }
    )
    (var-set agreement-counter new-id)
    (update-party-agreements party-a new-id)
    (update-party-agreements party-b new-id)
    (ok new-id)
  )
)

;; Record a party's decision
(define-public (record-decision (agreement-id uint) (decision bool))
  (let
    (
      (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR_AGREEMENT_NOT_FOUND))
      (caller tx-sender)
    )
    (asserts! (not (get is-finalized agreement)) ERR_AGREEMENT_FINALIZED)
    (asserts! (or (is-eq caller (get party-a agreement)) (is-eq caller (get party-b agreement))) ERR_UNAUTHORIZED)
    
    (if (is-eq caller (get party-a agreement))
      (map-set agreements
        { agreement-id: agreement-id }
        (merge agreement { party-a-decision: (some decision), updated-at: stacks-block-height })
      )
      (map-set agreements
        { agreement-id: agreement-id }
        (merge agreement { party-b-decision: (some decision), updated-at: stacks-block-height })
      )
    )
    (ok true)
  )
)

;; Finalize agreement if both parties have decided
(define-public (finalize-agreement (agreement-id uint))
  (let
    (
      (agreement (unwrap! (map-get? agreements { agreement-id: agreement-id }) ERR_AGREEMENT_NOT_FOUND))
    )
    (asserts! (not (get is-finalized agreement)) ERR_AGREEMENT_FINALIZED)
    (asserts! (is-some (get party-a-decision agreement)) (err u105))
    (asserts! (is-some (get party-b-decision agreement)) (err u106))
    
    (map-set agreements
      { agreement-id: agreement-id }
      (merge agreement { is-finalized: true, updated-at: stacks-block-height })
    )
    (ok true)
  )
)

;; read only functions

;; Get agreement details
(define-read-only (get-agreement (agreement-id uint))
  (map-get? agreements { agreement-id: agreement-id })
)

;; Get agreements for a party
(define-read-only (get-party-agreements (party principal))
  (default-to { agreement-ids: (list) } (map-get? party-agreements { party: party }))
)

;; Check if agreement is complete (both parties decided)
(define-read-only (is-agreement-complete (agreement-id uint))
  (match (map-get? agreements { agreement-id: agreement-id })
    agreement (and (is-some (get party-a-decision agreement)) (is-some (get party-b-decision agreement)))
    false
  )
)

;; Get current agreement counter
(define-read-only (get-agreement-counter)
  (var-get agreement-counter)
)

;; private functions

;; Helper function to update party agreements list
(define-private (update-party-agreements (party principal) (agreement-id uint))
  (let
    (
      (current-agreements (default-to { agreement-ids: (list) } (map-get? party-agreements { party: party })))
      (current-list (get agreement-ids current-agreements))
    )
    (map-set party-agreements
      { party: party }
      { agreement-ids: (unwrap-panic (as-max-len? (append current-list agreement-id) u100)) }
    )
  )
)
