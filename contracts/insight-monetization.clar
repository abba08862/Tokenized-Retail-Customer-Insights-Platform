;; Insight Monetization Contract
;; This contract manages data sharing compensation

(define-data-var admin principal tx-sender)
(define-data-var fee-percentage uint u5) ;; 5% platform fee

;; Define traits for external contracts
(define-trait retailer-verification-trait
  (
    (is-verified-retailer (principal) (response bool uint))
  )
)

(define-trait consumer-trait
  (
    (is-active-consumer (principal) (response bool uint))
  )
)

;; Map to store data sharing agreements
(define-map data-sharing-agreements uint
  {
    retailer: principal,
    consumer: principal,
    compensation: uint,
    active: bool,
    created-at: uint
  }
)

;; Counter for agreement IDs
(define-data-var agreement-counter uint u0)

;; Map to track consumer earnings
(define-map consumer-earnings principal uint)

;; Public function to create a data sharing agreement
(define-public (create-agreement
  (consumer principal)
  (compensation uint)
  (retailer-verification-contract <retailer-verification-trait>)
  (consumer-contract <consumer-trait>))
  (let ((agreement-id (var-get agreement-counter)))
    (begin
      ;; Check if retailer is verified
      (asserts! (unwrap-panic (contract-call? retailer-verification-contract is-verified-retailer tx-sender)) (err u401))

      ;; Check if consumer is active
      (asserts! (unwrap-panic (contract-call? consumer-contract is-active-consumer consumer)) (err u404))

      ;; Create the agreement
      (map-set data-sharing-agreements agreement-id
        {
          retailer: tx-sender,
          consumer: consumer,
          compensation: compensation,
          active: true,
          created-at: block-height
        }
      )

      ;; Increment the agreement counter
      (var-set agreement-counter (+ agreement-id u1))

      ;; Return the agreement ID
      (ok agreement-id)
    )
  )
)

;; Public function to pay a consumer for their data
(define-public (pay-for-insights (agreement-id uint))
  (let (
    (agreement (default-to
      { retailer: tx-sender, consumer: tx-sender, compensation: u0, active: false, created-at: u0 }
      (map-get? data-sharing-agreements agreement-id)))
    (platform-fee (/ (* (get compensation agreement) (var-get fee-percentage)) u100))
    (consumer-payment (- (get compensation agreement) platform-fee))
  )
    (begin
      ;; Check if agreement exists and is active
      (asserts! (is-some (map-get? data-sharing-agreements agreement-id)) (err u404))
      (asserts! (get active agreement) (err u403))

      ;; Check if caller is the retailer in the agreement
      (asserts! (is-eq tx-sender (get retailer agreement)) (err u401))

      ;; Update consumer earnings
      (let ((current-earnings (default-to u0 (map-get? consumer-earnings (get consumer agreement)))))
        (map-set consumer-earnings
          (get consumer agreement)
          (+ current-earnings consumer-payment)
        )
      )

      ;; Return success
      (ok true)
    )
  )
)

;; Read-only function to get agreement details
(define-read-only (get-agreement (agreement-id uint))
  (map-get? data-sharing-agreements agreement-id)
)

;; Read-only function to get consumer earnings
(define-read-only (get-consumer-earnings (consumer principal))
  (default-to u0 (map-get? consumer-earnings consumer))
)

;; Function to update fee percentage (admin only)
(define-public (update-fee-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= new-percentage u100) (err u400))
    (ok (var-set fee-percentage new-percentage))
  )
)
