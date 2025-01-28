// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Create time-bound sessions others can mark themselves as attending.
contract Attendance {
    struct Session {
        uint48 start;
        uint48 end;
        uint256 totalAttended;
    }

    Session[] public sessions;
    mapping(address attendee => uint256 total) public totalAttendence;
    mapping(uint256 sessionId => mapping(address attendee => bool attended)) public hasAttended;

    event SessionCreated(uint256 sessionId, address creator, uint48 start, uint48 end);
    event SessionAttended(uint256 sessionId, address attendee);

    error InvalidStartEnd(uint48 start, uint48 end);
    error SessionDoesNotExist(uint256 sessionId, uint256 totalSessions);
    error HasAttendedSession(uint256 sessionId, address sender);

    /// @notice Get the total number of sessions created.
    function totalSessions() external view returns (uint256) {
        return sessions.length;
    }

    /// @notice Check if a session is currently active.
    function isActive(uint256 sessionId) external view returns (bool) {
        Session memory session = sessions[sessionId];
        return block.timestamp >= session.start && block.timestamp < session.end;
    }

    /// @notice Create a new session.
    function createSession(uint48 start, uint48 end) external returns (uint256 sessionId) {
        if (start >= end) revert InvalidStartEnd(start, end);

        sessionId = sessions.length;
        sessions.push(Session({start: start, end: end, totalAttended: 0}));
        emit SessionCreated(sessionId, msg.sender, start, end);
    }

    /// @notice Attend an active session.
    /// @dev Sessions can only be attended only once per address.
    function attendSession(uint256 sessionId) external {
        if (sessionId > sessions.length - 1) revert SessionDoesNotExist(sessionId, sessions.length);

        Session storage session = sessions[sessionId];
        if (block.timestamp < session.start || block.timestamp >= session.end) {
            revert InvalidStartEnd(session.start, session.end);
        }
        if (hasAttended[sessionId][msg.sender]) revert HasAttendedSession(sessionId, msg.sender);

        hasAttended[sessionId][msg.sender] = true;
        totalAttendence[msg.sender]++;
        session.totalAttended++;
        emit SessionAttended(sessionId, msg.sender);
    }
}
