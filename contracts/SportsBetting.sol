// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SportsBetting is Ownable, ReentrancyGuard {
    // Custom struct to represent a round's predictions
    struct RoundPredictions {
        string[] teams;
    }

    // Bracket struct containing 4 rounds of predictions
    struct Bracket {
        RoundPredictions[4] rounds;
    }

    // Mapping to store player predictions
    mapping(address => Bracket) private playerPredictions;
    
    // Actual winners bracket
    Bracket private actualWinners;

    // Add new state variables for tracking players and winners
    address[] private players;
    mapping(uint256 => string[]) private roundWinners;
    mapping(address => bool) private hasSubmitted;

    // Add state variable to track total pot
    uint256 private totalPot;

    // Events
    event BracketCreated(address indexed player);
    event WinnerUpdated(uint256 indexed round, string teamNum);
    event WinnerDeclared(address winner, uint256 score);

    // Error messages
    error InvalidRound();
    error InvalidPredictionsLength();
    error BracketAlreadySubmitted();
    error RoundNotCompleted();

    // Constants
    uint256 private constant ROUND_1_PREDICTIONS = 6;
    uint256 private constant ROUND_2_PREDICTIONS = 4;
    uint256 private constant ROUND_3_PREDICTIONS = 2;
    uint256 private constant ROUND_4_PREDICTIONS = 1;

    constructor() {
        // Initialize empty arrays for each round in actualWinners
        for(uint i = 0; i < 4; i++) {
            actualWinners.rounds[i].teams = new string[](0);
        }
    }

    /**
     * @dev Creates a bracket for the player with their predictions
     * @param predictions Array of team numbers representing predictions
     */
    function createBracket(string[] calldata predictions) external payable nonReentrant {
        // Check if player already submitted
        if (hasSubmitted[msg.sender]) revert BracketAlreadySubmitted();

        // Check if correct amount was sent
        require(msg.value == 0.000001 ether, "Must send exactly 0.000001 ETH to submit bracket");

        // Add to total pot
        totalPot += msg.value;

        // Validate predictions length
        if (predictions.length != (ROUND_1_PREDICTIONS + ROUND_2_PREDICTIONS + 
            ROUND_3_PREDICTIONS + ROUND_4_PREDICTIONS)) {
            revert InvalidPredictionsLength();
        }

        uint256 currentIndex = 0;

        // Initialize arrays for each round
        playerPredictions[msg.sender].rounds[0].teams = new string[](ROUND_1_PREDICTIONS);
        playerPredictions[msg.sender].rounds[1].teams = new string[](ROUND_2_PREDICTIONS);
        playerPredictions[msg.sender].rounds[2].teams = new string[](ROUND_3_PREDICTIONS);
        playerPredictions[msg.sender].rounds[3].teams = new string[](ROUND_4_PREDICTIONS);

        // Fill Round 1
        for (uint256 i = 0; i < ROUND_1_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[0].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 2
        for (uint256 i = 0; i < ROUND_2_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[1].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 3
        for (uint256 i = 0; i < ROUND_3_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[2].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 4
        playerPredictions[msg.sender].rounds[3].teams[0] = predictions[currentIndex];

        // Add player to tracking
        players.push(msg.sender);
        hasSubmitted[msg.sender] = true;

        emit BracketCreated(msg.sender);
    }

    /**
     * @dev Updates winner for a specific round and pays out winner if final round
     * @param round Round number (1-4)
     * @param teamNum Team number that won
     */
    function updateWinner(uint256 round, string calldata teamNum) external onlyOwner {
        if (round < 1 || round > 4) revert InvalidRound();
        
        uint256 roundIndex = round - 1;
        actualWinners.rounds[roundIndex].teams.push(teamNum);
        
        emit WinnerUpdated(round, teamNum);

        // If final round, calculate winner and transfer prize
        if (round == 4) {
            (address winner, uint256 score) = calculateWinner();
            uint256 prize = (totalPot * 90) / 100; // 90% of total pot
            
            // Reset total pot before transfer to prevent reentrancy
            totalPot = 0;
            
            // Transfer prize to winner
            (bool success, ) = payable(winner).call{value: prize}("");
            require(success, "Failed to send prize to winner");
            
            emit WinnerDeclared(winner, score);
        }
    }

    /**
     * @dev Calculates the winner based on predictions
     * @return winner Address of the winner
     * @return highestScore Highest score achieved
     */
    function calculateWinner() public view returns (address winner, uint256 highestScore) {
        highestScore = 0;

        // Rename players to allPlayers to avoid shadowing
        address[] memory allPlayers = _getPlayers();
        
        for (uint256 i = 0; i < allPlayers.length; i++) {
            address player = allPlayers[i];
            uint256 playerScore = 0;

            // Calculate score for each round
            for (uint256 round = 0; round < 4; round++) {
                uint256 roundScore = _calculateRoundScore(player, round);
                playerScore += roundScore * (round + 1);
            }

            // Update highest score if necessary
            if (playerScore > highestScore) {
                highestScore = playerScore;
                winner = player;
            }
        }
    }

    /**
     * @dev Calculates score for a specific round
     */
    function _calculateRoundScore(address player, uint256 roundIndex) private view returns (uint256) {
        uint256 score = 0;
        string[] memory winners = _getRoundWinners(roundIndex);
        string[] memory playerTeams = playerPredictions[player].rounds[roundIndex].teams;

        for (uint256 i = 0; i < winners.length; i++) {
            for (uint256 j = 0; j < playerTeams.length; j++) {
                if (keccak256(bytes(winners[i])) == keccak256(bytes(playerTeams[j]))) {
                    score++;
                }
            }
        }
        return score;
    }

    /**
     * @dev Checks if a player has submitted predictions
     */
    function _hasPredictions(address player) private view returns (bool) {
        return hasSubmitted[player];
    }

    /**
     * @dev Gets all players who have submitted predictions
     */
    function _getPlayers() private view returns (address[] memory) {
        return players;
    }

    /**
     * @dev Gets winners for a specific round
     */
    function _getRoundWinners(uint256 round) private view returns (string[] memory) {
        return roundWinners[round];
    }

    // Add new view functions for external queries
    
    /**
     * @dev Get the number of players who have submitted brackets
     */
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    /**
     * @dev Get winners for a specific round
     */
    function getRoundWinners(uint256 round) external view returns (string[] memory) {
        require(round <= 4 && round > 0, "Invalid round");
        return roundWinners[round-1];
    }

    /**
     * @dev Get all players who have submitted brackets
     */
    function getAllPlayers() external view returns (address[] memory) {
        return players;
    }

    /**
     * @dev Get all predictions for a player's bracket organized by round
     * @param player Address of the player
     * @return result Array of string arrays where each inner array contains teams picked for that round
     */
    function getBracketPredictions(address player) external view returns (string[][] memory result) {
        require(hasSubmitted[player], "Player has not submitted a bracket");
        
        result = new string[][](4);
        
        for (uint256 roundIndex = 0; roundIndex < 4; roundIndex++) {
            result[roundIndex] = playerPredictions[player].rounds[roundIndex].teams;
        }
        
        return result;
    }

    /**
     * @dev Get current prize pool
     */
    function getPrizePool() external view returns (uint256) {
        return (totalPot * 90) / 100; // 90% of total pot
    }

    /**
     * @dev Updates all winners for all rounds at once. Only callable by owner.
     * @param winners Array of 13 team names representing winners for all rounds
     */
    function setAllWinners(string[] calldata winners) external onlyOwner {
        if (winners.length != 13) revert InvalidPredictionsLength();
        
        uint256 currentIndex = 0;
        
        // Clear existing winners
        for (uint256 round = 0; round < 4; round++) {
            delete roundWinners[round];
        }

        // Set Round 1 winners (6 teams)
        for (uint256 i = 0; i < ROUND_1_PREDICTIONS; i++) {
            actualWinners.rounds[0].teams.push(winners[currentIndex]);
            roundWinners[0].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 2 winners (4 teams)
        for (uint256 i = 0; i < ROUND_2_PREDICTIONS; i++) {
            actualWinners.rounds[1].teams.push(winners[currentIndex]);
            roundWinners[1].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 3 winners (2 teams)
        for (uint256 i = 0; i < ROUND_3_PREDICTIONS; i++) {
            actualWinners.rounds[2].teams.push(winners[currentIndex]);
            roundWinners[2].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 4 winner (1 team)
        actualWinners.rounds[3].teams.push(winners[currentIndex]);
        roundWinners[3].push(winners[currentIndex]);

        // Calculate and distribute prize
        (address winner, uint256 score) = calculateWinner();
        uint256 prize = (totalPot * 90) / 100; // 90% of total pot
        
        // Reset total pot before transfer to prevent reentrancy
        totalPot = 0;
        
        // Transfer prize to winner
        (bool success, ) = payable(winner).call{value: prize}("");
        require(success, "Failed to send prize to winner");
        
        emit WinnerDeclared(winner, score);
    }
}