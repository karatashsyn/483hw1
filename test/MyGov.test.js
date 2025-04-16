const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyGov Full Test", function () {
    let tlToken, myGov, owner, members;

    before(async () => {
        [owner, ...members] = await ethers.getSigners();

        const TLToken = await ethers.getContractFactory("TLToken");
        tlToken = await TLToken.deploy();
        await tlToken.deployed();

        const MyGov = await ethers.getContractFactory("MyGov");
        myGov = await MyGov.deploy(tlToken.address);
        await myGov.deployed();

        // Faucet TL to users for testing
        for (let i = 0; i < 300; i++) {
            await tlToken.faucet(
                members[i].address,
                ethers.utils.parseEther("10000")
            );
        }
    });

    it("should allow 300 unique addresses to claim MGOV from faucet", async () => {
        for (let i = 0; i < 300; i++) {
            await myGov.connect(members[i]).faucet();
            expect(await myGov.balanceOf(members[i].address)).to.equal(
                ethers.utils.parseEther("1")
            );
        }
    });

    it("should allow donation of TL and MGOV tokens", async () => {
        await tlToken
            .connect(members[0])
            .approve(myGov.address, ethers.utils.parseEther("500"));
        await myGov
            .connect(members[0])
            .donateTLToken(ethers.utils.parseEther("500"));

        await myGov
            .connect(members[0])
            .donateMyGovToken(ethers.utils.parseEther("0.5"));

        expect(await tlToken.balanceOf(myGov.address)).to.be.gte(
            ethers.utils.parseEther("500")
        );
    });

    it("should submit and vote on a project proposal", async () => {
        const proposer = members[1];
        await tlToken
            .connect(proposer)
            .approve(myGov.address, ethers.utils.parseEther("4000"));
        await myGov
            .connect(proposer)
            .approve(myGov.address, ethers.utils.parseEther("5")); // MGOV approve
        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://project1.com",
                Date.now() + 100000,
                [100, 200],
                [3600, 7200]
            );

        await myGov.connect(members[2]).voteForProjectProposal(0, true);
        await myGov.connect(members[3]).delegateVoteTo(members[2].address, 0);
        expect(await myGov.getProjectOwner(0)).to.equal(proposer.address);
    });

    it("should submit and take a survey", async () => {
        const surveyor = members[4];
        await tlToken
            .connect(surveyor)
            .approve(myGov.address, ethers.utils.parseEther("1000"));
        await myGov
            .connect(surveyor)
            .approve(myGov.address, ethers.utils.parseEther("2"));
        await myGov
            .connect(surveyor)
            .submitSurvey("http://survey.com", Date.now() + 100000, 4, 2);

        await myGov.connect(members[5]).takeSurvey(0, [0, 1]);
        const [takers, results] = await myGov.getSurveyResults(0);
        expect(takers).to.equal(1);
        expect(results[0]).to.equal(1);
    });
});
