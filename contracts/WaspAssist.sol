// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


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

contract WaspAssist is Ownable {
    using SafeMath for uint256;

    address public waspToken;
    address public waspHive;
    address public waspPair;
    address public waspFarm;

    function getHiveWasp(address user) public view returns (uint) {
        uint totalStake = 0;
        uint poolLength = WaspHive(waspHive).poolLength();
        uint i;
        uint amount;
        uint pending;
        for (i=0; i<poolLength; i++) {
            (amount,) = WaspHive(waspHive).pendingwanWan(i, user);
            totalStake = totalStake.add(amount);
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
        totalStake = totalStake.add(lpBalance.mul(reserve0).div(lpTotal));
        return totalStake;
    }

    function getFarmingWasp(address user) public view returns (uint) {
        uint totalStake;
        uint amount;
        (amount,) = WaspFarm(waspFarm).userInfo(6, user);
        if (amount > 0) {
            uint lpBalance = amount;
            uint lpTotal = IERC20(waspPair).totalSupply();
            uint reserve0;
            (reserve0, , ) = WanswapPair(waspPair).getReserves();
            totalStake = totalStake.add(lpBalance.mul(reserve0).div(lpTotal));
        }
        uint pending = WaspFarm(waspFarm).pendingWasp(6, user);
        totalStake = totalStake.add(pending);
        return totalStake;
    }

    function getTotalWasp(address user) public view returns (uint) {
        uint totalStake = 0;

        // BALANCE
        totalStake = totalStake.add(IERC20(waspToken).balanceOf(user));

        // HIVE
        totalStake = totalStake.add(getHiveWasp(user));

        // POOL
        totalStake = totalStake.add(getPoolWasp(user));

        // FARMING
        totalStake = totalStake.add(getFarmingWasp(user));

        return totalStake;
    }

    function config(address _waspToken, address _waspHive, address _waspPair, address _waspFarm) public onlyOwner {
        waspToken = _waspToken;
        waspHive = _waspHive;
        waspPair = _waspPair;
        waspFarm = _waspFarm;
    }
}
