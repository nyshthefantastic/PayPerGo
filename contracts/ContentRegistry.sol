// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ContentRegistry {
    struct Content {
        uint256 contentId;
        address creatorWalletAddress;
        uint256 ratePerUnit;
        uint256 maxUnits;
        string title;
        string contentData;
        uint256 timestamp;
    }

    // Mapping: contentId → Content details
    mapping(uint256 => Content) public contents;

    // Array to store all content IDs
    uint256[] private contentIds;

    // Mapping: userAddress → escrow balance
    mapping(address => uint256) public escrowBalances;

    // Mapping: userAddress → (contentId → units consumed)
    mapping(address => mapping(uint256 => uint256)) public usage;

    // Mapping: creatorWalletAddress → earnings
    mapping(address => uint256) public creatorEarnings;

    event ContentRegistered(
        uint256 indexed contentId,
        address indexed creator,
        uint256 ratePerUnit,
        uint256 maxUnits,
        string title,
        string contentData,
        uint256 timestamp
    );
    event EscrowDeposited(address indexed user, uint256 paymentValue);
    event EscrowWithdrawn(address indexed user, uint256 amount);
    event ContentAccessed(
        uint256 indexed contentId,
        address indexed user,
        uint256 unitsPurchased,
        uint256 totalCost,
        uint256 totalUnitsConsumed
    );
    event EarningsWithdrawn(address indexed creator, uint256 amount);

    modifier onlyCreator(uint256 _contentId) {
        require(msg.sender == contents[_contentId].creatorWalletAddress, "Not content creator");
        _;
    }

    /// @notice Registers a new content for pay-per-use consumption
    function registerContent(
        uint256 _contentId,
        uint256 _ratePerUnit,
        uint256 _maxUnits,
        string calldata _title,
        string calldata _contentData
    ) external {
        require(contents[_contentId].creatorWalletAddress == address(0), "Content already registered");
        require(_ratePerUnit > 0, "Rate must be > 0");

        contents[_contentId] = Content({
            contentId: _contentId,
            creatorWalletAddress: msg.sender,
            ratePerUnit: _ratePerUnit,
            maxUnits: _maxUnits,
            title: _title,
            contentData: _contentData,
            timestamp: block.timestamp
        });

        contentIds.push(_contentId); // Store the contentId in the array

        emit ContentRegistered(_contentId, msg.sender, _ratePerUnit, _maxUnits, _title, _contentData, block.timestamp);
    }

    /// @notice Returns all registered content IDs
    function getAllContentIds() external view returns (uint256[] memory) {
        return contentIds;
    }

    /// @notice Returns the content data for a given content ID
    function getContentData(uint256 _contentId) external view returns (string memory, string memory, uint256) {
        require(contents[_contentId].creatorWalletAddress != address(0), "Content not found");
        Content memory content = contents[_contentId];
        return (content.title, content.contentData, content.timestamp);
    }

    /// @notice Deposit funds into escrow for later consumption
    function depositToEscrow() external payable {
        require(msg.value > 0, "Deposit must be > 0");
        escrowBalances[msg.sender] += msg.value;
        emit EscrowDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw unused escrow funds
    function withdrawEscrow() external {
        uint256 balance = escrowBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");

        escrowBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit EscrowWithdrawn(msg.sender, balance);
    }

    /// @notice Pay-per-use to access content. This will update usage
    ///         and store earnings for the creator.
    function accessContent(uint256 _contentId, uint256 _unitsToBuy) external {
        Content storage content = contents[_contentId];
        require(content.creatorWalletAddress != address(0), "Content not found");
        require(_unitsToBuy > 0, "Must buy at least 1 unit");

        uint256 userConsumed = usage[msg.sender][_contentId];
        
        // If maxUnits is not 0, enforce a maximum usage
        require(
            content.maxUnits == 0 || userConsumed + _unitsToBuy <= content.maxUnits,
            "Exceeds max usage limit"
        );

        uint256 totalCost = content.ratePerUnit * _unitsToBuy;
        require(escrowBalances[msg.sender] >= totalCost, "Insufficient escrow balance");

        // Deduct escrow & track usage
        escrowBalances[msg.sender] -= totalCost;
        usage[msg.sender][_contentId] += _unitsToBuy;

        // Instead of transferring funds immediately, store in creator earnings
        creatorEarnings[content.creatorWalletAddress] += totalCost;

        emit ContentAccessed(
            _contentId,
            msg.sender,
            _unitsToBuy,
            totalCost,
            usage[msg.sender][_contentId]
        );
    }

    /// @notice Allows creators to withdraw their earnings from escrow
    function withdrawEarnings(uint256 _contentId) external onlyCreator(_contentId) {
        uint256 earnings = creatorEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw");

        // Reset earnings before transfer (protection against reentrancy)
        creatorEarnings[msg.sender] = 0;

        payable(msg.sender).transfer(earnings);

        emit EarningsWithdrawn(msg.sender, earnings);
    }

    /// @notice View function to check user's consumption for a specific content
    function getUserUsage(address _user, uint256 _contentId) external view returns (uint256) {
        return usage[_user][_contentId];
    }

    /// @notice View function to check escrow balance of a user
    function getEscrowBalance(address _user) external view returns (uint256) {
        return escrowBalances[_user];
    }
}
