const { expect } = require("chai");
const hre = require("hardhat");

const NUM_MEMBERS = 300;
// By changing that number manually, we can test different num of users

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

        for (let i = 0; i < NUM_MEMBERS; i++) {
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
        for (let i = 0; i < NUM_MEMBERS; i++) {
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

    it("should reject MGOV and TL donation without enough tokens", async () => {
        await expect(
            myGov
                .connect(members[1])
                .donateMyGovToken(hre.ethers.parseEther("2"))
        ).to.be.revertedWith("Not enough MGOV tokens for donation");
    });

    it("should reject TL donation without enough tokens", async () => {
        await expect(
            myGov
                .connect(members[1])
                .donateTLToken(hre.ethers.parseEther("500"))
        ).to.be.reverted;
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

    it("should reject survey submission when insufficient funds", async () => {
        await expect(
            myGov
                .connect(members[3])
                .submitSurvey(
                    "http://survey.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    4,
                    2
                )
        ).to.be.revertedWith("At least 2 MGOV tokens required");
    });

    it("Should reject survey submission if not member", async () => {
        await myGov
            .connect(members[4])
            .donateMyGovToken(hre.ethers.parseEther("1"));
        await expect(
            myGov
                .connect(members[4])
                .submitSurvey(
                    "http://surveyfail.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    3,
                    1
                )
        ).to.be.revertedWith("Only members can submit surveys");
    });

    it("should allow survey submission and voting", async () => {
        await tlToken
            .connect(members[5])
            .approve(myGov.target, hre.ethers.parseEther("1000"));
        await myGov
            .connect(owner)
            .transfer(members[5].address, hre.ethers.parseEther("2"));

        await myGov
            .connect(members[5])
            .submitSurvey(
                "http://newsurvey.com",
                Math.floor(Date.now()) + 100000,
                3,
                1
            );
        await myGov.connect(members[5]).takeSurvey(0, [1]);

        const results = await myGov.getSurveyResults(0);
        expect(results[0]).to.equal(1);
    });

    it("should allow another member to take a survey", async () => {
        await myGov.connect(members[6]).takeSurvey(0, [2]);
        const results = await myGov.getSurveyResults(0);
        expect(results[0]).to.equal(2);
    });

    it("should get survey details and ownership", async () => {
        const surveyor = members[16];
        await tlToken
            .connect(surveyor)
            .approve(myGov.target, hre.ethers.parseEther("1000"));
        await myGov
            .connect(owner)
            .transfer(surveyor.address, hre.ethers.parseEther("2"));

        await myGov
            .connect(surveyor)
            .submitSurvey(
                "http://detailsurvey.com",
                Math.floor(Date.now() / 1000) + 1000,
                3,
                1
            );

        const [weburl] = await myGov.getSurveyInfo(1);
        const surveyOwner = await myGov.getSurveyOwner(1);
        expect(weburl).to.equal("http://detailsurvey.com");
        expect(surveyOwner).to.equal(surveyor.address);
    });

    it("should reject proposal if not enough MGOV", async () => {
        await tlToken
            .connect(members[7])
            .approve(myGov.target, hre.ethers.parseEther("4000"));
        await expect(
            myGov
                .connect(members[3])
                .submitProjectProposal(
                    "http://fail.com",
                    Math.floor(Date.now() / 1000) + 1000,
                    [1000],
                    [10]
                )
        ).to.be.revertedWith("5 MGOV tokens required");
    });

    it("should allow submitting project proposal", async () => {
        await tlToken
            .connect(members[7])
            .approve(myGov.target, hre.ethers.parseEther("5000"));

        await myGov
            .connect(owner)
            .transfer(members[7].address, hre.ethers.parseEther("5"));

        await myGov
            .connect(members[7])
            .submitProjectProposal(
                "http://project.com",
                Math.floor(Date.now()) + 1000,
                [1000],
                [300, 500]
            );
        await myGov.connect(members[8]).voteForProjectProposal(0, true);

        await expect(await myGov.getProjectOwner(0)).to.equal(
            members[7].address
        );
    });

    it("should allow voting for project proposal and payment", async () => {
        const proposer = members[9];
        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("5000"));
        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://voteproposal.com",
                Math.floor(Date.now()) + 1000,
                [500],
                [300, 500]
            );
        await myGov.connect(members[10]).voteForProjectProposal(1, true);
        await myGov.connect(proposer).reserveProjectGrant(1);

        await hre.network.provider.send("evm_increaseTime", [4000]);
        await hre.network.provider.send("evm_mine");

        await myGov.connect(proposer).voteForProjectPayment(1, 0);
    });

    it("should allow reserve and withdraw project payment", async () => {
        const proposer = members[11];
        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("5000"));
        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://withdrawtest.com",
                Math.floor(Date.now()) + 1000,
                [500],
                [300, 500]
            );

        for (let i = 12; i < 43; i++) {
            await myGov.connect(members[i]).voteForProjectProposal(2, true);
        }

        await myGov.connect(proposer).reserveProjectGrant(2);

        await hre.network.provider.send("evm_increaseTime", [4000]);
        await hre.network.provider.send("evm_mine");

        for (let i = 12; i < 30; i++) {
            await myGov.connect(members[i]).voteForProjectPayment(2, true);
        }
        await myGov.connect(proposer).withdrawProjectTLPayment(2);
    });

    it("should allow vote for project payment after reserve and time passed", async () => {
        const proposer = members[12];
        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("5000"));
        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://project.pay",
                Math.floor(Date.now()) + 1000,
                [500],
                [300, 500]
            );
        for (let i = 12; i < 43; i++) {
            await myGov.connect(members[i]).voteForProjectProposal(3, true);
        }
        await myGov.connect(proposer).reserveProjectGrant(3);

        // Simulate time passing (note: this requires evm_increaseTime in actual Hardhat runtime)
        await hre.network.provider.send("evm_increaseTime", [4000]);
        await hre.network.provider.send("evm_mine");
        for (let i = 12; i < 30; i++) {
            await myGov.connect(members[i]).voteForProjectPayment(3, true);
        }
        await myGov.connect(proposer).withdrawProjectTLPayment(3);

        const received = await myGov.getTLReceivedByProject(3);
        expect(received).to.be.greaterThan(0);
    });

    it("should delegate votes and allow target member to use them", async () => {
        const delegator = members[13];
        const delegatee = members[14];
        const proposer = members[15];

        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("5000"));
        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://delegation.com",
                Math.floor(Date.now()) + 1000,
                [500],
                [300, 500]
            );

        await myGov.connect(delegator).delegateVoteTo(delegatee.address, 4);
        await myGov.connect(delegatee).voteForProjectProposal(4, true);
        await myGov.connect(delegatee).voteForProjectProposal(4, true);
    });

    it("should get project status, owner and info", async () => {
        const proposer = members[16];
        await tlToken
            .connect(proposer)
            .approve(myGov.target, hre.ethers.parseEther("4000"));
        await myGov
            .connect(owner)
            .transfer(proposer.address, hre.ethers.parseEther("5"));

        await myGov
            .connect(proposer)
            .submitProjectProposal(
                "http://statusproject.com",
                Math.floor(Date.now()) + 1000,
                [500],
                [300, 500]
            );

        const projectOwner = await myGov.getProjectOwner(5);
        const [weburl] = await myGov.getProjectInfo(5);
        expect(await myGov.getProjectNextTLPayment(5)).to.equal(300);
        expect(projectOwner).to.equal(proposer.address);
        expect(weburl).to.equal("http://statusproject.com");
    });

    it("should return correct counts and totals", async () => {
        const countProposals = await myGov.getNoOfProjectProposals();
        const countFunded = await myGov.getNoOfFundedProjects();
        const totalReceived = await myGov.getTLReceivedByProject(5);
        const countSurveys = await myGov.getNoOfSurveys();

        expect(countProposals).to.be.gte(1);
        expect(countFunded).to.be.gte(1);
        expect(totalReceived).to.be.a("bigint");
        expect(countSurveys).to.be.gte(1);
    });

    it("should revert when accessing non-existent survey or project", async () => {
        await expect(myGov.getSurveyInfo(999)).to.be.reverted;
        await expect(myGov.getSurveyOwner(999)).to.be.reverted;
        await expect(myGov.getSurveyResults(999)).to.be.reverted;

        await expect(myGov.getProjectOwner(999)).to.be.reverted;
        await expect(myGov.getProjectInfo(999)).to.be.reverted;
        await expect(myGov.getProjectNextTLPayment(999)).to.be.reverted;
        await expect(myGov.getIsProjectFunded(999)).to.be.reverted;
        await expect(myGov.getTLReceivedByProject(999)).to.be.reverted;
    });

    it("should return zero for initial counts and values", async () => {
        const tempGov = await (
            await hre.ethers.getContractFactory("MyGov")
        ).deploy(tlToken.target);
        await tempGov.waitForDeployment();

        expect(await tempGov.getNoOfSurveys()).to.equal(0);
        expect(await tempGov.getNoOfProjectProposals()).to.equal(0);
        expect(await tempGov.getNoOfFundedProjects()).to.equal(0);
    });
});
