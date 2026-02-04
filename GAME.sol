// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GAME ERC20 Token
contract GameToken is ERC20, Ownable {
    uint256 public baseRate = 1000; // базовый rate токенов за 1 ETH
    uint256 public startTime;

    constructor() ERC20("GameToken", "GAME") {
        startTime = block.timestamp;
    }

    /// @notice Mint токенов при вкладе
    /// @param to Адрес получателя
    /// @param ethAmount Сумма ETH внесённая
    function mintForContribution(address to, uint256 ethAmount, uint256 contributorNumber) external onlyOwner {
        uint256 timeElapsed = block.timestamp - startTime;

        // Scarcity mechanic: с течением времени меньше токенов за ETH
        uint256 rate = baseRate;
        if (timeElapsed > 0) {
            // уменьшаем rate на 1% за каждый день (пример)
            uint256 daysElapsed = timeElapsed / 1 days;
            if (daysElapsed > 100) daysElapsed = 100; // ограничение min rate
            rate = rate * (100 - daysElapsed) / 100;
        }

        uint256 tokens = ethAmount * rate;

        // Бонус для первых 100 вкладчиков
        if (contributorNumber <= 100) {
            tokens = tokens + tokens / 10; // +10%
        }

        _mint(to, tokens);
    }
}

/// @title Crowdfunding Campaign
contract Campaign is Ownable {
    struct CampaignStruct {
        string name;
        uint256 goal;
        uint256 deadline;
        uint256 totalContributions;
        bool finalized;
        mapping(address => uint256) contributions;
        uint256 contributorCount;
    }

    GameToken public token;
    uint256 public campaignCount;
    mapping(uint256 => CampaignStruct) public campaigns;

    event CampaignCreated(uint256 indexed id, string name, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 indexed id, address indexed contributor, uint256 amount);
    event CampaignFinalized(uint256 indexed id, bool success);

    constructor(address tokenAddress) {
        token = GameToken(tokenAddress);
    }

    /// @notice Создание кампании
    function createCampaign(string calldata name, uint256 goal, uint256 durationInDays) external onlyOwner {
        campaignCount++;
        CampaignStruct storage c = campaigns[campaignCount];
        c.name = name;
        c.goal = goal;
        c.deadline = block.timestamp + durationInDays * 1 days;
        c.totalContributions = 0;
        c.finalized = false;
        c.contributorCount = 0;

        emit CampaignCreated(campaignCount, name, goal, c.deadline);
    }

    /// @notice Внесение ETH в кампанию
    function contribute(uint256 campaignId) external payable {
        CampaignStruct storage c = campaigns[campaignId];
        require(block.timestamp < c.deadline, "Campaign ended");
        require(msg.value > 0, "No ETH sent");
        require(!c.finalized, "Campaign finalized");

        if (c.contributions[msg.sender] == 0) {
            c.contributorCount++;
        }

        c.contributions[msg.sender] += msg.value;
        c.totalContributions += msg.value;

        // Минт токенов за вклад
        token.mintForContribution(msg.sender, msg.value, c.contributorCount);

        emit ContributionMade(campaignId, msg.sender, msg.value);
    }

    /// @notice Завершение кампании
    function finalizeCampaign(uint256 campaignId) external onlyOwner {
        CampaignStruct storage c = campaigns[campaignId];
        require(!c.finalized, "Already finalized");
        require(block.timestamp >= c.deadline, "Campaign not ended yet");

        c.finalized = true;

        // Если цель достигнута, средства остаются контракту (для simplicity)
        // Если цель не достигнута, возврат вкладов
        if (c.totalContributions < c.goal) {
            for (uint i = 0; i < c.contributorCount; i++) {
                // В реальном контракте нужен массив адресов, здесь упрощено
            }
        }

        emit CampaignFinalized(campaignId, c.totalContributions >= c.goal);
    }

    /// @notice Получить вклад конкретного пользователя
    function contributionOf(uint256 campaignId, address user) external view returns (uint256) {
        return campaigns[campaignId].contributions[user];
    }
}
