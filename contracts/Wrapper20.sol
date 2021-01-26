// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Wrapper20 is IERC20 {
    address public immutable WRAPPABLE;
    uint256 public immutable ID;

    constructor(uint256 id) public {
        WRAPPABLE = msg.sender;
        ID = id;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        revert("not implemented");
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        revert("not implemented");
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        revert("not implemented");
    }

    function totalSupply() external view override returns (uint256) {
        revert("not implemented");
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        revert("not implemented");
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        revert("not implemented");
    }
}
