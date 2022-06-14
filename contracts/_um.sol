// SPDX-License-Identifier: MIT


pragma solidity ^0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract _um is ERC721, Ownable {

    string private _contractURI                     = "";
    uint256 public totalSupply                      = 0;
    uint256 public mintCost                         = 0.004 ether;
    uint256 constant public RAISE_MINT_COST_BPS     = 200;

    struct Collection {
        string name;
        string baseURI;
        uint256 supply;
    }

    Collection[] public collect ;

    constructor() ERC721("_undefined mutables", "_UM") {
        transferOwnership(msg.sender);
    }

    // _um collection metadata for marketplaces
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // change collection metadata
    function setContractURI(string memory _uri) onlyOwner public {
        _contractURI = _uri;
    }

    // pick a pseudorandom URI for a given token
    // then return a random tokenId for that collection
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        // add 2 to avoid multiplication by 0 or 1 with those token ids
        uint256 _pseudorando = block.timestamp * (tokenId + 2);
        
        // get a random collection
        string memory _currentURI = collect[_pseudorando % collect.length].baseURI;

        // get a random tokenid, checking against max supply for that collection
        uint256 _id = _pseudorando % collect[_pseudorando % collect.length].supply;

        return bytes(_currentURI).length > 0 ? string(abi.encodePacked(_currentURI, Strings.toString(_id))) : "";
    }

    // onlyOwner functions
    // in the future, ownership could be transferred to a contract
    // to open up permissionless collection management

    // add any collection, specifying baseURI and totalSupply
    function addCollection(string memory _name, string memory _uri, uint256 _supply) onlyOwner public {

        Collection memory addedCollection = Collection(_name, _uri, _supply);
        collect.push(addedCollection);
    }

    // change baseURI or totalSupply for an existing collection
    function changeCollection(uint256 _id, string memory _uri, uint256 _supply) onlyOwner public {

        Collection memory changedCollection = Collection(collect[_id].name, _uri, _supply);
        collect[_id] = changedCollection;
    }

    // remove a collection from the list
    function removeCollection(uint256 _id) onlyOwner public {

        collect[_id] = collect[collect.length - 1];
        collect.pop();
    }
    
    // minting is technically infinite but pragmatically capped by proportional cost growth 

    function mint(address _recipient) public payable {
        require(msg.value >= mintCost, "UM: not enough eth to mint");

        payable(owner()).transfer(mintCost);
        mintCost += mintCost * RAISE_MINT_COST_BPS / 10000;

        _safeMint(_recipient, totalSupply);
        totalSupply++;

        // send extra eth back if any
        if(msg.value > mintCost){
            uint256 _remainder = msg.value - mintCost;
            payable(msg.sender).transfer(_remainder);
        }
    }

}