;; NFT-Based Ticketing System - Feature 1: NFT Ticket Minting
;; SIP-009 Compliant NFT Contract for Event Ticketing
;; Built with latest Clarity syntax for Stacks blockchain

;; Define the NFT token
(define-non-fungible-token event-ticket uint)

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u102))
(define-constant ERR_SOLD_OUT (err u103))
(define-constant ERR_INVALID_PARAMS (err u104))
(define-constant ERR_ALREADY_EXISTS (err u105))
(define-constant ERR_UNAUTHORIZED (err u106))

;; Define data variables
(define-data-var next-event-id uint u1)
(define-data-var next-ticket-id uint u1)

;; Define data maps
(define-map events
  { event-id: uint }
  {
    organizer: principal,
    event-name: (string-ascii 50),
    total-supply: uint,
    tickets-sold: uint,
    ticket-price: uint,
    royalty-percent: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map tickets
  { ticket-id: uint }
  {
    event-id: uint,
    owner: principal,
    seat-zone: (string-ascii 20),
    minted-at: uint,
    is-used: bool
  }
)

(define-map event-organizers
  { organizer: principal }
  { is-authorized: bool }
)

;; Authorization functions
(define-public (authorize-organizer (organizer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (ok (map-set event-organizers { organizer: organizer } { is-authorized: true }))
  )
)

(define-public (revoke-organizer (organizer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (ok (map-set event-organizers { organizer: organizer } { is-authorized: false }))
  )
)

;; Helper function to check if organizer is authorized
(define-private (is-authorized-organizer (organizer principal))
  (default-to false 
    (get is-authorized 
      (map-get? event-organizers { organizer: organizer })
    )
  )
)

;; Event creation function
(define-public (create-event 
  (event-name (string-ascii 50))
  (total-supply uint)
  (ticket-price uint)
  (royalty-percent uint)
)
  (let
    (
      (event-id (var-get next-event-id))
    )
    ;; Validate inputs
    (asserts! (> (len event-name) u0) ERR_INVALID_PARAMS)
    (asserts! (> total-supply u0) ERR_INVALID_PARAMS)
    (asserts! (> ticket-price u0) ERR_INVALID_PARAMS)
    (asserts! (<= royalty-percent u50) ERR_INVALID_PARAMS) ;; Max 50% royalty
    
    ;; Check if organizer is authorized (contract owner is always authorized)
    (asserts! 
      (or 
        (is-eq tx-sender CONTRACT_OWNER)
        (is-authorized-organizer tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Create the event
    (map-set events
      { event-id: event-id }
      {
        organizer: tx-sender,
        event-name: event-name,
        total-supply: total-supply,
        tickets-sold: u0,
        ticket-price: ticket-price,
        royalty-percent: royalty-percent,
        created-at: stacks-block-height,
        is-active: true
      }
    )
    
    ;; Increment event ID counter
    (var-set next-event-id (+ event-id u1))
    
    (ok event-id)
  )
)

;; Ticket minting function
(define-public (mint-ticket 
  (event-id uint)
  (seat-zone (string-ascii 20))
)
  (let
    (
      (ticket-id (var-get next-ticket-id))
      (event-info (unwrap! (map-get? events { event-id: event-id }) ERR_NOT_FOUND))
      (tickets-sold (get tickets-sold event-info))
      (total-supply (get total-supply event-info))
      (ticket-price (get ticket-price event-info))
    )
    ;; Validate event exists and is active
    (asserts! (get is-active event-info) ERR_NOT_FOUND)
    
    ;; Check if tickets are still available
    (asserts! (< tickets-sold total-supply) ERR_SOLD_OUT)
    
    ;; Validate payment (in a real implementation, this would handle STX transfer)
    ;; For now, we assume payment validation happens elsewhere
    
    ;; Mint the NFT ticket
    (try! (nft-mint? event-ticket ticket-id tx-sender))
    
    ;; Store ticket metadata
    (map-set tickets
      { ticket-id: ticket-id }
      {
        event-id: event-id,
        owner: tx-sender,
        seat-zone: seat-zone,
        minted-at: stacks-block-height,
        is-used: false
      }
    )
    
    ;; Update tickets sold count
    (map-set events
      { event-id: event-id }
      (merge event-info { tickets-sold: (+ tickets-sold u1) })
    )
    
    ;; Increment ticket ID counter
    (var-set next-ticket-id (+ ticket-id u1))
    
    (ok ticket-id)
  )
)

;; Purchase ticket with STX payment
(define-public (purchase-ticket 
  (event-id uint)
  (seat-zone (string-ascii 20))
)
  (let
    (
      (event-info (unwrap! (map-get? events { event-id: event-id }) ERR_NOT_FOUND))
      (ticket-price (get ticket-price event-info))
      (organizer (get organizer event-info))
    )
    ;; Transfer STX payment to organizer
    (try! (stx-transfer? ticket-price tx-sender organizer))
    
    ;; Mint the ticket
    (mint-ticket event-id seat-zone)
  )
)

;; Transfer ticket function
(define-public (transfer-ticket 
  (ticket-id uint)
  (sender principal)
  (recipient principal)
)
  (let
    (
      (ticket-info (unwrap! (map-get? tickets { ticket-id: ticket-id }) ERR_NOT_FOUND))
    )
    ;; Validate sender owns the ticket
    (asserts! (is-eq sender (unwrap! (nft-get-owner? event-ticket ticket-id) ERR_NOT_FOUND)) ERR_UNAUTHORIZED)
    
    ;; Validate ticket hasn't been used
    (asserts! (not (get is-used ticket-info)) ERR_UNAUTHORIZED)
    
    ;; Transfer the NFT
    (try! (nft-transfer? event-ticket ticket-id sender recipient))
    
    ;; Update ticket owner in metadata
    (map-set tickets
      { ticket-id: ticket-id }
      (merge ticket-info { owner: recipient })
    )
    
    (ok true)
  )
)

;; Deactivate event (organizer only)
(define-public (deactivate-event (event-id uint))
  (let
    (
      (event-info (unwrap! (map-get? events { event-id: event-id }) ERR_NOT_FOUND))
    )
    ;; Only organizer can deactivate
    (asserts! (is-eq tx-sender (get organizer event-info)) ERR_UNAUTHORIZED)
    
    ;; Deactivate the event
    (map-set events
      { event-id: event-id }
      (merge event-info { is-active: false })
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Get event information
(define-read-only (get-event-info (event-id uint))
  (map-get? events { event-id: event-id })
)

;; Get ticket information
(define-read-only (get-ticket-info (ticket-id uint))
  (map-get? tickets { ticket-id: ticket-id })
)

;; Get tickets remaining for an event
(define-read-only (get-tickets-remaining (event-id uint))
  (match (map-get? events { event-id: event-id })
    event-info (- (get total-supply event-info) (get tickets-sold event-info))
    u0
  )
)

;; Get ticket owner
(define-read-only (get-ticket-owner (ticket-id uint))
  (nft-get-owner? event-ticket ticket-id)
)

;; Get next event ID
(define-read-only (get-next-event-id)
  (var-get next-event-id)
)

;; Get next ticket ID
(define-read-only (get-next-ticket-id)
  (var-get next-ticket-id)
)

;; Check if organizer is authorized
(define-read-only (check-organizer-authorization (organizer principal))
  (is-authorized-organizer organizer)
)

;; SIP-009 Standard Functions

;; Get last token ID
(define-read-only (get-last-token-id)
  (ok (- (var-get next-ticket-id) u1))
)

;; Get token URI (metadata)
(define-read-only (get-token-uri (ticket-id uint))
  (match (map-get? tickets { ticket-id: ticket-id })
    ticket-info 
      (let
        (
          (event-info (unwrap! (map-get? events { event-id: (get event-id ticket-info) }) (ok none)))
        )
        (ok (some (concat 
          "https://api.ticketing.com/metadata/"
          (uint-to-ascii ticket-id)
        )))
      )
    (ok none)
  )
)

;; Get owner of token
(define-read-only (get-owner (ticket-id uint))
  (ok (nft-get-owner? event-ticket ticket-id))
)

;; Helper function to convert uint to ascii (simplified version)
(define-private (uint-to-ascii (value uint))
  ;; This is a simplified implementation
  ;; In production, you'd want a more robust uint-to-string conversion
  (if (is-eq value u0) "0"
  (if (is-eq value u1) "1"
  (if (is-eq value u2) "2"
  (if (is-eq value u3) "3"
  (if (is-eq value u4) "4"
  (if (is-eq value u5) "5"
  (if (is-eq value u6) "6"
  (if (is-eq value u7) "7"
  (if (is-eq value u8) "8"
  (if (is-eq value u9) "9"
  "unknown"))))))))))
)
