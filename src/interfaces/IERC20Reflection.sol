// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Reflection is IERC20 {
    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) external view returns (uint256);

    function tokenFromReflection(
        uint256 rAmount
    ) external view returns (uint256);
}
