;; Data structure to store poll details
(define-map polls
  {id: uint}
  {
    question: (buff 120),
    options: (list 10 (buff 50)),
    start: uint,
    end: uint
  })

;; Data structure to track votes
(define-map votes
  {poll-id: uint, voter: principal}
  {option-index: uint})

;; Public function to create a poll
(define-public (create-poll (id uint) (question (buff 120)) (options (list 10 (buff 50))) (start uint) (end uint))
  (begin
    (asserts! (is-none (map-get polls {id: id})) (err "Poll already exists"))
    (asserts! (< start end) (err "Invalid poll duration"))
    (map-set polls {id: id} {question: question, options: options, start: start, end: end})
    (ok "Poll created successfully")))

;; Public function to cast a vote
(define-public (vote (poll-id uint) (option-index uint))
  (let ((poll (map-get polls {id: poll-id})))
    (asserts! (is-some poll) (err "Poll not found"))
    (asserts! (is-none (map-get votes {poll-id: poll-id, voter: tx-sender})) (err "Already voted"))
    (asserts! (>= block-height (get start poll)) (err "Poll not started"))
    (asserts! (<= block-height (get end poll)) (err "Poll ended"))
    (map-set votes {poll-id: poll-id, voter: tx-sender} {option-index: option-index})
    (ok "Vote casted successfully"))))

;; Read-only function to get the results of a poll
(define-read-only (get-results (poll-id uint))
  (fold votes
    (fn (key {poll-id: uint, voter: principal} value {option-index: uint} acc (map 10 uint))
      (if (is-eq poll-id poll-id)
        (map-set acc value.option-index (+ (get value.option-index acc u0) u1))
        acc))
    (map 10 u0)))

;; Read-only function to check poll details
(define-read-only (get-poll (poll-id uint))
  (default-to (err "Poll not found") (map-get polls {id: poll-id})))
