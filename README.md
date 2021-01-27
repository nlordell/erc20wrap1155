# ERC20-Wrap-1155

Small proof of concept of what a minimal stateless ERC20 wrapper to an ERC1155
would look like.

The idea here is to use deterministic `CREATE2` addresses for the wrapper
contracts. This allows the ERC1155 implementation to handle ERC20 calls
(specifically `transfer(From)` which is **not** compatible with ERC1155 because
of the requirement that the receiver must implement the `ERC1155TokenReceiver`
interface if it has code).

## What's Next

Spending some time to make sure the implementation is sound (e.g. cannot be
exploited to drain funds) and how badly the ERC20/1155 specs are being ignored.

## Trying it out

Just install dependencies and run tests:
```
yarn && yarn test
```
