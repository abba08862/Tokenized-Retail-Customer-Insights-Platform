;; Transaction Tracking Contract
;; This contract records purchasing patterns

(define-data-var admin principal tx-sender)

;; Define trait for retailer verification contract
(define-trait retailer-verification-trait
  (
    (is-verified-retailer (principal) (response bool uint))
  )
)

;; Map to store transaction records
(define-map transactions uint
  {
    consumer: principal,
    retailer: principal,
    amount: uint,
    category: (string-utf8 50),
    timestamp: uint
  }
)

;; Counter for transaction IDs
(define-data-var transaction-counter uint u0)

;; Public function to record a transaction (only verified retailers can call)
(define-public (record-transaction
  (consumer principal)
  (amount uint)
  (category (string-utf8 50))
  (retailer-verification-contract <retailer-verification-trait>))
  (let ((tx-id (var-get transaction-counter)))
    (begin
      ;; Check if retailer is verified using the retailer verification contract
      (asserts! (unwrap-panic (contract-call? retailer-verification-contract is-verified-retailer tx-sender)) (err u401))

      ;; Record the transaction
      (map-set transactions tx-id
        {
          consumer: consumer,
          retailer: tx-sender,
          amount: amount,
          category: category,
          timestamp: block-height
        }
      )

      ;; Increment the transaction counter
      (var-set transaction-counter (+ tx-id u1))

      ;; Return the transaction ID
      (ok tx-id)
    )
  )
)

;; Read-only function to get transaction details
(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions tx-id)
)

;; Read-only function to get the current transaction counter
(define-read-only (get-transaction-count)
  (var-get transaction-counter)
)
