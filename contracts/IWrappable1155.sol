// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IWrappable1155 is IERC1155 {
    /// Returns the total supply for the token with the specified ID.
    function totalSupply(uint256 id) external view returns (uint256);

    /// Performs a trasfer returning whether or not the operator was approved.
    /// The caller **MUST** verify and update allowances in case the operator
    /// was not approved. This can only be called by the wrapper ERC20 token.
    function sudoTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}
