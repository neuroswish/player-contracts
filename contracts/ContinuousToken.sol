// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";

/**
 * @title Bonding Curve
 * @author neuroswish
 *
 * Implement bonding curves governing the pricing of continuous tokens
 *
 * "All of you Mario, it's all a game"
 */

contract ContinuousToken is BondingCurve {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint32 public reserveRatio;
    uint32 public ppm = 1000000;
    uint256 public virtualSupply;
    uint256 public virtualBalance;

    uint256 public poolBalance;

    uint256 public waitingClear;
    uint256 public batchBlocks;

    struct Batch {
        bool init;
        bool buysCleared;
        bool sellsCleared;
        bool cleared;
        uint256 poolBalance;
        uint256 supply;
        uint256 totalBuySpend;
        uint256 totalBuyReturn;
        uint256 totalSellSpend;
        uint256 totalSellReturn;
        mapping(address => uint256) buyers;
        mapping(address => uint256) sellers;
    }

    mapping(uint256 => Batch) public batches;
    mapping(address => uint256[]) public addressToBlocks;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event Buy(
        address indexed to,
        uint256 poolBalance,
        uint256 supply,
        uint256 tokens,
        uint256 price
    );
    event Sell(
        address indexed from,
        uint256 poolBalance,
        uint256 supply,
        uint256 tokens,
        uint256 eth
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _batchBlocks,
        uint32 _reserveRatio,
        uint256 _virtualSupply,
        uint256 _virtualBalance
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        batchBlocks = _batchBlocks;

        reserveRatio = _reserveRatio;
        virtualSupply = _virtualSupply;
        virtualBalance = _virtualBalance;
    }

    function currentBatch() public view returns (uint256 cb) {
        cb = (block.number / batchBlocks) * batchBlocks;
    }

    function getuserBlocks(address user)
        public
        view
        returns (uint256[] memory)
    {
        return addressToBlocks[user];
    }

    function getUserBlocksLength(address user) public view returns (uint256) {
        return addressToBlocks[user].length;
    }

    function getUserBlocksByIndex(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        return addressToBlocks[user][index];
    }

    function isUserBuyerByBlock(address user, uint256 index)
        public
        view
        returns (bool)
    {
        return batches[index].buyers[user] > 0;
    }

    function isUserSellerByBlock(address user, uint256 index)
        public
        view
        returns (bool)
    {
        return batches[index].sellers[user] > 0;
    }

    function getBuy(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _price
    ) public view returns (uint256) {
        return
            calculatePurchaseReturn(
                (_supply + virtualSupply),
                (_poolBalance + virtualBalance),
                reserveRatio,
                _price
            );
    }

    function getSell(
        uint256 _supply,
        uint256 _poolBalance,
        uint256 _tokens
    ) public view returns (uint256) {
        return
            calculateSaleReturn(
                (_supply + virtualSupply),
                (_poolBalance + virtualBalance),
                reserveRatio,
                _tokens
            );
    }

    function addBuy(address sender) public payable returns (bool) {
        uint256 batch = currentBatch();
        Batch storage cb = batches[batch]; // current batch
        if (!cb.init) {
            initBatch(batch);
        }
        cb.totalBuySpend += msg.value;
        if (cb.buyers[sender] == 0) {
            addressToBlocks[sender].push(batch);
        }
        cb.buyers[sender] += msg.value;
        return true;
    }

    function addSell(uint256 amount) public returns (bool) {
        require(
            balanceOf(msg.sender) >= amount,
            "insufficient funds for sell order"
        );
        uint256 batch = currentBatch();
        Batch storage cb = batches[batch]; // current batch
        if (!cb.init) {
            initBatch(batch);
        }
        cb.totalSellSpend += amount;
        if (cb.sellers[msg.sender] == 0) {
            addressToBlocks[msg.sender].push(batch);
        }
        cb.sellers[msg.sender] += amount;
        require(_burn(msg.sender, amount), "burn must succeed");
        return true;
    }

    function initBatch(uint256 batch) internal {
        clearBatch();
        batches[batch].poolBalance = poolBalance;
        batches[batch].supply = supply_;
        batches[batch].init = true;
        waitingClear = batch;
    }

    function clearBatch() public {
        if (waitingClear == 0) return;
        require(waitingClear > currentBatch(), "Can't clear an active batch");
        Batch storage cb = batches[waitingClear]; // clearing batch
        if (cb.cleared) return;
        clearMatching();

        poolBalance = cb.poolBalance;

        // The supply was decremented when _burns took place as the sell orders came in.
        // Now the supply needs to be incremented by totalBuyReturn.
        // The resulting tokens are held by this contract until collected by the buyers
        require(
            _mint(this, cb.totalBuyReturn),
            "minting new tokens to be held until buyers collect must succeed"
        );
        cb.cleared = true;
        waitingClear = 0;
    }

    function clearMatching() internal {
        Batch storage cb = batches[waitingClear];

        // the static price is the current exact price in collateral
        // per token according to the initial state of the batch
        uint256 staticPrice = getPricePPM(cb.supply, cb.poolBalance);

        // We want to find out if there are more buy orders or more sell orders.
        // To do this we check the result of all sells and all buys at the current exact price.
        // If the result of the sells is larger than the pending buys, there are more sells.
        // If the result of the buys is larger than the pending sells, there are more buys.
        // Of course we don't really need to check both; if one is true the other is false.

        uint256 resultOfSell = (cb.totalSellSpend * staticPrice) / ppm;

        // We check if the result of the sells was more than the pending buys to determine if there were more sells than buys.
        // If that is the case we will execute all pending buy orders at the current exact price, because there is at least one sell order for each buy.
        // The remaining sell orders will be executed using the traditional bonding curve.
        // The final sell price will be a combination of the exact price and the bonding curve price.
        // Further down we will do the opposite if there are more buys than sells.

        // if more sells than buys
        if (resultOfSell >= cb.totalBuySpend) {
            // totalBuyReturn is the number of tokens bought as a result of all buy orders combined at the currend exact price.
            // We have already determined that this number is less than the total amount of tokens to be sold.
            // tokens = totalBuySpend / staticPrice.
            // TODO staticPrice is in PPM; to avoid rounding errors it has been rearranged with PPM as a numerator
            cb.totalBuyReturn = (cb.totalBuySpend * ppm) / staticPrice;
            cb.buysCleared = true;

            // We know there should be some tokens left over to be sold with the curve.
            // These should be the difference between teh original total sell order and the result of executing all the buys
            uint256 remainingSell = cb.totalSellSpend - cb.totalBuyReturn;

            // Now that we know how many tokens are left to be sold we can get the amount of collateral generatedby selling them through normal bonding curve execution.
            // This is based on the original supply and poolBalance (as if the buy orders never existed and the sell order was just smaller than originally thought).
            uint256 remainingSellReturn = getSell(
                cb.supply,
                cb.poolBalance,
                remainingSell
            );

            // The total result of all sells is the original amount of buys which were matched, plus the remaining sells executed with the bonding curve.
            cb.totalSellReturn = cb.totalBuySpend + remainingSellReturn;

            // supply doesn't need to be changed.
            // It only needs to be changed by clearSales or clearBuys scenario
        }
    }
}
