// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./utils.sol";
import "./nft_generator.sol";

contract Crowdfunding {
    CertificateNFT private certificateNFT;

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
        uint256 donativeDate;
    }

    // stiore the campaigs
    mapping(bytes32 => Campaign) private campaigns;
    bytes32[] private campaignsIDs;

    // store the owner campaigns IDs
    mapping(address => bytes32[]) private ownerCampaigns;

    // store the donatives history for a campaign campaignId - Donative
    mapping(bytes32 => Donative[]) private donatives;

    // events
    event CampaignCreatedEvent(
        bytes32 id,
        string _title,
        string _description,
        uint256 _expectedAmount,
        address _campaignOwner);

    event CampaignUpdatedEvent();
    
    event DonativeAddedEvent(
        bytes32 campaignId,
        address donner,
        uint256 quantity,
        uint256 donativeDate);

    
    
    event CampaignReviewEvent(
         bytes32 id,
         uint256 paymentDate,
         uint256 expectedAmount,
         uint256 amount,
        address campaignOwner);

    
    
    
    event CampaignCompletedEvent(
        bytes32 campaignId,
        uint256 compledDate);
    
    event CaimpaignDonativeRefund(
        bytes32 id,
        address donner,
        uint256 quantity,
        uint256 refoundDate
    );
    
    
    // constructor
    constructor(address _certificateNFTs) {
        fee = 3;
        platformOwner = msg.sender;
        certificateNFT = CertificateNFT(_certificateNFTs);
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

        emit CampaignCreatedEvent(cId, _title, _description, _expectedAmount, msg.sender);
    }

    function addDonative(bytes32 campaignId) public payable {
        require(msg.value > 0, "Incorrect donative");
        require(msg.value <= msg.sender.balance, "Insufficient balance for donation");
        require(campaignId != bytes32(0), "Campaign ID cannot be zero");

        Campaign storage campaignInf = campaigns[campaignId];
        
        require(!campaignInf.completed, "Campaign already reach the expected amount");
        require(campaignInf.Id != bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Invalid ID");

        uint256 donativeDate = block.timestamp;
        donatives[campaignId].push(Donative(
            msg.sender,
            msg.value,
            donativeDate
        ));
        
        campaignInf.amount += msg.value;

        if (campaignInf.amount >= campaignInf.expectedAmount) {
            campaignInf.completed = true;
            
            emit CampaignCompletedEvent(
                campaignInf.Id,
                donativeDate);
        }

        emit DonativeAddedEvent(
            campaignInf.Id,
            msg.sender,
            msg.value,
            donativeDate);
    }

    function reviewCampaignsJob() public onlyOwner{
        uint256 currentDate = block.timestamp;

        for (uint256 i = 0; i < campaignsIDs.length; i++) {
            Campaign storage campaignInf = campaigns[campaignsIDs[i]];
            if (currentDate >= campaignInf.endDate || 
                campaignInf.amount >= campaignInf.expectedAmount) {
                campaignInf.isActive = false;
                // Calculate the fee amount
                uint256 feeAmount = (campaignInf.amount * fee) / 100;
                // Deduct the fee from the campaign amount
                uint256 netAmount = campaignInf.amount - feeAmount;
                // send payment to the campaign owner
                payToCampaignOwner(netAmount, campaignInf.owner);
                // pay to platform owner
                payToPlatformOwner(feeAmount);
                // assign the certificates to thaks the donative
                generateDonativeCertificate(campaignInf.Id, campaignInf.title);

                emit CampaignReviewEvent(
                    campaignInf.Id,
                    block.timestamp,
                    campaignInf.expectedAmount,
                    campaignInf.amount,
                    campaignInf.owner);
            }

            if (currentDate >= campaignInf.endDate && campaignInf.amount < campaignInf.expectedAmount) {
                campaignInf.isActive = false;
                campaignInf.completed = true;
                //refund donatives
                Donative[] memory donativesList = donatives[campaignInf.Id];
                for (uint256 d = 0; d < donativesList.length; d++) {
                    refundDonatives(donativesList[d].donner, donativesList[d].quantity);
                    
                    emit CaimpaignDonativeRefund (
                        campaignInf.Id,
                        donativesList[d].donner,
                        donativesList[d].quantity,
                        block.timestamp
                    );
                }
            }
        }
    }

    function refundDonatives(address donner, uint256 donative) internal{
        address payable recipientPayable = payable(donner);
        (bool ss, ) = recipientPayable.call{value: donative}("");
        require(ss, "Transfer failed");
    }

    function payToCampaignOwner(uint256 netAmount, address campaignOwner) internal {
        (bool success, ) = campaignOwner.call{value: netAmount}("");
        require(success, "Transfer failed");
    }

    function payToPlatformOwner(uint256 feeAmount) internal {
            (bool success, ) = platformOwner.call{value: feeAmount}("");
            require(success, "Transfer failed");
    }

    function generateDonativeCertificate(bytes32 campaignId, string memory campaignTitle) internal {
            Donative[] memory donativesList = donatives[campaignId];
            for (uint256 d = 0; d < donativesList.length; d++) {
                string memory tokenURI = "some-value-here";

                uint256 tokenId = certificateNFT.mint(donativesList[d].donner, tokenURI);
                certificateNFT.setCertificates(donativesList[d].donner, tokenId, tokenURI, campaignTitle);
            }
    }

    function updateCampaign(
        bytes32 campaignId, 
        string memory _title,
        string memory _description,
        uint256 _expectedAmount) public {
        
        require(campaignId != bytes32(0), "Campaign ID cannot be zero");

        Campaign storage campaignRecord = campaigns[campaignId];

        require(campaignRecord.Id != bytes32(0x0000000000000000000000000000000000000000000000000000000000000000), "Invalid ID");
        
        require(campaignRecord.owner == msg.sender, "Invalid owner to update the campaign");
        require(!campaignRecord.completed, "Campaign already reach the expected amount");
        require(campaignRecord.isActive, "Campaign is inactive");
        require(bytes(_title).length != 0, "title can not be empty");
        require(bytes(_description).length != 0, "description can not be empty");
        require(_expectedAmount > 0, "amount can not be negative");
        require(_expectedAmount > campaignRecord.amount, "Expected amount can not be less than the current ammount");

        campaignRecord.title = _title;
        campaignRecord.description = _description;
        campaignRecord.expectedAmount = _expectedAmount;
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



