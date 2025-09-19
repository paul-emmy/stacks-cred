;; StacksCred - Decentralized Content Creator Monetization Protocol
;;
;; Summary:
;; StacksCred enables creators to monetize content through community-driven validation,
;; stake-weighted voting, and Bitcoin-secured reputation scoring on Stacks Layer 2.
;;
;; Description:
;; A comprehensive protocol that transforms content monetization by combining economic
;; incentives with social validation. Creators stake STX, publish content, and earn
;; rewards based on community curation. Built with cryptoeconomic mechanisms that
;; reward quality while penalizing spam, creating a sustainable creator economy
;; backed by Bitcoin's security and Stacks' smart contract capabilities.

;; CONSTANTS & ERROR DEFINITIONS

(define-constant contract-owner tx-sender)

;; Error constants for comprehensive error handling
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-self-interaction (err u106))
(define-constant err-already-voted (err u107))
(define-constant err-invalid-score (err u108))
(define-constant err-stake-required (err u109))
(define-constant err-cooldown-active (err u110))
(define-constant err-invalid-input (err u111))

;; PROTOCOL CONFIGURATION VARIABLES

(define-data-var contract-enabled bool true)
(define-data-var min-stake-amount uint u1000000) ;; 1 STX minimum stake
(define-data-var reputation-multiplier uint u100)
(define-data-var content-reward-pool uint u0)
(define-data-var platform-fee-rate uint u50) ;; 0.5% platform fee

;; CORE DATA STRUCTURES

;; User profile and reputation tracking
(define-map users
  principal
  {
    reputation-score: uint,
    total-content: uint,
    total-earnings: uint,
    stake-amount: uint,
    last-action-block: uint,
    verified: bool,
    join-block: uint,
  }
)

;; Content metadata and performance metrics
(define-map content
  uint
  {
    creator: principal,
    content-hash: (string-ascii 64),
    title: (string-utf8 100),
    category: (string-ascii 20),
    timestamp: uint,
    total-votes: uint,
    positive-votes: uint,
    quality-score: uint,
    reward-claimed: bool,
    stake-backing: uint,
  }
)

;; Voting records with stake-weighted influence
(define-map votes
  {
    content-id: uint,
    voter: principal,
  }
  {
    vote-type: bool, ;; true = upvote, false = downvote
    stake-weight: uint,
    timestamp: uint,
  }
)

;; Social graph connections
(define-map user-following
  {
    follower: principal,
    following: principal,
  }
  bool
)

;; Reputation change audit trail
(define-map reputation-history
  {
    user: principal,
    block: uint,
  }
  {
    old-score: uint,
    new-score: uint,
    reason: (string-ascii 50),
  }
)

;; SEQUENCE COUNTERS

(define-data-var content-id-nonce uint u0)

;; INPUT VALIDATION FUNCTIONS

(define-private (validate-content-hash (hash (string-ascii 64)))
  (let ((hash-len (len hash)))
    (and (>= hash-len u32) (<= hash-len u64))
  )
)

(define-private (validate-title (title (string-utf8 100)))
  (let ((title-len (len title)))
    (and (>= title-len u1) (<= title-len u100))
  )
)

(define-private (validate-category (category (string-ascii 20)))
  (let ((category-len (len category)))
    (and (>= category-len u1) (<= category-len u20))
  )
)

(define-private (validate-content-id (content-id uint))
  (and (> content-id u0) (<= content-id (var-get content-id-nonce)))
)

(define-private (validate-amount (amount uint))
  (and (> amount u0) (<= amount u1000000000000)) ;; Reasonable upper limit
)

(define-private (validate-user (user principal))
  (is-some (map-get? users user))
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-contract-info)
  {
    enabled: (var-get contract-enabled),
    min-stake: (var-get min-stake-amount),
    reputation-multiplier: (var-get reputation-multiplier),
    reward-pool: (var-get content-reward-pool),
    platform-fee: (var-get platform-fee-rate),
  }
)

(define-read-only (get-user-profile (user principal))
  (map-get? users user)
)

(define-read-only (get-user-reputation (user principal))
  (default-to u0 (get reputation-score (map-get? users user)))
)

(define-read-only (get-content-details (content-id uint))
  (if (validate-content-id content-id)
    (map-get? content content-id)
    none
  )
)

(define-read-only (get-vote-details (content-id uint) (voter principal))
  (if (validate-content-id content-id)
    (map-get? votes {
      content-id: content-id,
      voter: voter,
    })
    none
  )
)

(define-read-only (is-following (follower principal) (following principal))
  (default-to false
    (map-get? user-following {
      follower: follower,
      following: following,
    })
  )
)