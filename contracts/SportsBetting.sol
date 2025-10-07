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

    // Group struct to manage private groups
    struct Group {
        string name;
        bytes32 passwordHash;
        address[] members;
        uint256 totalPot;
        uint256 entryFee;
        bool exists;
    }

    // Mapping to store player predictions per group
    mapping(bytes32 => mapping(address => Bracket)) private groupPlayerPredictions;

    // Mapping to store groups by their name hash
    mapping(bytes32 => Group) private groups;

    // Mapping to track if a player has submitted in a specific group
    mapping(bytes32 => mapping(address => bool)) private groupHasSubmitted;

    // Mapping to track which groups a player belongs to
    mapping(address => bytes32[]) private playerGroups;

    // Global state variables for round winners (shared across all groups)
    mapping(uint256 => string[]) private roundWinners;

    // Add this state variable at the top with other state variables
    bool public isBracketCreationPaused;

    // Events
    event BracketCreated(address indexed player);
    event GroupBracketCreated(address indexed player, bytes32 indexed groupId, string groupName);
    event GroupCreated(bytes32 indexed groupId, string groupName, address indexed creator);
    event PlayerJoinedGroup(address indexed player, bytes32 indexed groupId, string groupName);
    event WinnerUpdated(uint256 indexed round, string teamNum);
    event GroupWinnerDeclared(bytes32 indexed groupId, string groupName, address winner, uint256 score);
    event WinnerDeclared(address winner, uint256 score);
    event BracketDeleted(address indexed user);
    event WinnerRemoved(uint256 indexed round, string teamNum);

    // Error messages
    error InvalidRound();
    error InvalidPredictionsLength();
    error BracketAlreadySubmitted();
    error RoundNotCompleted();
    error GroupNotFound();
    error InvalidPassword();
    error GroupFull();
    error GroupAlreadyExists();
    error EmptyGroupName();
    error EmptyPassword();
    error InvalidEntryFee();
    error IncorrectEntryFeeAmount();

    // Constants
    uint256 private constant ROUND_1_PREDICTIONS = 6;
    uint256 private constant ROUND_2_PREDICTIONS = 4;
    uint256 private constant ROUND_3_PREDICTIONS = 2;
    uint256 private constant ROUND_4_PREDICTIONS = 1;
    uint256 private constant MAX_GROUP_SIZE = 20;
    uint256 private constant MAX_ENTRY_FEE = 0.001 ether;

    // Add point constants at the top with other constants
    uint256 private constant ROUND_1_POINTS = 1; // Wildcard
    uint256 private constant ROUND_2_POINTS = 2; // Divisional
    uint256 private constant ROUND_3_POINTS = 4; // Conference
    uint256 private constant ROUND_4_POINTS = 6; // Super Bowl

    constructor() {
        // Remove initialization of actualWinners since we don't need it anymore
    }

    /**
     * @dev Internal function to hash group name and password for secure storage
     */
    function _hashGroupCredentials(string memory groupName, string memory password) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(groupName, password));
    }

    /**
     * @dev Internal function to get group ID from group name
     */
    function _getGroupId(string memory groupName) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(groupName));
    }

    /**
     * @dev Internal function to verify group password
     */
    function _verifyGroupPassword(bytes32 groupId, string memory password) private view returns (bool) {
        if (!groups[groupId].exists) return false;
        string memory groupName = groups[groupId].name;
        bytes32 expectedHash = _hashGroupCredentials(groupName, password);
        return groups[groupId].passwordHash == expectedHash;
    }

    /**
     * @dev Internal function to create a new group
     */
    function _createGroup(string memory groupName, string memory password, uint256 entryFee) private {
        bytes32 groupId = _getGroupId(groupName);

        require(!groups[groupId].exists, "Group already exists");

        // Validate entry fee
        if (entryFee == 0 || entryFee > MAX_ENTRY_FEE) revert InvalidEntryFee();

        groups[groupId] = Group({
            name: groupName,
            passwordHash: _hashGroupCredentials(groupName, password),
            members: new address[](0),
            totalPot: 0,
            entryFee: entryFee,
            exists: true
        });

        // Add to tracking array for batch operations
        allGroupIds.push(groupId);

        emit GroupCreated(groupId, groupName, msg.sender);
    }

    /**
     * @dev Creates a bracket for the player within a specific group
     * @param predictions Array of team numbers representing predictions
     * @param groupName Name of the group to join
     * @param password Password for the group
     * @param entryFee Entry fee for the group (only used if creating new group)
     */
    function createBracket(
        string[] calldata predictions,
        string calldata groupName,
        string calldata password,
        uint256 entryFee
    ) external payable nonReentrant {
        require(!isBracketCreationPaused, "Bracket creation is currently paused");

        // Validate inputs
        if (bytes(groupName).length == 0) revert EmptyGroupName();
        if (bytes(password).length == 0) revert EmptyPassword();

        bytes32 groupId = _getGroupId(groupName);

        // Check if group exists, if not create it
        if (!groups[groupId].exists) {
            _createGroup(groupName, password, entryFee);
        } else {
            // Verify password for existing group
            if (!_verifyGroupPassword(groupId, password)) revert InvalidPassword();

            // Check if group is full
            if (groups[groupId].members.length >= MAX_GROUP_SIZE) revert GroupFull();
        }

        // Check if player already submitted in this group
        if (groupHasSubmitted[groupId][msg.sender]) revert BracketAlreadySubmitted();

        // Check if correct amount was sent (use group's entry fee)
        if (msg.value != groups[groupId].entryFee) revert IncorrectEntryFeeAmount();

        // Add to group's total pot
        groups[groupId].totalPot += msg.value;

        // Validate predictions length
        if (
            predictions.length
                != (ROUND_1_PREDICTIONS + ROUND_2_PREDICTIONS + ROUND_3_PREDICTIONS + ROUND_4_PREDICTIONS)
        ) {
            revert InvalidPredictionsLength();
        }

        uint256 currentIndex = 0;

        // Initialize arrays for each round
        groupPlayerPredictions[groupId][msg.sender].rounds[0].teams = new string[](ROUND_1_PREDICTIONS);
        groupPlayerPredictions[groupId][msg.sender].rounds[1].teams = new string[](ROUND_2_PREDICTIONS);
        groupPlayerPredictions[groupId][msg.sender].rounds[2].teams = new string[](ROUND_3_PREDICTIONS);
        groupPlayerPredictions[groupId][msg.sender].rounds[3].teams = new string[](ROUND_4_PREDICTIONS);

        // Fill Round 1
        for (uint256 i = 0; i < ROUND_1_PREDICTIONS; i++) {
            groupPlayerPredictions[groupId][msg.sender].rounds[0].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 2
        for (uint256 i = 0; i < ROUND_2_PREDICTIONS; i++) {
            groupPlayerPredictions[groupId][msg.sender].rounds[1].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 3
        for (uint256 i = 0; i < ROUND_3_PREDICTIONS; i++) {
            groupPlayerPredictions[groupId][msg.sender].rounds[2].teams[i] = predictions[currentIndex];
            currentIndex++;
        }

        // Fill Round 4
        groupPlayerPredictions[groupId][msg.sender].rounds[3].teams[0] = predictions[currentIndex];

        // Add player to group if not already a member
        bool isMember = false;
        for (uint256 i = 0; i < groups[groupId].members.length; i++) {
            if (groups[groupId].members[i] == msg.sender) {
                isMember = true;
                break;
            }
        }

        if (!isMember) {
            groups[groupId].members.push(msg.sender);
            playerGroups[msg.sender].push(groupId);
            emit PlayerJoinedGroup(msg.sender, groupId, groupName);
        }

        groupHasSubmitted[groupId][msg.sender] = true;

        emit GroupBracketCreated(msg.sender, groupId, groupName);
    }

    /**
     * @dev Updates winner for a specific round and pays out winner if final round
     * @param round Round number (1-4)
     * @param teamNum Team number that won
     */
    function updateWinner(uint256 round, string calldata teamNum) external onlyOwner {
        if (round < 1 || round > 4) revert InvalidRound();

        uint256 roundIndex = round - 1;
        uint256 maxWinners;
        if (roundIndex == 0) maxWinners = ROUND_1_PREDICTIONS;
        else if (roundIndex == 1) maxWinners = ROUND_2_PREDICTIONS;
        else if (roundIndex == 2) maxWinners = ROUND_3_PREDICTIONS;
        else maxWinners = ROUND_4_PREDICTIONS;

        require(roundWinners[roundIndex].length < maxWinners, "Maximum winners for this round already set");

        // Check for duplicates
        for (uint256 i = 0; i < roundWinners[roundIndex].length; i++) {
            if (keccak256(bytes(roundWinners[roundIndex][i])) == keccak256(bytes(teamNum))) {
                revert("Winner already exists in this round");
            }
        }

        roundWinners[roundIndex].push(teamNum);

        emit WinnerUpdated(round, teamNum);

        // Note: Group prizes must be distributed manually using distributeGroupPrize()
    }

    /**
     * @dev Distributes prize for a specific group when all rounds are complete
     * @param groupName Name of the group
     */
    function distributeGroupPrize(string calldata groupName) external onlyOwner {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        require(groups[groupId].totalPot > 0, "No prize pool for this group");

        // Check if all rounds are complete (at least 1 winner in final round)
        require(roundWinners[3].length > 0, "Final round not complete");

        (address winner, uint256 score) = calculateGroupWinner(groupId);
        require(winner != address(0), "No valid winner found");

        uint256 prize = (groups[groupId].totalPot * 90) / 100; // 90% of group pot

        // Reset group pot before transfer to prevent reentrancy
        groups[groupId].totalPot = 0;

        // Transfer prize to winner
        (bool success,) = payable(winner).call{value: prize}("");
        require(success, "Failed to send prize to winner");

        emit GroupWinnerDeclared(groupId, groupName, winner, score);
    }

    // Array to track all created groups for batch operations
    bytes32[] private allGroupIds;

    /**
     * @dev Distributes prizes for multiple groups in batches to avoid gas limits
     * @param startIndex Starting index in the allGroupIds array
     * @param batchSize Number of groups to process in this batch
     */
    function distributeGroupPrizesBatch(uint256 startIndex, uint256 batchSize) external onlyOwner {
        require(roundWinners[3].length > 0, "Final round not complete");
        require(startIndex < allGroupIds.length, "Start index out of bounds");

        uint256 endIndex = startIndex + batchSize;
        if (endIndex > allGroupIds.length) {
            endIndex = allGroupIds.length;
        }

        for (uint256 i = startIndex; i < endIndex; i++) {
            bytes32 groupId = allGroupIds[i];

            // Skip if group has no prize pool
            if (groups[groupId].totalPot == 0) continue;

            (address winner, uint256 score) = calculateGroupWinner(groupId);
            if (winner == address(0)) continue; // No valid winner

            uint256 prize = (groups[groupId].totalPot * 90) / 100;

            // Reset group pot before transfer
            groups[groupId].totalPot = 0;

            // Transfer prize to winner
            (bool success,) = payable(winner).call{value: prize}("");
            require(success, "Failed to send prize to winner");

            emit GroupWinnerDeclared(groupId, groups[groupId].name, winner, score);
        }
    }

    /**
     * @dev Get total number of groups created
     */
    function getTotalGroupCount() external view returns (uint256) {
        return allGroupIds.length;
    }

    /**
     * @dev Get group IDs in a specific range for batch processing
     */
    function getGroupIdsBatch(uint256 startIndex, uint256 batchSize) external view returns (bytes32[] memory) {
        require(startIndex < allGroupIds.length, "Start index out of bounds");

        uint256 endIndex = startIndex + batchSize;
        if (endIndex > allGroupIds.length) {
            endIndex = allGroupIds.length;
        }

        bytes32[] memory batch = new bytes32[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            batch[i - startIndex] = allGroupIds[i];
        }

        return batch;
    }

    /**
     * @dev Calculates the winner within a specific group
     * @param groupId ID of the group
     * @return winner Address of the winner
     * @return highestScore Highest score achieved
     */
    function calculateGroupWinner(bytes32 groupId) public view returns (address winner, uint256 highestScore) {
        require(groups[groupId].exists, "Group does not exist");

        highestScore = 0;
        address[] memory groupMembers = groups[groupId].members;

        for (uint256 i = 0; i < groupMembers.length; i++) {
            address player = groupMembers[i];

            // Only consider players who have submitted brackets in this group
            if (!groupHasSubmitted[groupId][player]) continue;

            uint256 playerScore = 0;

            // Calculate score for each round
            for (uint256 round = 0; round < 4; round++) {
                playerScore += _calculateGroupRoundScore(groupId, player, round);
            }

            if (playerScore > highestScore) {
                highestScore = playerScore;
                winner = player;
            }
        }
    }

    /**
     * @dev Calculates score for a specific round within a group
     */
    function _calculateGroupRoundScore(bytes32 groupId, address player, uint256 roundIndex)
        private
        view
        returns (uint256)
    {
        uint256 score = 0;
        string[] memory winners = _getRoundWinners(roundIndex);
        string[] memory playerTeams = groupPlayerPredictions[groupId][player].rounds[roundIndex].teams;

        // For each winner in this round
        for (uint256 i = 0; i < winners.length; i++) {
            // Check if player predicted this winner
            for (uint256 j = 0; j < playerTeams.length; j++) {
                if (keccak256(bytes(winners[i])) == keccak256(bytes(playerTeams[j]))) {
                    // Apply round-specific points (only once per correct winner)
                    if (roundIndex == 0) score += ROUND_1_POINTS; // Wildcard = 1 point

                    else if (roundIndex == 1) score += ROUND_2_POINTS; // Divisional = 2 points

                    else if (roundIndex == 2) score += ROUND_3_POINTS; // Conference = 4 points

                    else if (roundIndex == 3) score += ROUND_4_POINTS; // Super Bowl = 6 points
                    break; // Break inner loop once we find a match
                }
            }
        }
        return score;
    }

    /**
     * @dev Gets winners for a specific round
     */
    function _getRoundWinners(uint256 round) private view returns (string[] memory) {
        return roundWinners[round];
    }

    // View functions for round winners (shared across all groups)

    /**
     * @dev Get winners for a specific round
     */
    function getRoundWinners(uint256 round) external view returns (string[] memory) {
        require(round <= 4 && round > 0, "Invalid round");
        return roundWinners[round - 1];
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
            roundWinners[0].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 2 winners (4 teams)
        for (uint256 i = 0; i < ROUND_2_PREDICTIONS; i++) {
            roundWinners[1].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 3 winners (2 teams)
        for (uint256 i = 0; i < ROUND_3_PREDICTIONS; i++) {
            roundWinners[2].push(winners[currentIndex]);
            currentIndex++;
        }

        // Set Round 4 winner (1 team)
        roundWinners[3].push(winners[currentIndex]);

        // Note: Group prizes must be distributed manually using distributeGroupPrize()
    }

    /**
     * @dev Pauses the creation of new brackets. Only owner can call.
     */
    function pauseBracketCreation() external onlyOwner {
        require(!isBracketCreationPaused, "Bracket creation is already paused");
        isBracketCreationPaused = true;
    }

    /**
     * @dev Resumes the creation of new brackets. Only owner can call.
     */
    function resumeBracketCreation() external onlyOwner {
        require(isBracketCreationPaused, "Bracket creation is not paused");
        isBracketCreationPaused = false;
    }

    /**
     * @dev Removes a winner from a specific round. Only callable by owner.
     * @param round Round number (1-4)
     * @param teamNum Team to remove
     */
    function removeWinner(uint256 round, string calldata teamNum) external onlyOwner {
        if (round < 1 || round > 4) revert InvalidRound();

        uint256 roundIndex = round - 1;
        bool found = false;

        // Remove from roundWinners array
        string[] storage roundWinnersList = roundWinners[roundIndex];
        for (uint256 i = 0; i < roundWinnersList.length; i++) {
            if (keccak256(bytes(roundWinnersList[i])) == keccak256(bytes(teamNum))) {
                roundWinnersList[i] = roundWinnersList[roundWinnersList.length - 1];
                roundWinnersList.pop();
                found = true;
                break;
            }
        }

        require(found, "Winner not found in this round");

        emit WinnerRemoved(round, teamNum);
    }

    /**
     * @dev Check if new brackets can be created
     */
    function canCreateNewBracket() external view returns (bool) {
        return !isBracketCreationPaused;
    }

    // Group-specific view functions

    /**
     * @dev Check if a group exists
     */
    function groupExists(string calldata groupName) external view returns (bool) {
        bytes32 groupId = _getGroupId(groupName);
        return groups[groupId].exists;
    }

    /**
     * @dev Get group members
     */
    function getGroupMembers(string calldata groupName) external view returns (address[] memory) {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        return groups[groupId].members;
    }

    /**
     * @dev Get group member count
     */
    function getGroupMemberCount(string calldata groupName) external view returns (uint256) {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        return groups[groupId].members.length;
    }

    /**
     * @dev Get group prize pool
     */
    function getGroupPrizePool(string calldata groupName) external view returns (uint256) {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        return (groups[groupId].totalPot * 90) / 100; // 90% of total pot
    }

    /**
     * @dev Get group entry fee
     */
    function getGroupEntryFee(string calldata groupName) external view returns (uint256) {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        return groups[groupId].entryFee;
    }

    /**
     * @dev Check if a player has submitted a bracket in a specific group
     */
    function hasSubmittedGroupBracket(address player, string calldata groupName) external view returns (bool) {
        bytes32 groupId = _getGroupId(groupName);
        return groups[groupId].exists && groupHasSubmitted[groupId][player];
    }

    /**
     * @dev Get all predictions for a player's bracket in a specific group
     */
    function getGroupBracketPredictions(address player, string calldata groupName)
        external
        view
        returns (string[][] memory result)
    {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        require(groupHasSubmitted[groupId][player], "Player has not submitted a bracket in this group");

        result = new string[][](4);

        for (uint256 roundIndex = 0; roundIndex < 4; roundIndex++) {
            result[roundIndex] = groupPlayerPredictions[groupId][player].rounds[roundIndex].teams;
        }

        return result;
    }

    /**
     * @dev Get score for a specific user's bracket in a group
     */
    function getGroupUserScore(address user, string calldata groupName) external view returns (uint256) {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");
        require(groupHasSubmitted[groupId][user], "No bracket found for this address in this group");

        uint256 score = 0;
        for (uint256 round = 0; round < 4; round++) {
            score += _calculateGroupRoundScore(groupId, user, round);
        }
        return score;
    }

    /**
     * @dev Get scores for all submitted brackets in a group
     */
    function getGroupAllScores(string calldata groupName)
        external
        view
        returns (address[] memory users, uint256[] memory scores)
    {
        bytes32 groupId = _getGroupId(groupName);
        require(groups[groupId].exists, "Group does not exist");

        address[] memory groupMembers = groups[groupId].members;

        // Count members who have submitted brackets
        uint256 submittedCount = 0;
        for (uint256 i = 0; i < groupMembers.length; i++) {
            if (groupHasSubmitted[groupId][groupMembers[i]]) {
                submittedCount++;
            }
        }

        users = new address[](submittedCount);
        scores = new uint256[](submittedCount);

        uint256 index = 0;
        for (uint256 i = 0; i < groupMembers.length; i++) {
            if (groupHasSubmitted[groupId][groupMembers[i]]) {
                users[index] = groupMembers[i];

                uint256 score = 0;
                for (uint256 round = 0; round < 4; round++) {
                    score += _calculateGroupRoundScore(groupId, groupMembers[i], round);
                }
                scores[index] = score;
                index++;
            }
        }

        return (users, scores);
    }

    /**
     * @dev Get all groups a player belongs to
     */
    function getPlayerGroups(address player) external view returns (bytes32[] memory) {
        return playerGroups[player];
    }

    /**
     * @dev Check if a player can join a group (not full and player hasn't submitted)
     */
    function canJoinGroup(address player, string calldata groupName) external view returns (bool) {
        bytes32 groupId = _getGroupId(groupName);
        if (!groups[groupId].exists) return true; // Can create new group
        if (groups[groupId].members.length >= MAX_GROUP_SIZE) return false; // Group is full
        if (groupHasSubmitted[groupId][player]) return false; // Already submitted
        return true;
    }

    /**
     * @dev Get the maximum allowed entry fee for groups
     */
    function getMaxEntryFee() external pure returns (uint256) {
        return MAX_ENTRY_FEE;
    }

    /**
     * @dev Get group info including entry fee (public function, no password required)
     * @param groupName Name of the group to check
     * @return exists Whether the group exists
     * @return entryFee Entry fee for the group (0 if group doesn't exist)
     * @return memberCount Number of members in the group
     * @return isFull Whether the group has reached maximum capacity
     */
    function getGroupInfo(string calldata groupName)
        external
        view
        returns (bool exists, uint256 entryFee, uint256 memberCount, bool isFull)
    {
        bytes32 groupId = _getGroupId(groupName);
        exists = groups[groupId].exists;

        if (exists) {
            entryFee = groups[groupId].entryFee;
            memberCount = groups[groupId].members.length;
            isFull = memberCount >= MAX_GROUP_SIZE;
        } else {
            entryFee = 0;
            memberCount = 0;
            isFull = false;
        }
    }
}
