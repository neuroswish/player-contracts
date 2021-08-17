// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBondingCurve.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Implement information markets
 *
 * "All of you Mario, it's all a game"
 */

contract Market is ReentrancyGuardUpgradeable {
    // ======== Interface addresses ========
    address public bondingCurve;

    // ======== Continuous token params ========
    string public name; // market name
    string public symbol; // market token symbol
    uint256 public totalSupply; // total supply of tokens in circulation
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm; // ppm units
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public feePct; // percentage fee of buy amount distributed to beneficiaries (10**17)
    uint256 public pctBase; // 10**18

    // ======== Player params ========
    address[] public curators; // addresses of active curators
    mapping(address => uint256) public rewards; // mapping from curator to their proportional reward amount for curating
    mapping(address => uint256) public totalBalance; // mapping of an address to that user's total token balance for this contract
    mapping(address => bool) public isCurating; // mapping of an address to bool representing whether address is currently staking
    mapping(address => mapping(uint256 => bool)) public isCuratingLayer; // mapping of an address to mapping representing whether address is staking a layer

    // ======== Layer params ========
    struct Layer {
        address creator; // layer creator
        string URI; // layer content URI
        address[] curators; // addresses curating this layer
    }
    Layer[] public layers; // array of all layers
    mapping(address => uint256[]) public addressToCuratedLayerIndex; // mapping from a curator address to layer index staked by that address
    mapping(address => uint256[]) public addressToCreatedLayerIndex; // mapping from a curator address to layer index staked by that address
    uint256 layerIndex = 0; // initialize layerIndex (foundational layer will have an index of 0)

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
    event LayerAdded(
        address indexed creator,
        string contentURI,
        uint256 layerIndex
    );
    event Curated(address indexed curator, uint256 layerIndex);
    event Removed(address indexed curator, uint256 layerIndex);
    event RewardsAdded(uint256 totalRewardAmount);
    event RewardClaimed(address indexed beneficiary);

    // ======== Modifiers ========
    /**
     * @notice Check to see if address holds tokens
     */
    modifier holder(address user) {
        require(totalBalance[user] > 0, "MUST HOLD TOKENS");
        _;
    }

    // ======== Initializer for new market proxy ========
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _bondingCurve
    ) public payable initializer {
        reserveRatio = 333333;
        ppm = 1000000;
        feePct = 10**17;
        pctBase = 10**18;
        name = _name;
        symbol = _symbol;
        bondingCurve = _bondingCurve;
        __ReentrancyGuard_init();
    }

    // ======== Functions ========

    /**
     * @notice Buy market tokens with ETH
     * @dev Emits a Buy event upon success; callable by anyone
     */
    function buy(uint256 _price, uint256 _minTokensReturned)
        public
        payable
        returns (bool)
    {
        require(msg.value == _price && msg.value > 0, "INVALID PRICE");
        require(_minTokensReturned > 0, "INVALID SLIPPAGE");
        // calculate beneficiary fees
        uint256 value = _price;
        uint256 reward = (_price * feePct) / pctBase;
        value -= reward;
        // calculate tokens returned
        uint256 tokensReturned;
        if (totalSupply == 0) {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculateInitializationReturn(value, reserveRatio);
            require(tokensReturned >= _minTokensReturned, "SLIPPAGE");
        } else {
            tokensReturned = IBondingCurve(bondingCurve)
                .calculatePurchaseReturn(
                    totalSupply,
                    poolBalance,
                    reserveRatio,
                    value
                );
            require(tokensReturned >= _minTokensReturned, "SLIPPAGE");
        }
        totalSupply += tokensReturned;
        totalBalance[msg.sender] += tokensReturned;
        poolBalance += value;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, value);
        calculateRewards(reward);
        return true;
    }

    /**
     * @notice Calculate beneficiary rewards for a buy event
     * @dev Emits a RewardsAdded event upon success; internally called by buy
     */
    function calculateRewards(uint256 _totalRewardAmount) internal {
        for (uint256 i; i < curators.length; i++) {
            address beneficiary = curators[i];
            uint256 reward = _totalRewardAmount *
                (totalBalance[beneficiary] / totalSupply);
            rewards[beneficiary] += reward;
        }
        emit RewardsAdded(_totalRewardAmount);
    }

    /**
     * @notice Sell market tokens for ETH
     * @dev Emits a Sell event upon success; callable by token holders
     */
    function sell(uint256 _tokens, uint256 _minETHReturned)
        public
        holder(msg.sender)
        nonReentrant
        returns (bool)
    {
        require(
            _tokens > 0 && _tokens <= totalBalance[msg.sender],
            "INVALID TOKEN AMT"
        );
        require(poolBalance > 0, "PB<0");
        require(_minETHReturned > 0, "INVALID SLIPPAGE");
        uint256 ethReturned = IBondingCurve(bondingCurve).calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned, "SLIPPAGE");
        poolBalance -= ethReturned;
        totalSupply -= _tokens;
        totalBalance[msg.sender] -= _tokens;
        sendValue(msg.sender, ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
        if (totalBalance[msg.sender] == 0) {
            for (uint256 i; i < curators.length; i++) {
                if (curators[i] == msg.sender) {
                    curators[i] = curators[curators.length - 1];
                    curators.pop();
                }
            }
        }
        return true;
    }

    /**
     * @notice Add a layer to the information market
     * @dev Emits a LayerAdded event upon success; callable by token holders
     */
    function addLayer(string memory _URI)
        public
        holder(msg.sender)
        returns (bool)
    {
        Layer memory layer;
        layer.URI = _URI;
        layer.creator = msg.sender;
        layers[layerIndex] = layer;
        addressToCreatedLayerIndex[msg.sender].push(layerIndex);
        layerIndex++;
        emit LayerAdded(msg.sender, _URI, layerIndex);
        return true;
    }

    /**
     * @notice Curate a layer to the information market by specifying the layer index
     * @dev Emits a Curated event upon success; callable by token holders
     */
    function curate(uint256 _layerIndex)
        public
        holder(msg.sender)
        returns (bool)
    {
        if (isCuratingLayer[msg.sender][_layerIndex]) {
            revert("CURATED");
        } else {
            addressToCuratedLayerIndex[msg.sender].push(_layerIndex);
            if (!isCurating[msg.sender]) {
                isCurating[msg.sender] = true;
                curators.push(msg.sender);
            }
            emit Curated(msg.sender, _layerIndex);
            return true;
        }
    }

    /**
     * @notice Remove a curation from a layer in the information market by specifying the layer index
     * @dev Emits a Removed event upon success; callable by token holders, will revert if holder is not currently curating the layer
     */
    function removeCuration(uint256 _layerIndex)
        public
        holder(msg.sender)
        returns (bool)
    {
        if (!isCuratingLayer[msg.sender][_layerIndex]) {
            revert("NOT CURATED");
        }
        for (
            uint256 i;
            i < addressToCuratedLayerIndex[msg.sender].length;
            i++
        ) {
            if (addressToCuratedLayerIndex[msg.sender][i] == _layerIndex) {
                addressToCuratedLayerIndex[msg.sender][
                    i
                ] = addressToCuratedLayerIndex[msg.sender][
                    addressToCuratedLayerIndex[msg.sender].length - 1
                ];
                addressToCuratedLayerIndex[msg.sender].pop();
            }
        }
        if (addressToCuratedLayerIndex[msg.sender].length == 0) {
            isCurating[msg.sender] = false;
            for (uint256 i; i < curators.length; i++) {
                if (curators[i] == msg.sender) {
                    curators[i] = curators[curators.length - 1];
                    curators.pop();
                }
            }
        }
        emit Removed(msg.sender, _layerIndex);
        return true;
    }

    /**
     * @notice Claim beneficiary rewards allotted to curators for curating layers in the information market
     * @dev Emits a RewardClaimed event upon success; callable by anyone, will revert if no rewards to be collected
     */
    function claimReward(address _beneficiary)
        public
        nonReentrant
        returns (bool)
    {
        require(rewards[_beneficiary] > 0, "NO REWARDS");
        sendValue(_beneficiary, rewards[_beneficiary]);
        rewards[_beneficiary] = 0;
        emit RewardClaimed(_beneficiary);
        return true;
    }

    // ============ Utility ============

    /**
     * @notice Send ETH in a safe manner
     * @dev Prevents reentrancy
     */
    function sendValue(address recipient, uint256 amount)
        internal
        nonReentrant
    {
        require(address(this).balance >= amount, "INVALID AMT");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("REVERTED");
        require(success);
    }
}
