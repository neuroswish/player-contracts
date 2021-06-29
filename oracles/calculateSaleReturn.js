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
    eth = calculateSaleReturn(poolBalance, tokens, supply, reserveRatio)

    // return result
    callback(200,
        {
            "id": jobRunID,
            "data": {
                "ETH": eth
            }
        })
}

// calculate the amount of ETH returned when selling k tokens, given a pool balance b, supply s, and reserve ratio r
function calculateSaleReturn(b, k, s, r) {
    eth = b * (1 - (1 - (k/s))**(1/r))
    return eth
}
