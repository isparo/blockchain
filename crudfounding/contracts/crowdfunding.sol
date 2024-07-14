// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils.sol";

contract Crowdfunding {
    address public platformOwner;
    uint256 private fee;

    using Utils for *;
    
    struct Campaign {
        bytes32 Id;
        string title;
        string description;
        uint256 expectedAmount;
        uint256 amount;
        address owner;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
        bool completed;
    }

    struct Donative {
        address donner;
        uint256 quantity;
        uint256 endDate;
    }

    // stiore the campaigs
    mapping(bytes32 => Campaign) private campaigns;
    bytes32[] private campaignsIDs;

    // store the owner campaigns IDs
    mapping(address => bytes32[]) private ownerCampaigns;

    // store the donatives history for a campaign campaignId - Donative
    mapping(bytes32 => Donative[]) private donatives;

    constructor() {
        fee = 3;
        platformOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == platformOwner);
        _;
    }

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _expectedAmount
    ) public {
        require(bytes(_title).length != 0, "title can not be empty");
        require(bytes(_description).length != 0, "description can not be empty");
        require(_expectedAmount > 0, "amount can not be negative");

        bytes32 cId = Utils.generateUniqueID();
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + 30 days; // One month from now

        Campaign memory campaign =  Campaign(
            cId,
            _title,
            _description,
            _expectedAmount,
            0,
            msg.sender,
            startDate,
            endDate,
            true,
            false
        );

        campaigns[cId] = campaign;
        ownerCampaigns[msg.sender].push(cId);
        campaignsIDs.push(cId);
    }

    function addDonative(bytes32 campaignId) public payable {
        require(msg.value > 0, "Incorrect donative");
        require(campaignId != bytes32(0), "Campaign ID cannot be zero");
        require(!campaigns[campaignId].completed, "Campaign already reach the expected amount");
        require(campaigns[campaignId].Id != bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Invalid ID");

        Donative memory donative = Donative(
            msg.sender,
            msg.value,
            block.timestamp
        );

        donatives[campaignId].push(donative);
        
        Campaign storage campaignInf = campaigns[campaignId];
        campaignInf.amount += msg.value;

        if (campaignInf.amount >= campaignInf.expectedAmount) {
            campaignInf.completed = true;
        }
    }

    function reviewCampaignsJob() public onlyOwner{
        uint256 currentDate = block.timestamp;

        for (uint256 i = 0; i < campaignsIDs.length; i++) {
            Campaign storage campaignInf = campaigns[campaignsIDs[i]];

            if (currentDate >= campaignInf.endDate || 
                campaignInf.amount >= campaignInf.expectedAmount) {

                campaignInf.isActive = false;

                (bool success, ) = campaignInf.owner.call{value: campaignInf.amount}("");
                require(success, "Transfer failed");
            }

        }
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory activeCampaigns = new Campaign[](campaignsIDs.length);

        for (uint256 i = 0; i < campaignsIDs.length; i++) {
            activeCampaigns[i]= campaigns[campaignsIDs[i]];
        }

        return activeCampaigns;
    }

    function getDonatives(bytes32 campaignId) public view returns (Donative[] memory) {
        Campaign memory campaignInf = campaigns[campaignId];
        require(campaignInf.Id != bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Invalid ID");
        
        return donatives[campaignId];
    }

    function getCampaignInfo(bytes32 campaignId) public view returns (Campaign memory) {
        Campaign memory campaignInf = campaigns[campaignId];
        require(campaignInf.Id != bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Invalid ID");
        
        return campaignInf;
    }

}



