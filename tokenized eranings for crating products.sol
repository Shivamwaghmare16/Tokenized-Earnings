// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenizedEarnings {
    string public constant productName = "EarningToken";
    string public constant symbol = "ETK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public owner;
    uint256 public totalRevenue; // Total revenue collected
    uint256 public productCount;

    struct Product {
        address creator;
        string title; // Renamed for clarity
        uint256 revenueShare; // Percentage of total revenue (10000 = 100%)
        uint256 revenueEarned; // Total revenue allocated
        bool isApproved;
    }

    mapping(uint256 => Product) public products;
    mapping(address => uint256) public balances;

    event ProductRegistered(uint256 indexed productId, address indexed creator, string title);
    event ProductApproved(uint256 indexed productId);
    event RevenueAdded(uint256 indexed productId, uint256 amount);
    event TokensMinted(address indexed recipient, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyApprovedProduct(uint256 productId) {
        require(products[productId].isApproved, "Product not approved");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Register a new product
    function registerProduct(string calldata productTitle, uint256 revenueShare) external {
        require(revenueShare > 0 && revenueShare <= 10000, "Invalid revenue share");

        products[productCount] = Product({
            creator: msg.sender,
            title: productTitle,
            revenueShare: revenueShare,
            revenueEarned: 0,
            isApproved: false
        });

        emit ProductRegistered(productCount, msg.sender, productTitle);
        productCount++;
    }

    // Approve a product for revenue sharing
    function approveProduct(uint256 productId) external onlyOwner {
        require(!products[productId].isApproved, "Product already approved");

        products[productId].isApproved = true;
        emit ProductApproved(productId);
    }

    // Add revenue to a product
    function addRevenue(uint256 productId) external payable onlyApprovedProduct(productId) {
        require(msg.value > 0, "Revenue must be greater than zero");

        Product storage product = products[productId];
        product.revenueEarned += msg.value;
        totalRevenue += msg.value;

        // Mint tokens proportional to revenue
        uint256 tokensToMint = (msg.value * product.revenueShare) / 10000;
        balances[product.creator] += tokensToMint;
        totalSupply += tokensToMint;

        emit RevenueAdded(productId, msg.value);
        emit TokensMinted(product.creator, tokensToMint);
    }

    // Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Withdraw funds
    function withdrawRevenue(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // View functions
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function getProductDetails(uint256 productId) external view returns (Product memory) {
        return products[productId];
    }
}
