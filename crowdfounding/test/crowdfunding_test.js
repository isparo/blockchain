const { expect } = require("chai"); 
const { ethers } = require('hardhat');

const toWei = (num) => ethers.parseEther(num.toString());
const fromWei = (num) => ethers.formatEther(num)

describe("Crowdfunding", () => {
    let crowdfunding;
    let certificateNFT;
    let deployer;
    let user;
    let doner;
    const initBalance = 0;

    beforeEach(async () => {
        // Setup accounts
        [deployer, user, doner] = await ethers.getSigners()

        //deploy nft contract
        const CertificateNFT = await ethers.getContractFactory("CertificateNFT");
        certificateNFT = await CertificateNFT.deploy();

        // Deploy contract
        const Crowdfunding = await ethers.getContractFactory("Crowdfunding")
        crowdfunding = await Crowdfunding.deploy(certificateNFT.target);
    });

    describe("Deployment", () => {
        it("validates the owner", async () => {
            expect(await crowdfunding.platformOwner()).to.equal(deployer.address)
        })

        it("defines zero valance", async () => {
            const balance = await ethers.provider.getBalance(crowdfunding.target);
            expect(balance).to.equal(initBalance);
        })
    });

    describe("Campaign", () => {
        it("should create new campaign", async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(25)
            );
            expect(transaction).to.emit(crowdfunding, "CampaignCreatedEvent");

            const receipt = await transaction.wait()
            const gasUsed = receipt.gasUsed;
            console.log("Gas used for transfer:", gasUsed);

            campaigns = await crowdfunding.connect(user).getAllCampaigns();
            expect(campaigns.length).to.equal(1)
            expect(campaigns[0].owner).to.equal(user.address);

            startDateNumber = ethers.toNumber(campaigns[0].startDate);
            const startDate = new Date(startDateNumber * 1000);

            endDateNumber = ethers.toNumber(campaigns[0].endDate);
            const endDate = new Date(endDateNumber * 1000);

            expect(startDate).to.be.lessThan(endDate);

            expect(campaigns[0].completed).to.equal(false);
        });

        it("should list the campaigns", async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(25),
                {gasLimit: 6721975}
            );
            await transaction.wait()

            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign 2",
                "test description 2",
                toWei(25),
                {gasLimit: 6721975}
            );
            await transaction.wait()

            campaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});
            expect(campaigns.length).to.equal(2);
        });

        it("should get the campaign information", async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(25)
            );
            await transaction.wait()
            campaigns = await crowdfunding.connect(user).getAllCampaigns();
            expect(campaigns.length).to.equal(1)
            campaign = await crowdfunding.connect(user).getCampaignInfo(campaigns[0].Id)
            expect(campaign.owner).to.equal(user.address);
            expect(campaign.owner).to.equal(campaigns[0].owner);
            expect(campaign.Id).to.equal(campaigns[0].Id);
        });

        it("should not create a campaign with invalid data", async () => {
            try {
                transaction = await crowdfunding.connect(user).createCampaign(
                    "",
                    "",
                    0
                );
                await transaction.wait()

                transaction = await crowdfunding.connect(user).createCampaign(
                    "value",
                    "",
                    0
                );
                await transaction.wait()
                transaction = await crowdfunding.connect(user).createCampaign(
                    "value",
                    "value",
                    0
                );
                await transaction.wait()
            } catch (error) {
                expect(error.message.includes("revert")).to.equal(true)
            }
        });

        it("returns empty campaigns list", async () => {
            campaigns = await crowdfunding.connect(user).getAllCampaigns();
            expect(campaigns.length).to.equal(0);
        });

        it("returns empty campaign info", async () => {
            try {
                campaign = await crowdfunding.connect(user).getCampaignInfo("0xc703ecc3dd6710b9e9d219682dd1394e19ccaf25674e2196b02a60194c0f4c0b");
            } catch(error) {
                expect(error.message.includes("Invalid ID")).to.equal(true)
            }
            
        });

        it("should update the campaign information", async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(4)
            );
            await transaction.wait()

            campaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});
            let campaign = campaigns[0];

            donationAmount = toWei(3);
            await crowdfunding.connect(doner).addDonative(campaign.Id, { value: donationAmount, gasLimit: 6721975 });

            await crowdfunding.connect(user).updateCampaign(
                campaign.Id, 
                "edited title",
                "edited description",
                toWei(5), {gasLimit: 6721975});
            
            updatedCampaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});
            let updatedCampaign = updatedCampaigns[0];

            expect(updatedCampaign.title).to.equal("edited title");
            expect(updatedCampaign.description).to.equal("edited description");
            expect(updatedCampaign.expectedAmount).to.equal(toWei(5));
        })
    });

    describe("Donatives", () => {
        let campaigns;
        let campaignID;

        beforeEach(async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(25)
            );
            await transaction.wait()

            campaigns = await crowdfunding.connect(user).getAllCampaigns();
            expect(campaigns.length).to.equal(1)
            expect(campaigns[0].owner).to.equal(user.address);
            campaignID = campaigns[0].Id;
        });

        it("should add a donative", async () => {
            const donationAmount = toWei(2);

            const balanceBefore = await ethers.provider.getBalance(crowdfunding.target);
            expect(balanceBefore).to.equal(toWei(0));

            const donorBalanceBefore = await ethers.provider.getBalance(doner.address);
            
            await crowdfunding.connect(doner).addDonative(campaignID, { value: donationAmount, gasLimit: 6721975 });
            
            const balanceAfter = await ethers.provider.getBalance(crowdfunding.target);
            expect(balanceAfter).to.equal(donationAmount);
            
            const donorBalanceAfter = await ethers.provider.getBalance(doner.address);
            expect(donorBalanceAfter).to.be.lessThan(donorBalanceBefore);

            campaignDonatives = await crowdfunding.connect(user).getDonatives(campaignID, {gasLimit: 6721975});
            expect(campaignDonatives.length).to.equal(1);
            expect(campaignDonatives[0].donner).to.equal(doner.address);
            expect(campaignDonatives[0].quantity).to.equal(donationAmount);

            campaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});
            expect(campaigns[0].completed).to.equal(false);
        });

        it("should add a donative and mark as a completed the campaign", async () => {
            const donationAmount = toWei(26);

            const balanceBefore = await ethers.provider.getBalance(crowdfunding.target);
            expect(balanceBefore).to.equal(toWei(0));

            const donorBalanceBefore = await ethers.provider.getBalance(doner.address);
            
            await crowdfunding.connect(doner).addDonative(campaignID, { value: donationAmount, gasLimit: 6721975 });
            
            const balanceAfter = await ethers.provider.getBalance(crowdfunding.target);
            expect(balanceAfter).to.equal(donationAmount);
            
            const donorBalanceAfter = await ethers.provider.getBalance(doner.address);
            expect(donorBalanceAfter).to.be.lessThan(donorBalanceBefore);

            campaignDonatives = await crowdfunding.connect(user).getDonatives(campaignID, {gasLimit: 6721975});
            expect(campaignDonatives.length).to.equal(1);
            expect(campaignDonatives[0].donner).to.equal(doner.address);
            expect(campaignDonatives[0].quantity).to.equal(donationAmount);

            campaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});
            expect(campaigns[0].completed).to.equal(true);
        });

        it("should fails when the campaign reached the expected amount", async () => {
            try {
                const donationAmount = toWei(26);

                const balanceBefore = await ethers.provider.getBalance(crowdfunding.target);
                expect(balanceBefore).to.equal(toWei(0));
    
                const donorBalanceBefore = await ethers.provider.getBalance(doner.address);
                
                await crowdfunding.connect(doner).addDonative(campaignID, { value: donationAmount });
                
                const balanceAfter = await ethers.provider.getBalance(crowdfunding.target);
                expect(balanceAfter).to.equal(donationAmount);
                
                const donorBalanceAfter = await ethers.provider.getBalance(doner.address);
                expect(donorBalanceAfter).to.be.lessThan(donorBalanceBefore);
    
                campaignDonatives = await crowdfunding.connect(user).getDonatives(campaignID);
                expect(campaignDonatives.length).to.equal(1);
                expect(campaignDonatives[0].donner).to.equal(doner.address);
                expect(campaignDonatives[0].quantity).to.equal(donationAmount);
    
                campaigns = await crowdfunding.connect(user).getAllCampaigns();
                expect(campaigns[0].completed).to.equal(true);
    
                await crowdfunding.connect(doner).addDonative(campaignID, { value: toWei(2) });

            } catch(error) {
                expect(error.message.includes("Campaign already reach the expected amount")).to.equal(true)
            }

        });
    });

    describe("reviewCampaignsJob", () => {
        let campaigns;
        let campaignID;
        let donationAmount = toWei(2);

        beforeEach(async () => {
            transaction = await crowdfunding.connect(user).createCampaign(
                "test campaign",
                "test description",
                toWei(2)
            );
            await transaction.wait()

            campaigns = await crowdfunding.connect(user).getAllCampaigns();
            expect(campaigns.length).to.equal(1)
            expect(campaigns[0].owner).to.equal(user.address);

            campaignID = campaigns[0].Id;
        });

        it("should review the campaigns and do the payments", async () => {
            const campaignUserBalanceBefore = await ethers.provider.getBalance(user.address);
            await crowdfunding.connect(doner).addDonative(campaignID, { value: donationAmount, gasLimit: 6721975 });

            const balanceBefore = await ethers.provider.getBalance(crowdfunding.target);
            expect(balanceBefore).to.equal(toWei(2));

            updatedCampaigns = await crowdfunding.connect(user).getAllCampaigns({gasLimit: 6721975});

            expect(updatedCampaigns[0].completed).to.equal(true);
            expect(updatedCampaigns[0].isActive).to.equal(true);
            
            // make the payments
            await crowdfunding.connect(deployer).reviewCampaignsJob({gasLimit: 6721975});

            campaignsReviewed = await crowdfunding.connect(user).getAllCampaigns();

            expect(campaignsReviewed[0].isActive).to.equal(false);

            const campaignUserBalanceAfter = await ethers.provider.getBalance(user.address);
            expect(campaignUserBalanceAfter).to.be.greaterThan(campaignUserBalanceBefore);

            const balanceAfter = await ethers.provider.getBalance(crowdfunding.target);
            feeResult = (2 * 3) / 100
            expect(balanceAfter).to.equal(toWei(feeResult));
            expect(balanceAfter).to.be.lessThan(balanceBefore);

            // validate if all the tokens were created
            tokensCount = await certificateNFT.connect(deployer).getTokensCount();
            expect(tokensCount).to.equal(1);
            
            donnerCerts = await certificateNFT.connect(doner).getMyNFTCertificates(doner.address);
            expect(donnerCerts.length).to.equal(1)
            
            const nftBalance = await certificateNFT.balanceOf(doner.address);
            expect(nftBalance).to.equal(1);

            const ownerOfToken = await certificateNFT.ownerOf(donnerCerts[0].tokenID);
            expect(ownerOfToken).to.equal(doner.address);
            
            const tokenURIOf = await certificateNFT.tokenURI(donnerCerts[0].tokenID);
            expect(tokenURIOf).to.equal("some-value-here");

            const nftContractBalance = await certificateNFT.balanceOf(certificateNFT.target);
            expect(nftContractBalance).to.equal(0);

        });
    });

});