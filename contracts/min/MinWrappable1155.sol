// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../vendored/ERC1155.sol";
import "./IMinWrappable1155.sol";
import "./MinWrapper20.sol";

contract MinWrappable1155 is ERC1155, IMinWrappable1155 {
    using Address for address;
    using SafeMath for uint256;

    bytes32 private constant SALT =
        hex"baadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0de";

    constructor(uint256 id, uint256 amount)
        ERC1155("https://github.com/nlordell/erc20wrap1155")
    {
        _mint(msg.sender, id, amount, hex"");
    }

    function deployWrapper(uint256 id) external returns (address wrapper) {
        bytes memory bytecode;
        (bytecode, wrapper) = encodeWrapperBytecode(id);
        require(!wrapper.isContract(), "W: wrapper exists");

        address wrapper_;
        assembly {
            wrapper_ := create2(0, add(bytecode, 32), mload(bytecode), SALT)
        }
        require(wrapper == wrapper_, "W: bad code");
    }

    function getWrapper(uint256 id) external view returns (address wrapper) {
        (, wrapper) = encodeWrapperBytecode(id);
    }

    function encodeWrapperBytecode(uint256 id)
        private
        view
        returns (bytes memory bytecode, address wrapper)
    {
        bytecode = abi.encodePacked(
            type(MinWrapper20).creationCode,
            abi.encode(id)
        );
        bytes32 c2hash =
            keccak256(
                abi.encodePacked(hex"ff", this, SALT, keccak256(bytecode))
            );
        wrapper = address(uint256(c2hash));
    }

    function wrapTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external override {
        requireIsWrapper(id);
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC20: not approved"
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        // TODO(nlordell): Implement "hybrid ERC1155" rules for transferring:
        // <https://eips.ethereum.org/EIPS/eip-1155#backwards-compatibility>

        emit TransferSingle(operator, from, to, id, amount);
    }

    function requireIsWrapper(uint256 id) private {
        (, address wrapper) = encodeWrapperBytecode(id);
        require(msg.sender == wrapper, "W: wrapper only method");
    }
}
