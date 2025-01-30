const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SportsBetting", function () {
    let sportsBetting;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        const SportsBetting = await ethers.getContractFactory("SportsBetting");
        sportsBetting = await SportsBetting.deploy();
        await sportsBetting.deployed();
    });

    describe("Bracket Creation", function () {
        it("Should allow a player to create a bracket", async function () {
            const predictions = [
                "1", "2", "3", "4", "5", "6",  // Round 1
                "7", "8", "9", "10",           // Round 2
                "11", "12",                    // Round 3
                "13"                           // Round 4
            ];

            await sportsBetting.connect(addr1).createBracket(predictions);
            expect(await sportsBetting.hasSubmittedBracket(addr1.address)).to.be.true;
            expect(await sportsBetting.getPlayerCount()).to.equal(1);
        });

        it("Should prevent duplicate submissions", async function () {
            const predictions = [
                "1", "2", "3", "4", "5", "6",
                "7", "8", "9", "10",
                "11", "12",
                "13"
            ];

            await sportsBetting.connect(addr1).createBracket(predictions);
            await expect(
                sportsBetting.connect(addr1).createBracket(predictions)
            ).to.be.revertedWithCustomError(sportsBetting, "BracketAlreadySubmitted");
        });
    });

    describe("Winner Updates", function () {
        it("Should allow owner to update winners", async function () {
            await expect(sportsBetting.connect(owner).updateWinner(1, "team1"))
                .to.emit(sportsBetting, "WinnerUpdated")
                .withArgs(1, "team1");
        });

        it("Should revert if non-owner tries to update winners", async function () {
            await expect(sportsBetting.connect(addr1).updateWinner(1, "team1"))
                .to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should revert for invalid round numbers", async function () {
            await expect(sportsBetting.connect(owner).updateWinner(0, "team1"))
                .to.be.revertedWithCustomError(sportsBetting, "InvalidRound");
            
            await expect(sportsBetting.connect(owner).updateWinner(5, "team1"))
                .to.be.revertedWithCustomError(sportsBetting, "InvalidRound");
        });
    });

    describe("Score Calculation", function () {
        beforeEach(async function () {
            // Setup two players with different predictions
            await sportsBetting.connect(addr1).createBracket(samplePredictions);
            
            const addr2Predictions = [
                "teamA", "teamB", "teamC", "teamD", "teamE", "teamF",
                "teamB", "teamC", "teamD", "teamE",
                "teamC", "teamD",
                "teamC"
            ];
            await sportsBetting.connect(addr2).createBracket(addr2Predictions);
        });

        it("Should calculate scores correctly when final round is updated", async function () {
            // Update winners for all rounds
            await sportsBetting.connect(owner).updateWinner(1, "team1");
            await sportsBetting.connect(owner).updateWinner(2, "team3");
            await sportsBetting.connect(owner).updateWinner(3, "team3");
            
            // Final round update should trigger winner calculation
            await expect(sportsBetting.connect(owner).updateWinner(4, "team3"))
                .to.emit(sportsBetting, "WinnerDeclared");
        });
    });

    describe("Edge Cases", function () {
        it("Should handle empty strings in predictions", async function () {
            const predictionsWithEmpty = [
                "", "team2", "team3", "team4", "team5", "team6",
                "team2", "team3", "team4", "team5",
                "team3", "team4",
                "team3"
            ];
            await expect(sportsBetting.connect(addr1).createBracket(predictionsWithEmpty))
                .to.emit(sportsBetting, "BracketCreated");
        });

        it("Should handle duplicate team predictions", async function () {
            const duplicatePredictions = [
                "team1", "team1", "team1", "team1", "team1", "team1",
                "team1", "team1", "team1", "team1",
                "team1", "team1",
                "team1"
            ];
            await expect(sportsBetting.connect(addr1).createBracket(duplicatePredictions))
                .to.emit(sportsBetting, "BracketCreated");
        });
    });
}); 