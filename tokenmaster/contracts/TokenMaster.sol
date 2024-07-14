// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TokenMaster is ERC721 {
    address public owner;
    //uint256 public totalOccasions;
    uint256 public totalSupply;

    struct Occasion {
        bytes32 id;
        string name;
        uint256 cost;
        uint256 tickets;
        uint256 maxTickets;
        string date;
        string time;
        string location;
    }

    // occasions, defines as key bytes32, that is the id of the occasion and is used askey to find it
    mapping(bytes32 => Occasion) occasions;
    bytes32[] private occasionsIds;

    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(uint256 => mapping(uint256 => address)) public seatTaken;
    mapping(uint256 => uint256[]) seatsTaken;

    // Event to Occasions added
    event OccasionAdded(bytes32 id, string name, uint256 cost, uint256 maxTickets);
    // Event for Ticket bought
    event TicketBought(bytes32 occasionId, uint256 cost, uint256 tickets);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() ERC721("TokenMaster", "TM"){
        owner = msg.sender;
    }

    function list(
        string memory _name,
        uint256 _cost,
        uint256 _maxTickets,
        string memory _date,
        string memory _time,
        string memory _location
    ) public onlyOwner {
        bytes32 occasionId = generateUniqueID();

       Occasion memory occ = Occasion (
            occasionId,
            _name,
            _cost,
            _maxTickets,
            _maxTickets,
            _date,
            _time,
            _location
        );

        occasions[occasionId] = occ;
        occasionsIds.push(occasionId);

        emit OccasionAdded(occasionId, _name, _cost, _maxTickets);
    }

    function getOccasion(bytes32 _id) public view returns (Occasion memory) {
        return occasions[_id];
    }

    function getAllOccasions() public view returns (Occasion[] memory) {
        Occasion[] memory allOccasions;

        allOccasions = new Occasion[](occasionsIds.length);
        for(uint256 i = 0; i < occasionsIds.length; i++) {
            allOccasions[i] = occasions[occasionsIds[i]];
        }

        return allOccasions;
    }

    
    function generateUniqueID() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao));
    }
}
