// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ActionBase} from "dataverse-contracts-test/contracts/monetizer/base/ActionBase.sol";
import {IActionConfig} from "dataverse-contracts-test/contracts/monetizer/interfaces/IActionConfig.sol";
import {IDataMonetizer} from "dataverse-contracts-test/contracts/monetizer/interfaces/IDataMonetizer.sol";
import {ShareToken} from "./token/ShareToken.sol";
import {IShareSetting} from "./setting/IShareSetting.sol";

contract ShareAction is ActionBase {
    using SafeERC20 for IERC20;

    enum TradeType {
        Buy,
        Sell
    }

    struct ShareData {
        address shareToken;
        uint256 totalValue;
        uint256 totalSupply;
        address currency;
        uint256 feePoint;
        address setting;
    }

    error InvalidShareSetting();

    mapping(bytes32 => ShareData) internal _assetShareData;

    constructor(address actionConfig, address monetizer) ActionBase(actionConfig, monetizer) {}

    function initializeAction(bytes32 assetId, bytes calldata data) external monetizerRestricted {
        (
            address publisher,
            string memory name,
            string memory symbol,
            address currency,
            uint256 feePoint,
            uint256 initialSupply,
            address setting
        ) = abi.decode(data, (address, string, string, address, uint256, uint256, address));
        ShareToken shareToken = new ShareToken(name, symbol);
        _assetShareData[assetId].currency = currency;
        _assetShareData[assetId].feePoint = feePoint;
        _assetShareData[assetId].shareToken = address(shareToken);

        shareToken.mint(publisher, initialSupply);
        _assetShareData[assetId].totalSupply = initialSupply;

        if (!IERC165(setting).supportsInterface(type(IShareSetting).interfaceId)) {
            revert InvalidShareSetting();
        }
        _assetShareData[assetId].setting = setting;
    }

    function processAction(bytes32 assetId, address trader, bytes calldata data)
        external
        monetizerRestricted
        returns (bytes memory)
    {
        (TradeType tradeType, uint256 amount) = abi.decode(data, (TradeType, uint256));
        if (tradeType == TradeType.Buy) {
            _buyShare(assetId, trader, amount);
        }
        if (tradeType == TradeType.Sell) {
            _sellShare(assetId, trader, amount);
        }
        return data;
    }

    function isAccessible(bytes32 assetId, address account) external view returns (bool) {
        return IShareSetting(_assetShareData[assetId].setting).isAccessible(assetId, account);
    }

    function _buyShare(bytes32 assetId, address trader, uint256 amount) internal {
        uint256 price = getBuyPrice(assetId, amount);
        uint256 ownerFeeAmount = (price * _assetShareData[assetId].feePoint) / BASE_FEE_POINT;

        uint256 dappFeeAmount = _payDappFee(assetId, trader, _assetShareData[assetId].currency, price);

        uint256 dataverseFeeAmount = _payDataverseFee(trader, _assetShareData[assetId].currency, price);

        IERC20(_assetShareData[assetId].currency).safeTransferFrom(trader, _assetOwner(assetId), ownerFeeAmount);
        IERC20(_assetShareData[assetId].currency).safeTransferFrom(
            trader, address(this), price - dappFeeAmount - dataverseFeeAmount - ownerFeeAmount
        );

        ShareToken(_assetShareData[assetId].shareToken).mint(trader, amount);
        _assetShareData[assetId].totalSupply += amount;
        _assetShareData[assetId].totalValue += price;
    }

    function _sellShare(bytes32 assetId, address trader, uint256 amount) internal {
        uint256 price = getSellPrice(assetId, amount);
        uint256 ownerFeeAmount = (price * _assetShareData[assetId].feePoint) / BASE_FEE_POINT;
        uint256 dappFeeAmount = _payDappFee(assetId, trader, _assetShareData[assetId].currency, price);
        uint256 dataverseFeeAmount = _payDataverseFee(trader, _assetShareData[assetId].currency, price);
        IERC20(_assetShareData[assetId].currency).safeTransferFrom(trader, _assetOwner(assetId), ownerFeeAmount);
        IERC20(_assetShareData[assetId].currency).transfer(
            trader, price - dappFeeAmount - dataverseFeeAmount - ownerFeeAmount
        );

        ShareToken(_assetShareData[assetId].shareToken).burn(trader, amount);
        _assetShareData[assetId].totalSupply -= amount;
        _assetShareData[assetId].totalValue -= price;
    }

    function getBuyPrice(bytes32 assetId, uint256 amount) public view returns (uint256) {
        return IShareSetting(_assetShareData[assetId].setting).getPrice(_assetShareData[assetId].totalSupply, amount);
    }

    function getSellPrice(bytes32 assetId, uint256 amount) public view returns (uint256) {
        return IShareSetting(_assetShareData[assetId].setting).getPrice(
            _assetShareData[assetId].totalSupply - amount, amount
        );
    }

    function getAssetShareData(bytes32 assetId) external view returns (ShareData memory) {
        return _assetShareData[assetId];
    }

    function _payDataverseFee(address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = getDataverseTreasuryData();
        uint256 dataverseFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dataverseFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dataverseFeeAmount);
        }
        return dataverseFeeAmount;
    }

    function _payDappFee(bytes32 assetId, address payer, address currency, uint256 amount) internal returns (uint256) {
        (address treasury, uint256 feePoint) = getDappTreasuryData(assetId);
        uint256 dappFeeAmount = (amount * feePoint) / BASE_FEE_POINT;
        if (dappFeeAmount > 0) {
            IERC20(currency).safeTransferFrom(payer, treasury, dappFeeAmount);
        }
        return dappFeeAmount;
    }

    function _assetOwner(bytes32 assetId) internal returns (address) {
        return IDataMonetizer(monetizer).getAssetOwner(assetId);
    }
}
