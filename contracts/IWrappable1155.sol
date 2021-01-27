// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IWrappable1155 is IERC1155 {
    function wrapTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;
}
