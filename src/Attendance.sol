// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Attendance {
    struct Session {
        uint48 start;
        uint48 end;
        uint160 totalAttended;
    }

    Session[] public sessions;
    mapping(address attendee => uint256 total) public totalAttendence;
    mapping(uint256 sessionId => mapping(address attendee => bool attended)) public hasAttended;

    event SessionCreated(uint256 sessionId, address creator, uint48 start, uint48 end);
    event SessionAttended(uint256 sessionId, address attendee);

    function createSession(uint48 start, uint48 end) external {
        if (start >= end) revert();

        uint256 sessionId = sessions.length;
        sessions.push(Session(start, end, 0));
        emit SessionCreated(sessionId, msg.sender, start, end);
    }

    function attendSession(uint256 sessionId) external {
        if (sessionId > sessions.length - 1) revert();

        Session storage session = sessions[sessionId];
        if (block.timestamp < session.start || block.timestamp > session.end) revert();

        if (hasAttended[sessionId][msg.sender]) revert();

        hasAttended[sessionId][msg.sender] = true;
        totalAttendence[msg.sender]++;
        session.totalAttended++;
        emit SessionAttended(sessionId, msg.sender);
    }
}
