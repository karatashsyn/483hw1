const { expect } = require("chai");
const hre = require("hardhat");

describe("MyGov Full Test", function () {
    let tlToken, myGov, owner, members;

    before(async () => {
        [owner] = await hre.ethers.getSigners();
        members = [];

        const TLToken = await hre.ethers.getContractFactory("TLToken");
        tlToken = await TLToken.deploy();
        await tlToken.waitForDeployment();

        const MyGov = await hre.ethers.getContractFactory("MyGov");
        myGov = await MyGov.deploy(tlToken.target);
        await myGov.waitForDeployment();

        for (let i = 0; i < 300; i++) {
            const wallet = hre.ethers.Wallet.createRandom().connect(
                hre.ethers.provider
            );
            members.push(wallet);

            await owner.sendTransaction({
                to: wallet.address,
                value: hre.ethers.parseEther("10")
            });

            await tlToken.faucet(
                wallet.address,
                hre.ethers.parseEther("10000")
            );
        }
        // await myGov.transfer(owner.address, hre.ethers.parseEther("100"));
        await myGov.testFund(owner.address, hre.ethers.parseEther("100"));
    });

    it("should allow 300 unique addresses to claim MGOV from faucet", async () => {
        for (let i = 0; i < 300; i++) {
            await myGov.connect(members[i]).faucet();
            expect(
                await myGov.balanceOf(members[i].address)
            ).to.greaterThanOrEqual(hre.ethers.parseEther("1"));
        }
    });

    it("should reject second faucet claim", async () => {
        await expect(myGov.connect(members[0]).faucet()).to.be.revertedWith(
            "Already claimed"
        );
    });

    it("should reject MGOV donation without enough tokens", async () => {
        await expect(
            myGov
                .connect(members[1])
                .donateMyGovToken(hre.ethers.parseEther("2"))
        ).to.be.revertedWith("Not enough MGOV tokens for donation");
    });

    it("should reject survey creation when insufficient funds", async () => {
        const outsider = members[299];
        await expect(
            myGov
                .connect(outsider)
                .submitSurvey(
                    "http://survey.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    4,
                    2
                )
        ).to.be.revertedWith("At least 2 MGOV tokens required");
    });

    it("should allow donation of TL and MGOV tokens for valid member", async () => {
        await tlToken
            .connect(members[2])
            .approve(myGov.target, hre.ethers.parseEther("500"));
        await myGov
            .connect(members[2])
            .donateMyGovToken(hre.ethers.parseEther("0.5"));
        await myGov
            .connect(members[2])
            .donateTLToken(hre.ethers.parseEther("500"));

        expect(await tlToken.balanceOf(myGov.target)).to.be.gte(
            hre.ethers.parseEther("500")
        );
    });

    it("should reject proposal if not enough MGOV", async () => {
        const lowBalance = members[3];
        await tlToken
            .connect(lowBalance)
            .approve(myGov.target, hre.ethers.parseEther("4000"));
        await expect(
            myGov
                .connect(lowBalance)
                .submitProjectProposal(
                    "http://fail.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    [1000],
                    [10]
                )
        ).to.be.revertedWith("5 MGOV tokens required");
    });

    it("Should reject survey submission if not member", async () => {
        const member = members[4];
        await myGov
            .connect(member)
            .donateMyGovToken(hre.ethers.parseEther("1"));
        await expect(
            myGov
                .connect(member)
                .submitSurvey(
                    "http://surveyfail.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    3,
                    1
                )
        ).to.be.revertedWith("Only members can submit surveys");
    });

    it("should pass by rejecting MGOV donation when balance is insufficient", async () => {
        const donor = members[5];
        await expect(
            myGov.connect(donor).donateMyGovToken(hre.ethers.parseEther("5"))
        ).to.be.revertedWith("Not enough MGOV tokens for donation");
    });

    it("should pass by rejecting survey submission from user who lost member status", async () => {
        const surveyor = members[6];
        await tlToken
            .connect(surveyor)
            .approve(myGov.target, hre.ethers.parseEther("1000"));
        await myGov
            .connect(surveyor)
            .donateMyGovToken(hre.ethers.parseEther("1")); // will make balance = 0
        await expect(
            myGov
                .connect(surveyor)
                .submitSurvey(
                    "http://surveyblock.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    3,
                    1
                )
        ).to.be.revertedWith("Only members can submit surveys");
    });

    it("should reject project payment before the withdrawal date", async () => {
        const proposer = members[7];
        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("1000"));

        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("4000"));

        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://project.com",
                Math.floor(Date.now()) + 10000000,
                [1000],
                [10]
            );
        await myGov.connect(members[8]).voteForProjectProposal(0, true);
        await myGov.connect(proposer).reserveProjectGrant(0);

        await expect(
            myGov.connect(proposer).withdrawProjectTLPayment(0)
        ).to.be.revertedWith("Not due yet");
    });
});
