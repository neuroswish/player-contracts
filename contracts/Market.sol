// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Implement layered cryptomedia markets
 *
 * "All of you Mario, it's all a game"
 */

contract Market is BondingCurve, ReentrancyGuardUpgradeable {
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
    event LayerAdded(
        address indexed creator,
        string contentURI,
        uint256 layerIndex
    );
    event Curated(address indexed curator, uint256 layerIndex);
    event Removed(address indexed curator, uint256 layerIndex);
    event RewardsAdded(uint256 totalRewardAmount);
    event RewardClaimed(address indexed beneficiary);
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

    // ======== Modifiers ========
    modifier holder(address user) {
        require(totalBalance[user] > 0);
        _;
    }

    // ======== Initializer for new market proxy ========
    function initialize(string calldata _name, string calldata _symbol)
        public
        payable
        initializer
    {
        reserveRatio = 333333;
        ppm = 1000000;
        feePct = 10**17;
        pctBase = 10**18;
        name = _name;
        symbol = _symbol;
        __ReentrancyGuard_init();
    }

    function buy(uint256 _price, uint256 _minTokensReturned)
        public
        payable
        returns (bool)
    {
        require(msg.value == _price && msg.value > 0);
        require(_minTokensReturned > 0);
        // calculate beneficiary fees
        uint256 value = _price;
        uint256 reward = (_price * feePct) / pctBase;
        value -= reward;
        // calculate tokens returned
        uint256 tokensReturned;
        if (totalSupply == 0) {
            tokensReturned = calculatePurchaseReturn(
                0,
                poolBalance,
                reserveRatio,
                value
            );
            require(tokensReturned >= _minTokensReturned);
        } else {
            tokensReturned = calculatePurchaseReturn(
                totalSupply,
                poolBalance,
                reserveRatio,
                value
            );
            require(tokensReturned >= _minTokensReturned);
        }
        totalSupply += tokensReturned;
        totalBalance[msg.sender] += tokensReturned;
        poolBalance += value;
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, value);
        calculateRewards(reward);
        return true;
    }

    function calculateRewards(uint256 _totalRewardAmount) internal {
        for (uint256 i; i < curators.length; i++) {
            address beneficiary = curators[i];
            uint256 reward = _totalRewardAmount *
                (totalBalance[beneficiary] / totalSupply);
            rewards[beneficiary] += reward;
        }
        emit RewardsAdded(_totalRewardAmount);
    }

    function sell(uint256 _tokens, uint256 _minETHReturned)
        public
        holder(msg.sender)
        nonReentrant
        returns (bool)
    {
        require(
            _tokens > 0 &&
                poolBalance > 0 &&
                _tokens <= totalBalance[msg.sender]
        );
        require(_minETHReturned > 0);
        uint256 ethReturned = calculateSaleReturn(
            totalSupply,
            poolBalance,
            reserveRatio,
            _tokens
        );
        require(ethReturned >= _minETHReturned);
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

    function curate(uint256 _layerIndex)
        public
        holder(msg.sender)
        returns (bool)
    {
        if (isCuratingLayer[msg.sender][_layerIndex]) {
            revert("already staked");
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

    function removeCuration(uint256 _layerIndex)
        public
        holder(msg.sender)
        returns (bool)
    {
        if (!isCuratingLayer[msg.sender][_layerIndex]) {
            revert("no stake");
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

    function claimReward(address _beneficiary)
        public
        nonReentrant
        returns (bool)
    {
        require(rewards[_beneficiary] > 0);
        sendValue(_beneficiary, rewards[_beneficiary]);
        rewards[_beneficiary] = 0;
        emit RewardClaimed(_beneficiary);
        return true;
    }

    // ============ Utility ============

    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount);

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success);
    }
}
