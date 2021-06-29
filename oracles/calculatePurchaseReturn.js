const { Validator } = require('@chainlink/external-adapter');

const customParams = {
    reserveRatio: 'reserveRatio',
    poolBalance: 'poolBalance',
    supply: 'supply',
    price: 'price'
}

const createRequest = (input, callback) => {
    // validator to help validate Chainlink request data
    const validator = new Validator(callback, input, customParams)
    const jobRunID = validator.validated.id

    // inputs
    const reserveRatio = validator.validated.data.reserveRatio
    const poolBalance = validator.validated.data.poolBalance
    const supply = validator.validated.data.supply
    const price = validator.validated.data.price

    // calculate price based on inputs
    k = calculatePurchaseReturn(poolBalance, price, supply, reserveRatio)

    // return result
    callback(200,
        {
            "id": jobRunID,
            "data": {
                "tokens": k
            }
        })
}

// calculate the number of tokens k minted by paying a price p, given a pool balance b, supply s, and reserve ratio r
function calculatePurchaseReturn(b, p, s, r) {
    k = s * (((p/b) + 1)**(r) - 1)
    return k
}
