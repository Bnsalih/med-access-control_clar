;; ------------------------------------------------------------
;; ------------------------------------------------------------
;; medivault_medical_records.clar
;; MediVault  Decentralized Medical Profile & Access Control
;; Rebranded Author: Muhammad Miftahu & Copilot
;; ------------------------------------------------------------
;; -------------------------------
;; Helpers & Overview
;; -------------------------------
;; This contract manages on-chain references (hashes) to patient
;; medical profiles and provides permissioned access to certified
;; healthcare providers. An audit trail records grants and revocations.

;; -------------------------------
;; Error codes (MediVault)
;; -------------------------------
(define-constant MV-ERR-NOT-FOUND u100)
(define-constant MV-ERR-UNAUTHORIZED u101)
(define-constant MV-ERR-ALREADY u102)
(define-constant MV-ERR-NOT-CERTIFIED u103)
(define-constant MV-ERR-NOT-OWNER u104)
(define-constant MV-ERR-NO-PROFILE u105)

;; -------------------------------
;; Data storage (rebranded names)
;; -------------------------------
(define-data-var steward (optional principal) none)

(define-map patient-profiles
  principal
  (tuple
    (owner principal)
    (profile-hash (buff 64))
    (created-block uint)
    (updated-block (optional uint))))

(define-map certified-providers
  principal
  (tuple
    (certified bool)
    (certified-block uint)))

(define-map permissions
  (tuple (patient principal) (provider principal))
  (tuple
    (granted bool)
    (granted-block uint)))

(define-map audit-trail
  uint
  (tuple
    (patient principal)
    (provider principal)
    (action (string-ascii 16))
    (block uint)))

(define-data-var audit-counter uint u0)

;; -------------------------------
;; Access control helpers
;; -------------------------------
(define-private (only-steward)
  (if (is-none (var-get steward))
      (err MV-ERR-UNAUTHORIZED)
      (if (is-eq tx-sender (unwrap-panic (var-get steward)))
          (ok true)
          (err MV-ERR-UNAUTHORIZED))))

(define-read-only (is-steward (who principal))
  (and (is-some (var-get steward))
       (is-eq who (unwrap-panic (var-get steward)))))

(define-private (provider-certified? (provider principal))
  (match (map-get? certified-providers provider) provider-record
    (get certified provider-record)
    false))

(define-private (record-audit (patient principal) (provider principal) (action (string-ascii 16)))
  (let ((idx (var-get audit-counter))
        (bh stacks-block-height))
    (begin 
      (map-set audit-trail idx
        (tuple (patient patient) (provider provider) (action action) (block bh)))
      (var-set audit-counter (+ idx u1))
      (ok u0))))

;; -------------------------------
;; Initialization
;; -------------------------------
(define-public (initialize-steward (new-steward principal))
  (begin
    (asserts! (is-eq tx-sender new-steward) (err MV-ERR-UNAUTHORIZED))
    (match (var-get steward) steward-value
      (begin
        (err MV-ERR-ALREADY))
      (begin
        (var-set steward (some new-steward))
        (ok true)))))

;; -------------------------------
;; Steward-only (admin) functions
;; -------------------------------
(define-public (certify-provider (provider principal))
  (begin
    (try! (only-steward))
    (asserts! (not (is-eq provider tx-sender)) (err MV-ERR-UNAUTHORIZED))
    (map-set certified-providers provider
      (tuple (certified true) (certified-block stacks-block-height)))
    (ok true)))

(define-public (decertify-provider (provider principal))
  (begin
    (try! (only-steward))
    (asserts! (not (is-eq provider tx-sender)) (err MV-ERR-UNAUTHORIZED))
    (map-set certified-providers provider
      (tuple (certified false) (certified-block stacks-block-height)))
    (ok true)))

(define-public (transfer-steward (new-steward principal))
  (begin
    (try! (only-steward))
    (asserts! (not (is-eq tx-sender new-steward)) (err MV-ERR-UNAUTHORIZED))
    (var-set steward (some new-steward))
    (ok true)))

;; -------------------------------
;; Patient-facing functions
;; -------------------------------
(define-public (create-medical-profile (profile-hash (buff 64)))
  (let ((patient tx-sender)
        (bh stacks-block-height))
    (match (map-get? patient-profiles patient) existing-profile
      (err MV-ERR-ALREADY)
      (begin
        (asserts! (is-eq (len profile-hash) u64) (err MV-ERR-UNAUTHORIZED))
        (map-set patient-profiles patient
          (tuple (owner patient)
                 (profile-hash profile-hash)
                 (created-block bh)
                 (updated-block none)))
        (ok true)))))

(define-public (update-medical-profile (profile-hash (buff 64)))
  (let ((patient tx-sender)
        (bh stacks-block-height))
    (match (map-get? patient-profiles patient) profile-record
      (if (is-eq (get owner profile-record) patient)
        (begin
          (map-set patient-profiles patient
            (merge profile-record
              (tuple (profile-hash profile-hash)
                     (updated-block (some bh)))))
          (ok true))
        (err MV-ERR-NOT-OWNER))
      (err MV-ERR-NO-PROFILE))))

(define-public (authorize-provider (provider principal))
  (let ((patient tx-sender)
        (bh stacks-block-height))
    (begin
      (asserts! (provider-certified? provider) (err MV-ERR-NOT-CERTIFIED))
      (map-set permissions (tuple (patient patient) (provider provider))
        (tuple (granted true) (granted-block bh)))
      (unwrap! (record-audit patient provider "authorize") (err MV-ERR-UNAUTHORIZED))
      (ok true))))

(define-public (revoke-authorization (provider principal))
  (let ((patient tx-sender)
        (bh stacks-block-height))
    (begin
      (asserts! (not (is-eq provider patient)) (err MV-ERR-UNAUTHORIZED))
      (asserts! (is-some (map-get? patient-profiles patient)) (err MV-ERR-NO-PROFILE))
      (map-set permissions (tuple (patient patient) (provider provider))
        (tuple (granted false) (granted-block bh)))
      (unwrap! (record-audit patient provider "revoke") (err MV-ERR-UNAUTHORIZED))
      (ok true))))

;; -------------------------------
;; Read-only & Query functions
;; -------------------------------
(define-read-only (has-permission (patient principal) (provider principal))
  (match (map-get? permissions (tuple (patient patient) (provider provider))) perm-record
    (get granted perm-record)
    false))

(define-read-only (is-certified? (provider principal))
  (provider-certified? provider))

(define-read-only (fetch-profile (patient principal))
  (let ((caller tx-sender))
    (match (map-get? patient-profiles patient) profile-record
      (let ((owner (get owner profile-record)))
        (if (is-eq caller owner)
          (ok (get profile-hash profile-record))
          (if (has-permission patient caller)
            (ok (get profile-hash profile-record))
            (err MV-ERR-UNAUTHORIZED))))
      (err MV-ERR-NO-PROFILE))))

(define-read-only (get-steward)
  (var-get steward))

(define-read-only (get-provider-status (provider principal))
  (map-get? certified-providers provider))

(define-read-only (get-audit-entry (idx uint))
  (map-get? audit-trail idx))

(define-read-only (get-profile-meta (patient principal))
  (map-get? patient-profiles patient))
