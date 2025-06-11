// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OptimizedInventoryManagement {
    
    // Custom errors for gas efficiency (saves ~50% gas vs require strings)
    error NotOwner();
    error NotAuthorized();
    error ItemNotExists();
    error InvalidQuantity();
    error InvalidPrice();
    error EmptyItemName();
    error InsufficientStock(uint256 available, uint256 requested);
    error ZeroAddress();
    error AlreadyAuthorized();
    error UserNotAuthorized();
    error ContractPaused();
    error SameOwner();
    
    // Packed struct for gas optimization
    struct Item {
        uint128 quantity;    // Packed into single slot
        uint128 price;       // Packed into single slot
        string itemName;
        address addedBy;
        uint32 timestamp;    // uint32 sufficient until 2106
        bool exists;
    }
    
    // State variables optimized for packing
    address public owner;
    uint32 private nextItemId = 1;  // uint32 saves gas vs uint256
    bool public contractPaused;
    
    // Mappings
    mapping(uint32 => Item) public inventory;
    mapping(address => bool) public authorizedUsers;
    
    // Events with indexed parameters for efficient filtering
    event ItemAdded(uint32 indexed itemId, string itemName, uint128 quantity, uint128 price, address indexed addedBy);
    event ItemSold(uint32 indexed itemId, uint128 quantitySold, uint128 remainingQuantity, address indexed soldBy);
    event ItemUpdated(uint32 indexed itemId, string newName, uint128 newQuantity, uint128 newPrice, address indexed updatedBy);
    event StockReplenished(uint32 indexed itemId, uint128 addedQuantity, uint128 newTotalQuantity);
    event UserAuthorized(address indexed user, address indexed authorizedBy);
    event UserDeauthorized(address indexed user, address indexed deauthorizedBy);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Gas-optimized modifiers using custom errors
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier onlyAuthorized() {
        if (msg.sender != owner && !authorizedUsers[msg.sender]) revert NotAuthorized();
        _;
    }
    
    modifier itemExists(uint32 _itemId) {
        if (!inventory[_itemId].exists) revert ItemNotExists();
        _;
    }
    
    modifier whenNotPaused() {
        if (contractPaused) revert ContractPaused();
        _;
    }
    
    // Constructor with optimized initialization
    constructor() {
        owner = msg.sender;
        authorizedUsers[msg.sender] = true;
    }
    
    // Gas-optimized batch item addition
    function addItems(
        string[] calldata _itemNames,
        uint128[] calldata _quantities,
        uint128[] calldata _prices
    ) external onlyAuthorized whenNotPaused returns (uint32[] memory itemIds) {
        uint256 length = _itemNames.length;
        if (length != _quantities.length || length != _prices.length) revert InvalidQuantity();
        
        itemIds = new uint32[](length);
        uint32 currentId = nextItemId;
        
        // Batch processing to reduce gas overhead
        for (uint256 i = 0; i < length;) {
            if (bytes(_itemNames[i]).length == 0) revert EmptyItemName();
            if (_quantities[i] == 0) revert InvalidQuantity();
            if (_prices[i] == 0) revert InvalidPrice();
            
            inventory[currentId] = Item({
                quantity: _quantities[i],
                price: _prices[i],
                itemName: _itemNames[i],
                addedBy: msg.sender,
                timestamp: uint32(block.timestamp),
                exists: true
            });
            
            emit ItemAdded(currentId, _itemNames[i], _quantities[i], _prices[i], msg.sender);
            itemIds[i] = currentId;
            
            unchecked { 
                ++currentId; 
                ++i; 
            }
        }
        
        nextItemId = currentId;
    }
    
    // Single item addition with gas optimizations
    function addItem(
        string calldata _itemName,
        uint128 _quantity,
        uint128 _price
    ) external onlyAuthorized whenNotPaused returns (uint32) {
        if (bytes(_itemName).length == 0) revert EmptyItemName();
        if (_quantity == 0) revert InvalidQuantity();
        if (_price == 0) revert InvalidPrice();
        
        uint32 itemId = nextItemId;
        
        inventory[itemId] = Item({
            quantity: _quantity,
            price: _price,
            itemName: _itemName,
            addedBy: msg.sender,
            timestamp: uint32(block.timestamp),
            exists: true
        });
        
        unchecked { ++nextItemId; }
        
        emit ItemAdded(itemId, _itemName, _quantity, _price, msg.sender);
        return itemId;
    }
    
    // Optimized batch selling
    function sellItems(
        uint32[] calldata _itemIds,
        uint128[] calldata _quantities
    ) external onlyAuthorized whenNotPaused {
        uint256 length = _itemIds.length;
        if (length != _quantities.length) revert InvalidQuantity();
        
        for (uint256 i = 0; i < length;) {
            uint32 itemId = _itemIds[i];
            uint128 quantityToSell = _quantities[i];
            
            if (!inventory[itemId].exists) revert ItemNotExists();
            if (quantityToSell == 0) revert InvalidQuantity();
            
            Item storage item = inventory[itemId];
            if (item.quantity < quantityToSell) {
                revert InsufficientStock(item.quantity, quantityToSell);
            }
            
            unchecked { 
                item.quantity -= quantityToSell; 
                ++i;
            }
            
            emit ItemSold(itemId, quantityToSell, item.quantity, msg.sender);
        }
    }
    
    // Single item selling
    function sellItem(uint32 _itemId, uint128 _quantityToSell) 
        external onlyAuthorized whenNotPaused itemExists(_itemId) {
        if (_quantityToSell == 0) revert InvalidQuantity();
        
        Item storage item = inventory[_itemId];
        if (item.quantity < _quantityToSell) {
            revert InsufficientStock(item.quantity, _quantityToSell);
        }
        
        unchecked { item.quantity -= _quantityToSell; }
        
        emit ItemSold(_itemId, _quantityToSell, item.quantity, msg.sender);
    }
    
    // Gas-optimized item update
    function updateItem(
        uint32 _itemId,
        string calldata _newName,
        uint128 _newQuantity,
        uint128 _newPrice
    ) external onlyAuthorized whenNotPaused itemExists(_itemId) {
        if (bytes(_newName).length == 0) revert EmptyItemName();
        if (_newQuantity == 0) revert InvalidQuantity();
        if (_newPrice == 0) revert InvalidPrice();
        
        Item storage item = inventory[_itemId];
        item.itemName = _newName;
        item.quantity = _newQuantity;
        item.price = _newPrice;
        
        emit ItemUpdated(_itemId, _newName, _newQuantity, _newPrice, msg.sender);
    }
    
    // Optimized stock replenishment
    function replenishStock(uint32 _itemId, uint128 _additionalQuantity)
        external onlyAuthorized whenNotPaused itemExists(_itemId) {
        if (_additionalQuantity == 0) revert InvalidQuantity();
        
        Item storage item = inventory[_itemId];
        unchecked { item.quantity += _additionalQuantity; }
        
        emit StockReplenished(_itemId, _additionalQuantity, item.quantity);
    }
    
    // View functions with minimal gas usage
    function getItem(uint32 _itemId) external view itemExists(_itemId)
        returns (
            uint32 itemId,
            string memory itemName,
            uint128 quantity,
            uint128 price,
            address addedBy,
            uint32 timestamp
        ) {
        Item storage item = inventory[_itemId];
        return (_itemId, item.itemName, item.quantity, item.price, item.addedBy, item.timestamp);
    }
    
    function isOutOfStock(uint32 _itemId) external view itemExists(_itemId) returns (bool) {
        return inventory[_itemId].quantity == 0;
    }
    
    // Optimized low stock check with pagination
    function checkLowStock(uint128 _threshold, uint32 _start, uint32 _limit) 
        external view returns (uint32[] memory lowStockItems, uint32 count) {
        uint32 end = _start + _limit;
        if (end > nextItemId) end = nextItemId;
        
        uint32[] memory tempArray = new uint32[](_limit);
        
        for (uint32 i = _start; i < end;) {
            if (inventory[i].exists && inventory[i].quantity <= _threshold) {
                tempArray[count] = i;
                unchecked { ++count; }
            }
            unchecked { ++i; }
        }
        
        // Return only filled portion
        lowStockItems = new uint32[](count);
        for (uint32 j = 0; j < count;) {
            lowStockItems[j] = tempArray[j];
            unchecked { ++j; }
        }
    }
    
    // Gas-optimized authorization functions
    function authorizeUser(address _user) external onlyOwner {
        if (_user == address(0)) revert ZeroAddress();
        if (authorizedUsers[_user]) revert AlreadyAuthorized();
        
        authorizedUsers[_user] = true;
        emit UserAuthorized(_user, msg.sender);
    }
    
    function deauthorizeUser(address _user) external onlyOwner {
        if (_user == owner) revert NotOwner();
        if (!authorizedUsers[_user]) revert UserNotAuthorized();
        
        authorizedUsers[_user] = false;
        emit UserDeauthorized(_user, msg.sender);
    }
    
    // Batch authorization for gas efficiency
    function batchAuthorizeUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length;) {
            address user = _users[i];
            if (user != address(0) && !authorizedUsers[user]) {
                authorizedUsers[user] = true;
                emit UserAuthorized(user, msg.sender);
            }
            unchecked { ++i; }
        }
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddress();
        if (_newOwner == owner) revert SameOwner();
        
        address previousOwner = owner;
        owner = _newOwner;
        authorizedUsers[_newOwner] = true;
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
    
    function getTotalItems() external view returns (uint32) {
        return nextItemId - 1;
    }
    
    // Emergency controls
    function pauseContract() external onlyOwner {
        contractPaused = true;
    }
    
    function unpauseContract() external onlyOwner {
        contractPaused = false;
    }
    
    // Gas-efficient item removal
    function removeItem(uint32 _itemId) external onlyOwner itemExists(_itemId) {
        delete inventory[_itemId];
    }
}
