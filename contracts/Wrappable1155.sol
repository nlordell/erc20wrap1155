// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./vendored/ERC1155.sol";
import "./IWrappable1155.sol";
import "./Wrapper20.sol";

contract Wrappable1155 is ERC1155, IWrappable1155 {
    using Address for address;
    using ERC165Checker for address;
    using SafeMath for uint256;

    bytes32 private constant SALT =
        hex"baadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0de";
    bytes4 private constant ERC1155_TOKEN_RECEIVER_INTERFACE = hex"4e2312e0";

    mapping(uint256 => uint256) public override totalSupply;

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
            type(Wrapper20).creationCode,
            abi.encode(id)
        );
        bytes32 c2hash =
            keccak256(
                abi.encodePacked(hex"ff", this, SALT, keccak256(bytecode))
            );
        wrapper = address(uint256(c2hash));
    }

    function sudoTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external override isWrapper(id) {
        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        if (to.supportsInterface(ERC1155_TOKEN_RECEIVER_INTERFACE)) {
            _doSafeTransferAcceptanceCheck(
                operator,
                from,
                to,
                id,
                amount,
                hex""
            );
        }

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                totalSupply[ids[i]] += amounts[i];
            }
        }
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    modifier isWrapper(uint256 id) {
        (, address wrapper) = encodeWrapperBytecode(id);
        require(msg.sender == wrapper, "ERC1155: wrapper only");
        _;
    }
}
