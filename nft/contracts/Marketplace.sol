// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard {

    address payable public immutable feeAccount; // the account that receives fees
    uint public immutable feePercent = 3; // the fee percentage on sales 
    uint public itemCount;

    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    mapping(uint => Item) public items;

    event Offered(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );

    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    // establece el fee percentage desde que se deplega el contrato
    // uint _feePercent
    constructor() {
        feeAccount = payable(msg.sender);
        //feePercent = 3;//_feePercent;
    }

    function makeItem(IERC721 _nft, uint _tokenId, uint _price) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");

        //increment the item count
        itemCount++;

        // transfer nft
        _nft.transferFrom(msg.sender, address(this), _tokenId);

        // add the item to items mapping(list)
        items[itemCount] = Item (
            itemCount,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );

        // emit the event
        emit Offered(
            itemCount,
            address(_nft),
            _tokenId,
            _price,
            msg.sender
        );
    }


    function purchaseItem(uint _itemId) external payable nonReentrant {
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];

        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        require(msg.value >= _totalPrice, "not enough ether to cover item price and market fee");
        require(!item.sold, "item already sold");

        // pay seller and feeAccount
        item.seller.transfer(item.price);
        feeAccount.transfer(_totalPrice - item.price);

        // update item to sold
        item.sold = true;

        // transfer nft to buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);

        // emit bought event
        emit Bought(_itemId, address(item.nft), item.tokenId, item.price, item.seller, msg.sender);
    }

    function listMyTokens() external view returns (Item[] memory) {
        uint totalTokens = itemCount;
        
        uint totalSoldTokens = 0;
        for (uint i = 1; i <= totalTokens; i++) {
            if (items[i].sold 
                && (items[i].nft.ownerOf(items[i].tokenId) == msg.sender)) {
                totalSoldTokens++;
            }
        }

        if (totalSoldTokens == 0) {
            return new Item[](0);
        }
        
        Item[] memory allTokens = new Item[](totalSoldTokens);
        uint index = 0;
        for (uint i = 1; i <= totalTokens; i++) {
            if (items[i].sold 
                && (items[i].nft.ownerOf(items[i].tokenId) == msg.sender)) {
                allTokens[index] = items[i];
                index++;
            }
        }

        return allTokens;
    }

    function soldMyToken(uint _itemId, uint _price, IERC721 _nft)  external nonReentrant {
        require(_price > 0, "Price must be greater than zero");
        require(items[_itemId].itemId > 0, "Item should exist");

        // validate, the token owner is the same person that is executing the contract
         address tokenOwner = _nft.ownerOf(items[_itemId].tokenId);
         require(tokenOwner == msg.sender, "You are not the owner");

         Item storage item = items[_itemId];
         item.seller = payable(msg.sender);
         item.sold = false;
         item.price = _price;

         // transfer nft
        _nft.transferFrom(msg.sender, address(this), item.tokenId);

         // emit the event
        emit Offered(
            item.itemId,
            address(_nft),
            item.tokenId,
            _price,
            msg.sender
        );
    }

    function getTotalPrice(uint _itemId) view public returns(uint){
        return((items[_itemId].price*(100 + feePercent))/100);
    }
}