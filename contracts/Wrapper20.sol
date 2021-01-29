// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IWrappable1155.sol";

contract Wrapper20 is IERC20 {
    using SafeMath for uint256;

    IWrappable1155 public immutable wrappable;
    uint256 public immutable id;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 id_) public {
        wrappable = IWrappable1155(msg.sender);
        id = id_;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _setAllowance(msg.sender, spender, amount);
        return true;
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
        return wrappable.totalSupply(id);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _setAllowance(
            sender,
            recipient,
            _allowances[sender][recipient].sub(
                amount,
                "ERC20: insufficient allowance"
            )
        );
        return true;
    }

    function _setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        wrappable.sudoTransferFrom(msg.sender, sender, recipient, id, amount);
        emit Transfer(sender, recipient, amount);
    }
}
