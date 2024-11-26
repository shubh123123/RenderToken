// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {

    IERC20 renderToken;
    address public owner;

    event TokensLocked(address user, uint amount);
    event TransactionExecuted(uint refundToOwner, uint refundToContributor);

    struct User {
        uint tokensLocked;
        uint[] jobIds;
    }

    mapping(uint => address) public jobId;
    mapping(address => User) private userInfo;

    uint jobIdCount;
    
    constructor(address _renderToken) {
        require(_renderToken != address(0), "Token address cannot be zero");
        renderToken = IERC20(_renderToken);
        owner = msg.sender;
    }

    function lockTokens(uint amount) external {
        require(amount > 0, "Amount should be greater than zero");
        renderToken.transferFrom(msg.sender, address(this), amount);
        User storage user = userInfo[msg.sender];
        user.tokensLocked += amount;
        user.jobIds.push(jobIdCount);
        jobId[jobIdCount] = msg.sender;
        jobIdCount++;
        emit TokensLocked(msg.sender, amount);
    }

    function transact(uint computationCost, address contributorAddress, uint _jobId) external {
        require(jobId[_jobId] == msg.sender, "Not valid user for this job");
        User storage user = userInfo[msg.sender];
        uint tokensLockedByUser = user.tokensLocked;
        require(tokensLockedByUser >= computationCost, "Amount of tokens locked are not enough to make this transaction");
        uint commission = (computationCost*10)/100;
        uint contributorShare = computationCost - commission;
        user.tokensLocked -= computationCost;
        renderToken.transfer(owner, commission);
        renderToken.transfer(contributorAddress, contributorShare);
        emit TransactionExecuted(commission, contributorShare);
    }

    function withdrawLocked() external {
        User storage user = userInfo[msg.sender];
        uint lockedTokens = user.tokensLocked;
        require(lockedTokens > 0, "No tokens are locked by the user");
        user.tokensLocked = 0;
        renderToken.transfer(msg.sender, lockedTokens);
    }

    function getUserInfo() external view returns(uint, uint[] memory) {
        User storage user = userInfo[msg.sender];
        return (user.tokensLocked, user.jobIds);
    }
    
}