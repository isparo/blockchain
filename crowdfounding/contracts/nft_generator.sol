// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CertificateNFT is ERC721URIStorage {
    address public platformOwner;
    string public cerificateContract = 'cerificateContract';
    uint256 private tokenCount = 0;

    struct Certificates {
        uint256 tokenID;
        string tokenURI;
        string description;
    }

    mapping(address => Certificates[]) private donersTokens;

    event CertificateMintedEvent();
    event CertificateInfoSetEvent();
    
    constructor() ERC721("Donative certificate", "DAPP") {
        platformOwner = msg.sender;
    }

     modifier onlyOwner() {
        require(msg.sender == platformOwner);
        _;
    }

    //onlyOwner
    //ipfs hash used as a tokenURI
    function mint(address donner, string memory tokenURI) public returns (uint256) {
        tokenCount++;
        uint256 tokenId = tokenCount;
        _safeMint(donner, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    function setCertificates(
        address donner,
        uint256 _tokenID,
        string memory _tokenURI,
        string memory _description) public {
        
        Certificates memory cert = Certificates(
            _tokenID,
            _tokenURI,
            _description
        );

        donersTokens[donner].push(cert);
    }

    function getTokensCount() public view returns (uint256) {
        return tokenCount;
    }

    function getMyNFTCertificates(address certificateOwner) public view returns(Certificates[] memory) {
        return donersTokens[certificateOwner];
    }

}