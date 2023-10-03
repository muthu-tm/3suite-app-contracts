// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Launchpad.sol";

contract LaunchpadFactory is Ownable {
    uint256 public pricePerSale;

    // user => sales created
    mapping(address => address[]) public userSales;
    mapping(address => uint32) public userSalesCount;
    // token => sales created
    mapping(address => address[]) public tokenSales;
    mapping(address => uint32) public tokenSalesCount;
    mapping(address => bool) public tokenWhitelist;

    // EVENTS
    event SaleCreated(address owner, address sale);

    modifier isValidToken(address _tokenAddress) {
        require(_tokenAddress != address(0), "Not a Valid Token Address");
        _;
    }

    constructor(uint256 _salePrice) {
        pricePerSale = _salePrice;
    }

    function createSale(
        address token,
        address tokenRaise,
        uint32 lpLockupTime,
        uint32 unLockTime,
        uint256 amountToSell,
        uint256 price,
        uint256 dexPrice,
        uint32 startTime,
        uint32 endTime,
        bool isPrivate,
        bool isWhitlisted
    ) public payable isValidToken(token) returns (address) {
        require(startTime > block.timestamp, "INVALID_SART_TIME");
        require(endTime > block.timestamp, "INVALID_END_TIME");
        require(endTime > startTime, "INVALID_SALE_TIME");
        require(lpLockupTime > block.timestamp, "INVALID_LOCKUP_TIME");
        require(unLockTime > endTime, "INVALID_UNLOCK_TIME");
        require(price <= dexPrice, "INVALID_SALE_PRICE");

        require(msg.value >= pricePerSale, "Insufficient Payable Amount!!");

        if (isPrivate == true) {
            isWhitlisted = true;
        }

        Launchpad sale = new Launchpad(
            token,
            tokenRaise,
            lpLockupTime,
            unLockTime,
            amountToSell,
            price,
            dexPrice,
            startTime,
            endTime,
            isPrivate,
            isWhitlisted
        );

        // update the storage
        tokenSalesCount[token] = userSalesCount[token] + 1;
        address[] storage tSales = tokenSales[token];
        tSales.push(address(sale));

        // update the storage
        userSalesCount[msg.sender] = userSalesCount[msg.sender] + 1;
        address[] storage uSales = userSales[msg.sender];
        uSales.push(address(sale));

        emit SaleCreated(msg.sender, address(sale));
        return address(sale);
    }

    function updatePricePerSale(uint256 _salePrice) public onlyOwner {
        pricePerSale = _salePrice;
    }

    function addTokenToWhitelist(address _token) public onlyOwner {
        tokenWhitelist[_token] = true;
    }

    function removeTokenFromWhitelist(address _token) public onlyOwner {
        delete tokenWhitelist[_token];
    }
}
