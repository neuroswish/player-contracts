// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBondingCurve.sol";
import "./interfaces/ISignal.sol";
import "./libraries/Base64.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Social Market
 *
 * "All of you Mario, it's all a game"
 */

contract Market is ReentrancyGuard, Initializable {
    // ======== Interface addresses ========
    address public factory; // factory address
    address public bondingCurve; // bonding curve interface address
    address public signalToken; // signal token address

    // ======== Continuous token params ========
    string public name; // market name
    string public symbol; // market symbol
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // token units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public signalTokenSupply; // signal provider token supply
    uint256 public totalSupply; // total supply of tokens in circulation
    uint256 public feePct; // transaction fee distributed to signalers
    uint256 public feeBase; // transaction fee base
    mapping(address => uint256) public balanceOf; // mapping of an address to that user's total token balance
    mapping(address => mapping(address => uint256)) public allowance;

    // ======== User params ========
    mapping(address => string) public userInteractions; // mapping from an address to a URI of that address's interactions in this market
    mapping(address => mapping(address => uint256)) public tokensStakedToUser; // mapping to amount of tokens staked by a user to another user
    mapping(address => uint256) public totalTokensStakedByUser; // mapping from an address to the amount of tokens the address has staked
    mapping(address => uint256) public totalTokensStakedToUser; // mapping from an address to the amount of tokens staked to that address
    mapping(address => uint256) public signalBalanceOf; // signal token balance for a user

    // ======== Events ========
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );
    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );
    event Staked(
        address indexed staker,
        address indexed stakee,
        uint256 amountStaked,
        uint256 signalTokensMinted
    );
    event Unstaked(
        address indexed staker,
        address indexed stakee,
        uint256 amountRemovedFromStakingPool,
        uint256 signalTokensBurned
    );
    event Redeemed(
        address indexed staker,
        address indexed stakee,
        uint256 stakerReward,
        uint256 stakeeReward
    );

    // ERC-20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    modifier holder(address user) {
        require(balanceOf[user] > 0, "MUST HOLD TOKENS");
        _;
    }

    // ======== Initializer for new market proxy ========
    /**
     * @notice Initialize a new market
     * @dev Sets reserveRatio, ppm, fee, name, and bondingCurve address; called by factory at time of deployment
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _bondingCurve,
        address _signalToken
    ) external initializer {
        reserveRatio = 333333;
        ppm = 1000000;
        feePct = (5**17);
        feeBase = (10**18);
        name = _name;
        symbol = _symbol;
        bondingCurve = _bondingCurve;
        signalToken = _signalToken;
        //__ReentrancyGuard_init();
    }

    // ======== Functions ========
    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success; callable by anyone
     */
    function buy(uint256 _price, uint256 _minTokensReturned) external payable {
        require(msg.value == _price && msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        // calculate tokens returned
        uint256 tokensReturned;
        if (totalSupply == 0) {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(_price, reserveRatio);
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    _price
                );
        }
        // calculate reward fee
        uint256 reward = (tokensReturned * feePct) / feeBase;
        tokensReturned -= reward;
        // make sure final token amount is within slippage tolerance
        require(tokensReturned >= _minTokensReturned, "SLIPPAGE");
        // add reward fee to staking pool
        _mint(address(this), reward);
        // mint tokens for buyer
        _mint(msg.sender, tokensReturned);
        poolBalance += _price;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, _price);
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(uint256 _tokens, uint256 _minETHReturned)
        external
        holder(msg.sender)
        nonReentrant
    {
        require(
            _tokens > 0 && _tokens <= balanceOf[msg.sender],
            "INVALID TOKEN AMT"
        );
        require(poolBalance > 0, "PB<0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        if (_tokens == balanceOf[msg.sender]) {
            require(
                signalBalanceOf[msg.sender] == 0,
                "MUST BURN ALL SIGNAL TOKENS BEFORE SELLING ALL SUPPLY"
            );
        }
        // calculate ETH returned
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        // burn tokens
        _burn(msg.sender, _tokens);
        poolBalance -= ethReturned;
        sendValue(payable(msg.sender), ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
    }

    /**
     * @notice Stake tokens to a user to signal importance
     * @dev Emits a Staked event upon success; callable by holders
     */
    function stake(address _stakee, uint256 _amount)
        external
        holder(msg.sender)
    {
        require(balanceOf[_stakee] > 0, "NOT IN NETWORK");
        require(
            _amount > 0 && _amount >= balanceOf[msg.sender],
            "INVALID AMOUNT"
        );
        // calculate number signal provider tokens to mint
        uint256 signal;
        if (signalTokenSupply == 0) {
            signal = _amount;
        } else {
            signal = (_amount * signalTokenSupply) / balanceOf[address(this)];
        }
        require(signal > 0, "INSUFFICIENT_SIGNAL_MINTED");
        // transfer LP tokens
        signalBalanceOf[msg.sender] += signal;
        // add new LP tokens minted to total LP token supply
        signalTokenSupply += signal;
        approve(address(this), _amount);
        transferFrom(msg.sender, address(this), _amount);
        totalTokensStakedByUser[msg.sender] += _amount;
        tokensStakedToUser[msg.sender][_stakee] += _amount;
        totalTokensStakedToUser[_stakee] += _amount;
        emit Staked(msg.sender, _stakee, _amount, signal);
    }

    /**
     * @notice Unstake tokens from a user to remove signal
     * @dev Emits an Unstaked event upon success & burns signal tokens for the staker-stakee connection; callable by holders
     */
    function unstake(address _stakee) external holder(msg.sender) nonReentrant {
        require(tokensStakedToUser[msg.sender][_stakee] > 0, "NO STAKE");
        // get number of signal tokens to burn to return stake (should be equal to tokens staked for the user specified)
        uint256 signalTokensToBurn = tokensStakedToUser[msg.sender][_stakee];
        // calculate the number of tokens to send return to the user based on their pro-rata share of the signal token pool
        uint256 tokensToGetBack = (signalTokensToBurn *
            balanceOf[address(this)]) / signalTokenSupply;
        // make sure that number is greater than or equal to the number of staked tokens in the contract
        require(
            tokensToGetBack >= balanceOf[address(this)],
            "INSUFFICIENT SUPPLY"
        );
        // send the user the tokens
        transfer(msg.sender, tokensToGetBack);
        // deduct the signal tokens from the user's signal token balance
        signalBalanceOf[msg.sender] -= signalTokensToBurn;
        // deduct the signal tokens from the total signal token balance
        signalTokenSupply -= signalTokensToBurn;
        // set the tokens staked to the specified user by msg.sender to 0
        tokensStakedToUser[msg.sender][_stakee] = 0;
        emit Unstaked(msg.sender, _stakee, tokensToGetBack, signalTokensToBurn);
    }

    /**
     * @notice Redeem reward tokens from a staking connection
     * @dev Emits a Redeemed event upon success & transfers reward tokens to both staker and stakee; callable by staker or stakee for a staking connection
     */
    function redeem(address _staker, address _stakee)
        external
        holder(msg.sender)
    {
        require(msg.sender == _stakee || msg.sender == _staker);
        require(tokensStakedToUser[_staker][_stakee] > 0, "NO STAKE");
        // calculate number of signal tokens
        uint256 signalTokens = tokensStakedToUser[_staker][_stakee];
        // calculate the number of tokens to return to the staker based on their pro-rata share of the signal token pool
        uint256 tokensToGetBack = (signalTokens * balanceOf[address(this)]) /
            signalTokenSupply;
        // make sure that number is greater than or equal to the number of staked tokens in the contract
        require(
            tokensToGetBack >= balanceOf[address(this)],
            "INSUFFICIENT SUPPLY"
        );
        // calculate profit to redeem
        uint256 profit = tokensToGetBack - signalTokens;
        // if there's no profit, then nothing to redeem; revert
        require(profit > 0, "NOTHING TO REDEEM");
        // calculate equal reward for staker and contributor
        uint256 reward = profit / 2;
        // transfer tokens to staker and contributor from staking pool supply
        // the associated profit from this relationship is now taken out of the staking pool
        transfer(_staker, reward);
        transfer(_stakee, reward);
        emit Redeemed(_staker, _stakee, profit, profit);
    }

    // ============ Public helper functions ============

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy, emits a Transfer event upon success
     */
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INVALID AMT");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("REVERTED");
        emit Transfer(address(this), msg.sender, amount);
        require(success);
    }

    // ============ ERC-20 ============

    /**
     * @notice Mints tokens
     * @dev Emits a Transfer event upon success
     */
    function _mint(address _to, uint256 _value) private {
        totalSupply = totalSupply + _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(address(0), _to, _value);
    }

    /**
     * @notice Burns tokens
     * @dev Emits a Transfer event upon success
     */
    function _burn(address _from, uint256 _value) private {
        balanceOf[_from] = balanceOf[_from] - _value;
        totalSupply = totalSupply - _value;
        emit Transfer(_from, address(0), _value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(this), "TRANSFER PROHIBITED");
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        if (to == address(this)) {
            require(msg.sender == address(this), "TRANSFER PROHIBITED");
        }
        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }
}
