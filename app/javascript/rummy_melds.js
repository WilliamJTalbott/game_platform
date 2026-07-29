// A direct port of Rummy::Meld's rule predicates (app/models/rummy/meld.rb) for
// client-side gating only — the server stays authoritative. Operates on plain
// { rankValue, suitIndex } cards, not DOM nodes.

export function isSet(cards) {
  return cards.length >= 3 &&
    uniqueBy(cards, "rankValue").length === 1 &&
    uniqueBy(cards, "suitIndex").length === cards.length
}

export function isRun(cards) {
  return cards.length >= 3 && uniqueBy(cards, "suitIndex").length === 1 && consecutiveRanks(cards)
}

export function kindOf(cards) {
  if (isSet(cards)) return "set"
  if (isRun(cards)) return "run"
  return null
}

export function isMeld(cards) {
  return kindOf(cards) !== null
}

export function canAdd(meldCards, newCards) {
  if (newCards.length === 0) return false

  return kindOf(meldCards.concat(newCards)) === kindOf(meldCards)
}

function uniqueBy(cards, key) {
  return [ ...new Set(cards.map((card) => card[key])) ]
}

function consecutiveRanks(cards) {
  const values = uniqueBy(cards, "rankValue").sort((a, b) => a - b)
  return values.length === cards.length && values[values.length - 1] - values[0] === values.length - 1
}
