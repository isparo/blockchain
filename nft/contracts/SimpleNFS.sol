// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//ERC721,ERC721Enumerable,Ownable
/* */
contract SimpleNFS is 
	ERC721URIStorage
{
    uint public tokenCount;
    string public dAppName = 'SimpleNFS';

   constructor() ERC721("DApp NFT", "DAPP"){}
    
    // after add address to, to catch the adrees as parameter
    function mint(string memory _tokenURI) external returns(uint) {
        tokenCount ++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        return(tokenCount);
    }
}