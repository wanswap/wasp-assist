// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

interface WaspHive {
    function poolLength() external view returns (uint256);
    function pendingwanWan(uint256 _pid, address _user) external view returns (uint256,uint256);
}

interface WanswapPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface WaspFarm {
    function userInfo(uint, address) external view returns (uint256, uint256);
    function poolLength() external view returns (uint256);
    function pendingWasp(uint256 _pid, address _user) external view returns (uint256);
}

contract WaspAssist is Initializable, AccessControlUpgradeable {
    address public waspToken;
    address public waspHive;
    address public waspPair;
    address public waspFarm;
    address public zooFarm;

    function balanceOf(address user) external view returns (uint256) {
        return getTotalWasp(user);
    }

    function initialize() initializer public {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getHiveWasp(address user) public view returns (uint) {
        uint totalStake = 0;
        uint poolLength = WaspHive(waspHive).poolLength();
        uint i;
        uint amount;
        for (i=0; i<poolLength; i++) {
            (amount,) = WaspHive(waspHive).pendingwanWan(i, user);
            totalStake += (amount);
        }
        return totalStake;
    }

    function getPoolWasp(address user) public view returns (uint) {
        uint totalStake;
        uint lpBalance = IERC20(waspPair).balanceOf(user);
        if (lpBalance == 0) {
            return 0;
        }
        uint lpTotal = IERC20(waspPair).totalSupply();
        uint reserve0;
        (reserve0, , ) = WanswapPair(waspPair).getReserves();
        totalStake += (lpBalance * reserve0 / lpTotal);
        return totalStake;
    }
    // 6, 16, 19, 23
    function getFarmingWasp(address user, uint256 _pid, bool isReserve0) public view returns (uint) {
        uint totalStake;
        uint amount;
        (amount,) = WaspFarm(waspFarm).userInfo(_pid, user);
        if (amount > 0) {
            uint lpBalance = amount;
            uint lpTotal = IERC20(waspPair).totalSupply();
            uint reserve0;
            uint reserve1;
            (reserve0, reserve1, ) = WanswapPair(waspPair).getReserves();
            if (isReserve0) {
                totalStake += (lpBalance * reserve0 / lpTotal);
            } else {
                totalStake += (lpBalance * reserve1 / lpTotal);
            }
        }
        uint pending = WaspFarm(waspFarm).pendingWasp(_pid, user);
        totalStake += (pending);
        return totalStake;
    }

    function getZooKeeperFarmingWasp(address user, uint256 _pid, bool isReserve0) public view returns (uint) {
        uint totalStake;
        uint amount;
        (amount,) = WaspFarm(zooFarm).userInfo(_pid, user);
        if (amount > 0) {
            uint lpBalance = amount;
            uint lpTotal = IERC20(waspPair).totalSupply();
            uint reserve0;
            uint reserve1;
            (reserve0, reserve1, ) = WanswapPair(waspPair).getReserves();
            if (isReserve0) {
                totalStake += (lpBalance * reserve0 / lpTotal);
            } else {
                totalStake += (lpBalance * reserve1 / lpTotal);
            }
        }
        uint pending = WaspFarm(zooFarm).pendingWasp(_pid, user);
        totalStake += (pending);
        return totalStake;
    }

    function getTotalWasp(address user) public view returns (uint) {
        uint totalStake = 0;

        // BALANCE
        totalStake += (IERC20(waspToken).balanceOf(user));

        // HIVE
        totalStake += (getHiveWasp(user));

        // POOL
        // totalStake += (getPoolWasp(user));

        // FARMING
        totalStake += (getFarmingWasp(user, 6, true));
        totalStake += (getFarmingWasp(user, 16, false));
        totalStake += (getFarmingWasp(user, 19, false));
        totalStake += (getFarmingWasp(user, 23, false));

        // ZOO
        totalStake += (getZooKeeperFarmingWasp(user, 0, true));
        totalStake += (getZooKeeperFarmingWasp(user, 7, false));

        return totalStake;
    }

    function config(address _waspToken, address _waspHive, address _waspPair, address _waspFarm, address _zooFarm) public onlyRole(DEFAULT_ADMIN_ROLE) {
        waspToken = _waspToken;
        waspHive = _waspHive;
        waspPair = _waspPair;
        waspFarm = _waspFarm;
        zooFarm = _zooFarm;
    }
}
