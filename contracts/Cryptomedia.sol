// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Cryptomedia
 * @author neuroswish
 *
 * Implement batched bonding curves for continuous tokens governing cryptomedia
 *
 * "All of you Mario, it's all a game"
 */

contract Cryptomedia is BondingCurve, ReentrancyGuardUpgradeable {
    // ======== Continuous token params ========
    uint256 public totalSupply; // total supply of tokens in circulation
    uint32 public reserveRatio; // reserve ratio in ppm
    uint32 public ppm = 1000000; // ppm units
    uint256 public slopeN; // slope numerator value for initial token return computation
    uint256 public slopeD; // slope denominator value for initial token return computation
    uint256 public poolBalance; // ETH balance in contract pool
    uint256 public buyFeePct; // 10**17
    uint256 public sellFeePct; // 10 **17
    uint256 public pctBase = 10**18;
    // ======== Player params ========
    address payable creator;
    uint256 creatorReward;
    address payable[] beneficiaries;
    mapping(address => uint256) beneficiaryIndex;
    mapping(address => bool) addressIsBeneficiary;
    mapping(address => uint256) beneficiaryRewards;
    mapping(address => uint256) private totalBalance; // mapping of an address to that user's total token balance for this contract

    // ======== Layer params ========
    string public foundationURI; // URI of foundational layer
    struct Layer {
        address payable creator; // layer creator
        string URI; // layer content URI
        //address[] curators; // list of curators
        uint256 stakedTokens; // total amount of tokens staked in layer
        mapping(address => uint256) amountStakedByCurator; // mapping from a curator to the amount of tokens the curator has staked
    }

    Layer[] public layers; // array of all layers
    //mapping(uint256 => Layer) public indexToLayer; // mapping from layer index to layer
    mapping(address => uint256[]) public addressToLayerIndex; // mapping from address to layer index staked by that address
    uint256 layerIndex = 1; // initialize layerIndex (foundational layer has index of 0)

    // ======== Events ========
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

    // ======== Constructor ========
    constructor(
        address payable _creator
        uint32 _reserveRatio,
        uint256 _slopeN,
        uint256 _slopeD,
        uint256 _buyFeePct,
        uint256 _sellFeePct
    ) {
        creator = _creator;
        reserveRatio = _reserveRatio;
        slopeN = _slopeN;
        slopeD = _slopeD;
        buyFeePct = _buyFeePct;
        sellFeePct = _sellFeePct;
    }

    // ======== Initializer for new market proxy ========
    function initialize(
        string calldata _foundationURI,
        address payable _creator
    ) public initializer {
        creator = _creator;
        foundationURI = _foundationURI;
        __ReentrancyGuard_init();
    }

    // ======== Functions ========
    function buy(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _price,
        uint256 _minTokensReturned
    ) internal nonReentrant returns (bool, uint256) {
        require(msg.value == _price && msg.value > 0);
        require(_minTokensReturned > 0);
        // calculate creator and beneficiary fees
        uint256 value = _price;
        uint256 reward = (_price * buyFeePct) / pctBase;
        value -= reward;
        // calculate tokens returned
        uint256 tokensReturned;
        if (_totalSupply == 0) {
            uint256 slope = (slopeN / slopeD);
            tokensReturned = calculateInitializationReturn(
                value,
                reserveRatio,
                slope
            );
            require(
                tokensReturned >= _minTokensReturned,
                "quantity of tokens returned falls outside slippage tolerance"
            );
        } else {
            tokensReturned = calculatePurchaseReturn(
                _totalSupply,
                _poolBalance,
                reserveRatio,
                value
            );
            require(
                tokensReturned >= _minTokensReturned,
                "quantity of tokens returned falls outside slippage tolerance"
            );
        }
        totalSupply += tokensReturned;
        totalBalance[msg.sender] += tokensReturned;
        if (!addressIsBeneficiary[msg.sender]) {
            addressIsBeneficiary[msg.sender] = true;
            beneficiaries.push(msg.sender);
        }
        poolBalance += value;
        calculateRewards(reward, totalSupply);
        return (true, tokensReturned);
    }

    function calculateRewards(uint256 _totalRewardAmount, uint256 _totalSupply)
        internal
    {
        uint256 buyCreatorReward = _totalRewardAmount / 2;
        creatorReward += buyCreatorReward;
        uint256 totalBeneficiaryReward = buyCreatorReward;
        for (uint256 i; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            uint256 reward = totalBeneficiaryReward *
                (totalBalance[beneficiary] / totalSupply);
            beneficiaryRewards[beneficiary] += reward;
        }
    }

    function sell(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _tokens,
        uint256 _minETHReturned,
        uint256 _layerIndex
    ) internal nonReentrant returns (bool) {
        require(
            _tokens > 0 &&
                layers[_layerIndex].amountStakedByCurator[msg.sender] >= _tokens
        );
        require(_minETHReturned > 0);
        uint256 ethReturned = calculateSaleReturn(
            _totalSupply,
            _poolBalance,
            reserveRatio,
            _tokens
        );
        require(
            ethReturned >= _minETHReturned,
            "quantity of ETH returned falls outside slippage tolerance"
        );
        sendValue(payable(msg.sender), ethReturned);
        poolBalance -= ethReturned;
        layers[_layerIndex].amountStakedByCurator[msg.sender] -= _tokens;
        totalSupply -= _tokens;
        totalBalance[msg.sender] -= _tokens;
        if (totalBalance[msg.sender] == 0) {
            addressIsBeneficiary[msg.sender] = false;
            for (uint256 i; i < beneficiaries.length; i++) {
                if (beneficiaries[i] == msg.sender) {
                    beneficiaries[i] = beneficiaries[beneficiaries.length - 1];
                    beneficiaries.pop();
                }
            }
        }
        return true;
    }

    function addLayer(string memory _contentURI, uint256 _minTokensToStake)
        public
        payable
        returns (bool)
    {
        uint256 tokensReturned;
        (, tokensReturned) = buy(
            totalSupply,
            poolBalance,
            msg.value,
            _minTokensToStake
        );
        Layer storage newLayer = layers[layerIndex];
        newLayer.URI = _contentURI;
        addressToLayerIndex[msg.sender].push(layerIndex);
        layers[layerIndex].amountStakedByCurator[msg.sender] += tokensReturned;
        layerIndex++;
        return true;
    }

    function addStake(uint256 _layerIndex, uint256 _minTokensToStake)
        public
        payable
        returns (bool)
    {
        uint256 tokensReturned;
        (, tokensReturned) = buy(
            totalSupply,
            poolBalance,
            msg.value,
            _minTokensToStake
        );
        layers[_layerIndex].amountStakedByCurator[msg.sender] += tokensReturned;
        addressToLayerIndex[msg.sender].push(layerIndex);
        return true;
    }

    function removeStake(
        uint256 _layerIndex,
        uint256 _amountToRemove,
        uint256 _minETHReturned
    ) internal returns (bool) {
        sell(
            totalSupply,
            poolBalance,
            _amountToRemove,
            _minETHReturned,
            _layerIndex
        );
        // if stake is completely removed
        if (layers[_layerIndex].amountStakedByCurator[msg.sender] == 0) {
            // remove layer from user's portfolio
            if (addressToLayerIndex[msg.sender].length > 1) {
                addressToLayerIndex[msg.sender][
                    _layerIndex
                ] = addressToLayerIndex[msg.sender][
                    addressToLayerIndex[msg.sender].length - 1
                ];
            }
            addressToLayerIndex[msg.sender].pop();
        }
        return true;
    }

    function claimBeneficiaryReward(address payable _beneficiary) public returns(bool) {
        require(addressIsBeneficiary[_beneficiary]);
        sendValue(_beneficiary, beneficiaryRewards[_beneficiary]);
        return true;
    }

    function claimCreatorReward(address payable _creator) public returns(bool) {
        require(creator == _creator);
        sendValue(_creator, creatorReward);
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
