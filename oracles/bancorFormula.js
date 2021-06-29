const { Requester, Validator } = require('@chainlink/external-adapter');

// Define custom error scenarios for the API.
// Return true for the adapter to retry.
const customError = (data) => {
    if (data.Response === 'Error') return true
    return false
}

const customParams = {
    reserveRatio: 'reserveRatio',
    price: 'price',
    tokens: 'tokens',
    poolBalance: 'poolBalance',
    supply: 'supply'
}

const createRequest = (input, callback) => {
    // Validator to help validate Chainlink request data
    const validator = new Validator(callback, input, customParams)
    const jobRunID = validator.validated.id
    // input vars
    const reserveRatio = validator.validated.data.reserveRatio
    const price = validator.validated.data.price
    const tokens = validator.validated.data.tokens
    const poolBalance = validator.validated.data.poolBalance
    const supply = validator.validated.data.supply

    var params = {
        reserveRatio,
        price,
        tokens,
        poolBalance,
        supply
    }
}

// calculate the price p of buying k tokens, given a pool balance b, supply s, and reserve ratio r
function calculatePrice(b, k, s, r) {
    p = b * (((k/s) + 1)**(1/r) - 1)
    return p
}

// calculate the number of tokens k minted by paying a price p, given a pool balance b, supply s, and reserve ratio r
function calculatePurchaseReturn(b, p, s, r) {
    k = s * (((p/b) + 1)**(r) - 1)
    return k
}

function calculateSaleReturn(b, k, s, r) {
    eth = b * (1 - (1 - (k/s))**(1/r))
    return eth
}

console.log(calculatePrice(3, 25, 100, (1/3)))
console.log(calculatePurchaseReturn(3, 2.86, 100, (1/3)))
console.log(calculateSaleReturn(5.859375, 25, 125, (1/3)))
