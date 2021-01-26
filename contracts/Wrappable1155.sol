// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Wrapper20.sol";

contract Wrappable1155 is ERC1155 {
    using Address for address;

    bytes32 private constant SALT =
        hex"baadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0debaadc0de";

    constructor() ERC1155("https://github.com/nlordell/erc20wrap1155") {}

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
}
