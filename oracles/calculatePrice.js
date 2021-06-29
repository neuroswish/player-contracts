const { Validator } = require('@chainlink/external-adapter');

const customParams = {
    reserveRatio: 'reserveRatio',
    poolBalance: 'poolBalance',
    supply: 'supply',
    tokens: 'tokens'
}

const createRequest = (input, callback) => {
    // validator to help validate Chainlink request data
    const validator = new Validator(callback, input, customParams)
    const jobRunID = validator.validated.id

    // inputs
    const reserveRatio = validator.validated.data.reserveRatio
    const poolBalance = validator.validated.data.poolBalance
    const supply = validator.validated.data.supply
    const tokens = validator.validated.data.tokens

    // calculate price based on inputs
    p = calculatePrice(poolBalance, tokens, supply, reserveRatio)

    // return result
    callback(200,
        {
            "id": jobRunID,
            "data": {
                "price": p
            }
        })
}

// function to calculate the price p of buying k tokens, given a pool balance b, supply s, and reserve ratio r
function calculatePrice(b, k, s, r) {
    p = b * (((k/s) + 1)**(1/r) - 1)
    return p
}

