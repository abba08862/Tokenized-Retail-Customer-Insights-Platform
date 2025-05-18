;; Consumer Identity Contract
;; This contract manages shopper profiles

(define-data-var admin principal tx-sender)
(define-data-var last-error (string-utf8 256) u"")

;; Map to store consumer profiles
(define-map consumer-profiles principal
  {
    username: (string-utf8 50),
    preferences-hash: (buff 32),
    registration-date: uint,
    active: bool
  }
)

;; Public function for consumers to register
(define-public (register-consumer (username (string-utf8 50)) (preferences-hash (buff 32)))
  (begin
    (asserts! (is-none (map-get? consumer-profiles tx-sender)) (err u400))
    (ok (map-set consumer-profiles tx-sender
      {
        username: username,
        preferences-hash: preferences-hash,
        registration-date: block-height,
        active: true
      }
    ))
  )
)

;; Public function for consumers to update their profile
(define-public (update-profile (username (string-utf8 50)) (preferences-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? consumer-profiles tx-sender)) (err u404))
    (ok (map-set consumer-profiles tx-sender
      {
        username: username,
        preferences-hash: preferences-hash,
        registration-date: (get registration-date (default-to
          { username: u"", preferences-hash: 0x0000000000000000000000000000000000000000000000000000000000000000, registration-date: u0, active: false }
          (map-get? consumer-profiles tx-sender))),
        active: true
      }
    ))
  )
)

;; Public function to deactivate a profile
(define-public (deactivate-profile)
  (let ((profile (default-to
          { username: u"", preferences-hash: 0x0000000000000000000000000000000000000000000000000000000000000000, registration-date: u0, active: false }
          (map-get? consumer-profiles tx-sender))))
    (begin
      (asserts! (is-some (map-get? consumer-profiles tx-sender)) (err u404))
      (ok (map-set consumer-profiles tx-sender
        {
          username: (get username profile),
          preferences-hash: (get preferences-hash profile),
          registration-date: (get registration-date profile),
          active: false
        }
      ))
    )
  )
)

;; Read-only function to get consumer profile
(define-read-only (get-consumer-profile (consumer principal))
  (map-get? consumer-profiles consumer)
)

;; Function to check if a consumer is active
(define-read-only (is-active-consumer (consumer principal))
  (default-to false (get active (map-get? consumer-profiles consumer)))
)
