// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IMinWrappable1155.sol";

contract MinWrapper20 is IERC20 {
    IMinWrappable1155 public immutable wrappable;
    uint256 public immutable id;

    constructor(uint256 id_) public {
        wrappable = IMinWrappable1155(msg.sender);
        id = id_;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256 amount)
    {
        bool approved = wrappable.isApprovedForAll(owner, spender);
        if (approved) {
            amount = uint256(-1);
        }
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        // TODO(nlordell): This can be implemented by keeping `allowances`
        // separate from `approvals`. With this separate state, `transferFrom`
        // can be relatively trivially implemented such that:
        // - if the `operator` is the sender or is ERC1155 approved, the amount
        // is transferred like an ERC20 `transfer`
        // - otherwise the amount is tranferred like an ERC20 `transferFrom`,
        // that is, the amount is deducted from the allowance.
        revert("W: not implemented");
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return wrappable.balanceOf(account, id);
    }

    function totalSupply() external view override returns (uint256) {
        // TODO(nlordell): This can be relatively trivially be implemented by
        // keeping track of the total supply in the ERC1155 contract.
        revert("W: not implemented");
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        wrappable.wrapTransferFrom(msg.sender, sender, recipient, id, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
}
