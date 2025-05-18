;; Retailer Verification Contract
;; This contract validates merchants on the platform

(define-data-var admin principal tx-sender)

;; Map to store verified retailers
(define-map verified-retailers principal
  {
    name: (string-utf8 100),
    website: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to verify a retailer (only admin can call)
(define-public (verify-retailer (retailer principal) (name (string-utf8 100)) (website (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set verified-retailers retailer
      {
        name: name,
        website: website,
        verified: true,
        verification-date: block-height
      }
    ))
  )
)

;; Public function to check if a retailer is verified
(define-read-only (is-verified-retailer (retailer principal))
  (default-to false (get verified (map-get? verified-retailers retailer)))
)

;; Public function to get retailer details
(define-read-only (get-retailer-details (retailer principal))
  (map-get? verified-retailers retailer)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
