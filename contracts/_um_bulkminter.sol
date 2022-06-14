// SPDX-License-Identifier: MIT

// bulk minter for _um

pragma solidity ^0.8.14;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface _um {
    function mint(address _recipient) external payable;
    function mintCost() external view returns(uint256);
}

contract _um_bulkminter {

    // _um.sol contract
    address immutable public UM;

    constructor(address _adr) {
        UM = _adr;
    }

    //** VIEW **//
    function cost() public view returns(uint256) {
        return _um(UM).mintCost();
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
        )pure external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    //** BULK MINT **//
    // _amount number of mutables to mint at once
    // msg.value should be at least the sum of the series
    // any extra ETH is refunded
    // for simplicity, use _amount * cost() * 2
    function mintMany(uint256 _amount) payable public {

        uint256 _balance = msg.value;
        uint256 i = 0;

        // loop until we reach _amount or run out of money
        do {
            uint256 _value = cost(); // cost increases with each mint
            _balance -= _value;
            _um(UM).mint{value:_value}(msg.sender);
            i++;
        }
        while (i < _amount && _balance >= cost());

        // transfer remaining ether if any
        if(_balance > 0) {
            uint256 _remainder = _balance;
            _balance = 0;
            payable(msg.sender).transfer(_remainder);
        }
    }
}