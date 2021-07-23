// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Implement batched bonding curves governing the price and supply of continuous tokens
 *
 * "All of you Mario, it's all a game"
 */

contract Bio is BondingCurve, ReentrancyGuardUpgradeable {
    // ======== continuous token params ========
    uint256 public totalSupply; // total supply of tokens in circulation
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm = 1000000; // ppm units
    uint256 public slopeN = 1; // slope numerator value for initial token return computation
    uint256 public slopeD = 100000; // slope denominator value for initial token return computation

    uint256 public poolBalance; // ETH balance in contract pool

    uint256 public waitingClear; // ID of batch waiting to be cleared
    uint256 public batchBlocks; // number of blocks batches are to last

    address payable creator;
    uint256 public buyFeePct; // 10**17
    uint256 public sellFeePct; // 10 **17
    uint256 public pctBase = 10**18;

    // defining a batch of buys and sells that lasts over a number of blocks
    struct Batch {
        bool init; // batch has been initialized
        bool buysCleared; // buys have been cleared
        bool sellsCleared; // sells have been cleared
        bool cleared; // batch has been cleared
        uint256 poolBalance; // ETH balance in contract pool
        uint256 totalSupply; // total supply of tokens
        uint256 totalBuySpend; // total ETH being spent in batch to buy tokens
        uint256 totalBuyReturn; // total number of tokens to be returned in batch
        uint256 totalSellSpend; // total number of tokens being sold in batch
        uint256 totalSellReturn; // total ETH being transfered to sellers in batch
        uint256 totalCreatorFee; // total ETH from transaction fees transferred to creator
        mapping(address => uint256) buyers; // mapping of buyer to quantity of tokens he is buying
        mapping(address => uint256) sellers; // mapping of seller to quantity of tokens he is selling
    }

    mapping(uint256 => Batch) public batches; // mapping of batch ID to batch
    mapping(address => uint256[]) public addressToBlocks; // mapping of a user to an array of block indices specifying the batch in which he has a transaction

    mapping(address => uint256) private balance; // mapping of an address to that user's token balance

    //TODO
    string[] public mediaURIs;
    mapping(string => uint256) stakedTokens;
    mapping(string => address) mediaCreator;

    event Mint(address indexed to, uint256 amount); // emit amount of tokens minted to a user
    event Burn(address indexed burner, uint256 amount); // emit amount of a user's token that are burned
    event Buy(
        address indexed to,
        uint256 poolBalance,
        uint256 supply,
        uint256 tokens,
        uint256 price
    ); // emit a buy event
    event Sell(
        address indexed from,
        uint256 poolBalance,
        uint256 supply,
        uint256 tokens,
        uint256 eth
    ); // emit a sell event

    // constructor
    constructor(
        uint32 _reserveRatio,
        uint256 _batchBlocks,
        uint256 _slopeN,
        uint256 _slopeD,
        uint256 _buyFeePct,
        uint256 _sellFeePct
    ) {
        reserveRatio = _reserveRatio;
        batchBlocks = _batchBlocks;
        slopeN = _slopeN;
        slopeD = _slopeD;
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;
    }

    // intialize new cryptomedia
    function initialize(address payable _creator) public initializer {
        creator = _creator;
        __ReentrancyGuard_init();
    }

    // get the batch ID of the current batch
    function currentBatch() public view returns (uint256 cb) {
        cb = (block.number / batchBlocks) * batchBlocks;
    }

    // given a user address, get the block numbers corresponding to the batch in which the user has a transaction
    function getUserBlocks(address user)
        public
        view
        returns (uint256[] memory)
    {
        return addressToBlocks[user];
    }

    // given a user address, get the number of blocks corresponding to the batch in which the user has a transaction
    function getUserBlocksLength(address user) public view returns (uint256) {
        return addressToBlocks[user].length;
    }

    // given a user address & batch block index, get the corresponding block in which the user has a transaction
    function getUserBlocksByIndex(address user, uint256 index)
        public
        view
        returns (uint256)
    {
        return addressToBlocks[user][index];
    }

    // given a user address & batch block index, return whether user is a buyer
    function isUserBuyerByBlock(address user, uint256 index)
        public
        view
        returns (bool)
    {
        return batches[index].buyers[user] > 0;
    }

    // given a user address & batch block index, return whether user is a seller
    function isUserSellerByBlock(address user, uint256 index)
        public
        view
        returns (bool)
    {
        return batches[index].sellers[user] > 0;
    }

    // returns token price in parts per million
    function getPricePPM(uint256 _totalSupply, uint256 _poolBalance)
        public
        view
        returns (uint256)
    {
        return (uint256(ppm) * _poolBalance) / (_totalSupply * reserveRatio);
    }

    // calculate the amount of tokens to be minted given total supply, pool balance, and amount of ETH being paid
    function getBuy(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _price
    ) public view returns (uint256) {
        if (_totalSupply == 0) {
            uint256 slope = (slopeN / slopeD); // define initialization slope
            return calculateInitializationReturn(_price, reserveRatio, slope); // get initialization return if supply is 0
        } else {
            return
                calculatePurchaseReturn(
                    (_totalSupply),
                    (_poolBalance),
                    reserveRatio,
                    _price
                );
        }
    }

    // calculate the amount of ETH to be exchanged given the total supply, pool balance, and quantity of tokens being sold
    function getSell(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _tokens
    ) public view returns (uint256) {
        return
            calculateSaleReturn(
                (_totalSupply),
                (_poolBalance),
                reserveRatio,
                _tokens
            );
    }

    // add a buy event to the current batch
    function addBuy(address sender) public payable returns (bool) {
        uint256 batch = currentBatch(); // get the current batch ID
        Batch storage cb = batches[batch]; // get the current batch
        // if the current batch has not been initialized, initialize as a new batch
        if (!cb.init) {
            initBatch(batch);
        }
        // get creator fee
        uint256 value = msg.value;
        uint256 fee = (msg.value * buyFeePct) / pctBase;
        value -= fee;
        // add the ETH being paid by the buyer to the total amount being spent for the current batch
        cb.totalBuySpend += value;
        // if the buyer has not been recorded as a buyer in the current batch, add the current batch ID (a block ID) to the list of blocks in which the user has a transaction
        if (cb.buyers[sender] == 0) {
            addressToBlocks[sender].push(batch);
        }
        // add the ETH being paid by the buyer to the total amount that he has spent in this batch
        cb.buyers[sender] += value;
        // add the ETH from transaction fees to the total amount to be transferred to the creator in this batch
        cb.totalCreatorFee += fee;
        // if all the above steps succeed, return true
        return true;
    }

    function addSell(uint256 amount) public returns (bool) {
        // check to make sure the seller has enough tokens to sell
        require(
            balanceOf(msg.sender) >= amount,
            "insufficient funds for sell order"
        );
        uint256 batch = currentBatch(); // get the current batch ID
        Batch storage cb = batches[batch]; // get the current batch
        // if the current batch has not been initialized, initialize as a new batch
        if (!cb.init) {
            initBatch(batch);
        }
        // add the tokens being sold by the seller to the total amount being sold for the current batch
        cb.totalSellSpend += amount;
        // if the seller has not been recorded as a seller in the current batch, add the current batch ID (a block ID) to the list of blocks in which the user has a transaction
        if (cb.sellers[msg.sender] == 0) {
            addressToBlocks[msg.sender].push(batch);
        }
        // add the tokens being sold by the seller to the total amount that he has sold in this batch
        cb.sellers[msg.sender] += amount;
        // check to make sure the seller's tokens get burned
        require(_burn(msg.sender, amount), "burn must succeed");
        // if all the above steps succeed, return true
        return true;
    }

    // initialize a new batch
    function initBatch(uint256 batch) internal {
        clearBatch(); // clear any existing batches
        batches[batch].poolBalance = poolBalance; // set the batch's pool balance to the contract's pool balance
        batches[batch].totalSupply = totalSupply; // set the batch's total supply to the contract's total supply
        batches[batch].init = true; // set initialization status to true
        waitingClear = batch; // set the ID of the batch waiting to be cleared to the current batch's ID
    }

    // clear a batch
    function clearBatch() public {
        if (waitingClear == 0) return; // if no batch waiting to be cleared, return
        require(waitingClear < currentBatch(), "Can't clear an active batch"); // check to make sure the batch (given number of batch blocks as specified in contract initialization) has elapsed before clearing it
        Batch storage cb = batches[waitingClear]; // set cb to the batch that is waiting to be cleared
        if (cb.cleared) return;
        clearMatching();

        poolBalance = cb.poolBalance;

        // The supply was decremented when _burns took place as the sell orders came in.
        // Now the supply needs to be incremented by totalBuyReturn.
        // The resulting tokens are held by this contract until collected by the buyers
        require(
            _mint(address(this), cb.totalBuyReturn),
            "minting new tokens to be held until buyers collect must succeed"
        );
        sendValue(creator, cb.totalCreatorFee);
        cb.cleared = true;
        waitingClear = 0;
    }

    function clearMatching() internal {
        Batch storage cb = batches[waitingClear];

        // the static price is the current exact price in collateral per token (in parts per million) according to the initial state of the batch
        uint256 staticPrice = getPricePPM(cb.totalSupply, cb.poolBalance);

        // We want to find out if there are more buy orders or more sell orders.
        // To do this we check the result of all sells and all buys at the current exact price.
        // If the result of the sells is larger than the pending buys, there are more sells.
        // If the result of the buys is larger than the pending sells, there are more buys.
        // Of course we don't really need to check both; if one is true the other is false.

        uint256 resultOfSell = (cb.totalSellSpend * staticPrice) / ppm; // ETH

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
            // staticPrice is in PPM; to avoid rounding errors it has been rearranged with PPM as a numerator
            cb.totalBuyReturn = (cb.totalBuySpend * ppm) / staticPrice;
            cb.buysCleared = true;

            // We know there should be some tokens left over to be sold with the curve.
            // These should be the difference between the original total sell order and the result of executing all the buys
            uint256 remainingSell = cb.totalSellSpend - cb.totalBuyReturn;

            // Now that we know how many tokens are left to be sold we can get the amount of collateral generated by selling them through normal bonding curve execution.
            // This is based on the original supply and poolBalance (as if the buy orders never existed and the sell order was just smaller than originally thought).
            uint256 remainingSellReturn = getSell(
                cb.totalSupply,
                cb.poolBalance,
                remainingSell
            );

            // The total result of all sells is the original amount of buys which were matched, plus the remaining sells executed with the bonding curve.
            cb.totalSellReturn = cb.totalBuySpend + remainingSellReturn;

            // supply doesn't need to be changed
            // It will be changed with the _mint and _burn functions
            // poolBalance is ultimately only affected by the net difference between the buys and sells
            cb.poolBalance -= remainingSellReturn;
            cb.sellsCleared = true;
            // more buys than sells
        } else {
            // Now in this scenario there were more buys than sells.
            // This means that resultOfSell that we calculated earlier is the total result of sell
            cb.totalSellReturn = resultOfSell; // ETH
            cb.sellsCleared = true;

            // There is some collateral left over to be spent as buy orders.
            // This should be the difference between the original total buy order and the result of executing all the sells
            uint256 remainingBuy = cb.totalBuySpend - resultOfSell; // residual ETH used to buy tokens

            // Now that we know how much collateral is left to be spent we can get the amount of tokens generated by spending it through a normal bonding curve execution.
            // This is based on the original supply and poolBalance (as if the sell orders never existed and the buy order was just smaller than originally thought).
            uint256 remainingBuyReturn = getBuy(
                cb.totalSupply,
                cb.poolBalance,
                remainingBuy
            );

            // totalBuyReturn becomes the combination of all the sell orders + the resulting tokens from the remaining buy orders
            cb.totalBuyReturn = cb.totalSellSpend + remainingBuyReturn;

            // Again, supply doesn't need to be changed, as it will be changed when the _mint function is called upon users claiming tokens
            // poolBalance is ultimately only affected by the net difference between the buys and the sells
            cb.poolBalance += remainingBuy;
            cb.buysCleared = true;
        }
    }

    function claimSell(uint256 batch, address sender) public nonReentrant {
        Batch storage cb = batches[batch]; // claiming batch
        require(cb.cleared, "can't claim a batch that hasn't cleared");
        require(cb.sellers[sender] != 0, "this address has no sell to claim");
        // calculate individual return
        uint256 individualSellReturn = (cb.totalSellReturn *
            cb.sellers[sender]) / cb.totalSellSpend;
        cb.sellers[sender] = 0;
        // calculate creator fee
        uint256 fee = (individualSellReturn * sellFeePct) / pctBase;
        individualSellReturn -= fee;
        sendValue(payable(sender), individualSellReturn);
        sendValue(creator, fee);
    }

    function claimBuy(uint256 batch, address sender) public {
        Batch storage cb = batches[batch]; // claiming batch
        require(cb.cleared, "can't claim a batch that hasn't cleared");
        require(cb.buyers[sender] != 0, "this address has no buy to claim");
        uint256 individualBuyReturn = (cb.buyers[sender] * cb.totalBuyReturn) /
            cb.totalBuySpend;
        cb.buyers[sender] = 0;
        require(
            _burn(address(this), individualBuyReturn),
            "burn must succeed to close claim"
        );
        require(
            _mint(sender, individualBuyReturn),
            "mint must succeed to close claim"
        );
    }

    /// @dev Mint new tokens with ether
    /// @param minter The address of the user minting tokens
    /// @param tokens The number of tokens to mint
    function _mint(address minter, uint256 tokens) internal returns (bool) {
        totalSupply += tokens;
        balance[minter] += tokens;
        emit Mint(minter, tokens);
        return true;
    }

    /// @dev Burn tokens to receive ether
    /// @param burner The address of the user burning tokens
    /// @param tokens The number of tokens to burn
    function _burn(address burner, uint256 tokens) internal returns (bool) {
        totalSupply -= tokens;
        balance[burner] -= tokens;
        emit Burn(burner, tokens);
        return true;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return balance[account];
    }

    // ============ Utility ============

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}
