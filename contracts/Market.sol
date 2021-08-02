// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
import "./BondingCurve.sol";
import "./MarketStorage.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Market
 * @author neuroswish
 *
 * Implement layered cryptomedia markets
 *
 * "All of you Mario, it's all a game"
 */

contract Market is MarketStorage, BondingCurve, ReentrancyGuardUpgradeable {
    // ======== Events ========
    event FoundationLayerAdded(
        address indexed creator,
        string foundationURI,
        uint256 layerIndex
    );
    event LayerAdded(
        address indexed layerCreator,
        string contentURI,
        uint256 layerIndex,
        uint256 tokensStaked
    );
    event Staked(
        address indexed curator,
        uint256 layerIndex,
        uint256 tokensStaked
    );
    event Removed(
        address indexed curator,
        uint256 layerIndex,
        uint256 tokensRemoved
    );
    event CreatorClaimed(address indexed creator);
    event BeneficiaryClaimed(address indexed beneficiary);
    event InitialSupplyCreated(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 price
    );
    event Buy(
        address indexed buyer,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 price
    );

    event RewardsAdded(uint256 totalRewardAmount);

    event Sell(
        address indexed seller,
        uint256 poolBalance,
        uint256 totalSupply,
        uint256 tokens,
        uint256 eth
    );

    // ======== Modifiers ========
    modifier marketInitialized() {
        require(supplyInitialized);
        _;
    }

    // ======== Constructor ========
    constructor(
        uint32 _reserveRatio,
        uint256 _slopeN,
        uint256 _slopeD,
        uint256 _feePct
    ) {
        reserveRatio = _reserveRatio;
        slopeN = _slopeN;
        slopeD = _slopeD;
        feePct = _feePct;
    }

    // ======== Initializer for new market proxy ========
    function initialize(address _creator, string calldata _foundationURI)
        public
        payable
        initializer
    {
        creator = _creator;
        foundationURI = _foundationURI;
        Layer storage foundationalLayer = layers[layerIndex];
        foundationalLayer.URI = _foundationURI;
        foundationalLayer.layerCreator = creator;
        emit FoundationLayerAdded(creator, _foundationURI, layerIndex);
        __ReentrancyGuard_init();
    }

    // ======== Functions ========
    function initializeSupply(uint256 _eth) public payable {
        require(msg.sender == creator);
        require(_eth == msg.value);
        uint256 tokensReturned;
        uint256 slope = (slopeN / slopeD);
        tokensReturned = calculateInitializationReturn(
            msg.value,
            reserveRatio,
            slope
        );
        totalSupply += tokensReturned;
        totalBalance[creator] += tokensReturned;
        poolBalance += _eth;
        emit InitialSupplyCreated(creator, poolBalance, totalSupply, msg.value);
        layers[layerIndex].stakedTokens += tokensReturned;
        layers[layerIndex].amountStakedByCurator[creator] += tokensReturned;
        addressToLayerIndex[creator].push(layerIndex);
        layerIndex++;
        supplyInitialized = true;
    }

    function buy(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _price,
        uint256 _minTokensReturned
    ) internal marketInitialized returns (bool, uint256) {
        require(msg.value == _price && msg.value > 0);
        require(_minTokensReturned > 0);
        // calculate creator and beneficiary fees
        uint256 value = _price;
        uint256 reward = (_price * feePct) / pctBase;
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
        emit Buy(msg.sender, poolBalance, totalSupply, tokensReturned, value);
        calculateRewards(reward);
        return (true, tokensReturned);
    }

    function calculateRewards(uint256 _totalRewardAmount) internal {
        uint256 buyCreatorReward = _totalRewardAmount / 2;
        creatorReward += buyCreatorReward;
        uint256 totalBeneficiaryReward = buyCreatorReward;
        for (uint256 i; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            uint256 reward = totalBeneficiaryReward *
                (totalBalance[beneficiary] / totalSupply);
            beneficiaryRewards[beneficiary] += reward;
        }
        emit RewardsAdded(_totalRewardAmount);
    }

    function sell(
        uint256 _totalSupply,
        uint256 _poolBalance,
        uint256 _tokens,
        uint256 _minETHReturned,
        uint256 _layerIndex
    ) internal marketInitialized nonReentrant returns (bool) {
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
        poolBalance -= ethReturned;
        layers[_layerIndex].amountStakedByCurator[msg.sender] -= _tokens;
        totalSupply -= _tokens;
        totalBalance[msg.sender] -= _tokens;
        sendValue(msg.sender, ethReturned);
        emit Sell(msg.sender, poolBalance, totalSupply, _tokens, ethReturned);
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
        marketInitialized
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
        newLayer.layerCreator = msg.sender;
        newLayer.stakedTokens += tokensReturned;
        newLayer.amountStakedByCurator[msg.sender] += tokensReturned;
        addressToLayerIndex[msg.sender].push(layerIndex);
        layerIndex++;
        emit LayerAdded(msg.sender, _contentURI, layerIndex, tokensReturned);
        return true;
    }

    function addStake(uint256 _layerIndex, uint256 _minTokensToStake)
        public
        payable
        marketInitialized
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
        emit Staked(msg.sender, _layerIndex, tokensReturned);
        return true;
    }

    function removeStake(
        uint256 _layerIndex,
        uint256 _amountToRemove,
        uint256 _minETHReturned
    ) internal marketInitialized returns (bool) {
        sell(
            totalSupply,
            poolBalance,
            _amountToRemove,
            _minETHReturned,
            _layerIndex
        );
        emit Removed(msg.sender, _layerIndex, _amountToRemove);
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

    function claimBeneficiaryReward(address _beneficiary)
        public
        marketInitialized
        nonReentrant
        returns (bool)
    {
        require(addressIsBeneficiary[_beneficiary]);
        sendValue(_beneficiary, beneficiaryRewards[_beneficiary]);
        emit BeneficiaryClaimed(_beneficiary);
        return true;
    }

    function claimCreatorReward(address _creator)
        public
        marketInitialized
        nonReentrant
        returns (bool)
    {
        require(creator == _creator);
        sendValue(_creator, creatorReward);
        emit CreatorClaimed(_creator);
        return true;
    }

    // ============ Utility ============

    function sendValue(address recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}
