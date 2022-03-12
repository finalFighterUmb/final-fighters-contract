// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FinalFighters is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint public cost = 0.05 ether;
    uint constant maxSupply = 10000;
    uint public maxMintAmount = 7;
    uint public nftPerAddressLimit = 7;
    bool public paused = false;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory name, string memory symbol, string memory initBaseURI) ERC721(name, symbol) {
        setBaseURI(initBaseURI);
    }

    // public
    function mint(uint mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(mintAmount > 0, "need to mint at least 1 NFT");
        require(mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(totalSupply() + mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if(onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                //TODO: Should limit only apply to whitelisted or no?? maybe to everyone except admin ??
                require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            }
            require(msg.value >= cost * mintAmount, "insufficient funds");
        }

        for (uint i = 1; i <= mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    //TODO: Is this method really required ? Seems it has alternatives inherited from ERC721
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory tokenIds = new uint[](ownerTokenCount);
        for (uint i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(_baseURI()).length > 0 ?
            string(abi.encodePacked(_baseURI(), tokenId.toString(), baseExtension)) :
            "";
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdrawAll() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdraw(uint8 percentage) public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance * percentage / 100}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
