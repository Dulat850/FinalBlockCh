// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GAME.sol";

contract Campaign {

    struct Contribution {
        uint256 amountETH;
        uint256 tokensMinted;
    }

    string public name;
    uint256 public goal;
    uint256 public deadline;
    uint256 public startTime;

    uint256 public totalRaised;
    bool public finalized;

    address public owner;
    GAME public gameToken;

    mapping(address => Contribution) public contributions;

    event ContributionMade(
        address indexed contributor,
        uint256 ethAmount,
        uint256 gameAmount
    );

    event CampaignFinalized(uint256 totalRaised);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier campaignActive() {
        require(block.timestamp < deadline, "Campaign ended");
        _;
    }

    constructor(
        string memory _name,
        uint256 _goal,
        uint256 _duration,
        address _gameToken
    ) {
        name = _name;
        goal = _goal;
        startTime = block.timestamp;
        deadline = block.timestamp + _duration;
        owner = msg.sender;
        gameToken = GAME(_gameToken);
    }

    function contribute() external payable campaignActive {
        require(msg.value > 0, "Zero value");

        uint256 gameAmount = calculateGameTokens(msg.value);

        totalRaised += msg.value;
        contributions[msg.sender].amountETH += msg.value;
        contributions[msg.sender].tokensMinted += gameAmount;

        gameToken.mint(msg.sender, gameAmount);

        emit ContributionMade(msg.sender, msg.value, gameAmount);
    }

    function calculateGameTokens(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 baseRate = 100;

        uint256 timePassed = block.timestamp - startTime;
        uint256 duration = deadline - startTime;

        uint256 reduction = (baseRate * timePassed) / duration;
        uint256 rate = baseRate > reduction ? baseRate - reduction : 10;

        if (totalRaised < goal / 5) {
            rate += 20;
        }

        return (ethAmount * rate) / 1 ether;
    }

    function finalizeCampaign() external onlyOwner {
    require(block.timestamp >= deadline, "Campaign not ended");
    require(!finalized, "Already finalized");

    finalized = true;

    (bool sent, ) = owner.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");

    emit CampaignFinalized(totalRaised);
}

}
