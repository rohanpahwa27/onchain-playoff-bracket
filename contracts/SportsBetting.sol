// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SportsBetting is Ownable, ReentrancyGuard {
    // Custom struct to represent a round's predictions
    struct RoundPredictions {
        mapping(string => bool) predictions;
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

    /**
     * @dev Creates a bracket for the player with their predictions
     * @param predictions Array of team numbers representing predictions
     */
    function createBracket(string[] calldata predictions) external nonReentrant {
        // Check if player already submitted
        if (hasSubmitted[msg.sender]) revert BracketAlreadySubmitted();

        // Validate predictions length
        if (predictions.length != (ROUND_1_PREDICTIONS + ROUND_2_PREDICTIONS + 
            ROUND_3_PREDICTIONS + ROUND_4_PREDICTIONS)) {
            revert InvalidPredictionsLength();
        }

        uint256 currentIndex = 0;

        // Fill Round 1
        for (uint256 i = 0; i < ROUND_1_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[0].predictions[predictions[currentIndex]] = true;
            currentIndex++;
        }

        // Fill Round 2
        for (uint256 i = 0; i < ROUND_2_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[1].predictions[predictions[currentIndex]] = true;
            currentIndex++;
        }

        // Fill Round 3
        for (uint256 i = 0; i < ROUND_3_PREDICTIONS; i++) {
            playerPredictions[msg.sender].rounds[2].predictions[predictions[currentIndex]] = true;
            currentIndex++;
        }

        // Fill Round 4
        playerPredictions[msg.sender].rounds[3].predictions[predictions[currentIndex]] = true;

        // Add player to tracking
        players.push(msg.sender);
        hasSubmitted[msg.sender] = true;

        emit BracketCreated(msg.sender);
    }

    /**
     * @dev Updates winner for a specific round
     * @param round Round number (1-4)
     * @param teamNum Team number that won
     */
    function updateWinner(uint256 round, string calldata teamNum) external onlyOwner {
        if (round < 1 || round > 4) revert InvalidRound();
        
        uint256 roundIndex = round - 1;
        actualWinners.rounds[roundIndex].predictions[teamNum] = true;
        
        // Store winner in roundWinners array
        roundWinners[roundIndex].push(teamNum);
        
        emit WinnerUpdated(round, teamNum);

        // If final round, calculate winner
        if (round == 4) {
            (address winner, uint256 score) = calculateWinner();
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
    function _calculateRoundScore(address player, uint256 round) private view returns (uint256) {
        uint256 score = 0;
        string[] memory winners = _getRoundWinners(round);

        for (uint256 i = 0; i < winners.length; i++) {
            if (playerPredictions[player].rounds[round].predictions[winners[i]]) {
                score++;
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
        require(round < 4, "Invalid round");
        return roundWinners[round];
    }

    /**
     * @dev Check if an address has submitted a bracket
     */
    function hasSubmittedBracket(address player) external view returns (bool) {
        return hasSubmitted[player];
    }

    /**
     * @dev Get all players who have submitted brackets
     */
    function getAllPlayers() external view returns (address[] memory) {
        return players;
    }

    // Add a getter function to check predictions
    function getPrediction(address player, uint256 round, string calldata teamNum) 
        external 
        view 
        returns (bool) 
    {
        return playerPredictions[player].rounds[round].predictions[teamNum];
    }

    // Add getter function for actualWinners
    function getActualWinner(uint256 round, string calldata teamNum) 
        external 
        view 
        returns (bool) 
    {
        return actualWinners.rounds[round].predictions[teamNum];
    }
} 