// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Launchpad is Ownable {
    struct Sale {
        address token;
        address tokenRaise;
        uint32 lpLockupTime;
        uint32 unLockTime;
        uint256 amountToSell;
        uint256 price;
        uint256 minParticipation;
        uint256 maxParticipation;
        uint256 dexPrice;
        uint32 startTime;
        uint32 endTime;
        bool isPrivate;
        bool isWhitlisted;
    }

    struct SaleContribution {
        uint time;
        uint256 tokenSold;
        uint256 amountRaised;
    }

    struct Sales {
        bool isWithdrawn;
        uint256 tokenSold;
        uint256 amountRaised;
    }

    struct SaleStats {
        uint256 totalSold;
        uint256 totalRaised;
    }

    uint8 private status;
    Sale public saleInfo;
    SaleStats public saleStats;
    mapping(address => Sales) sales;
    mapping(address => SaleContribution[]) public saleContribution;
    mapping(address => uint32) public userContributionCount;
    mapping(address => bool) public whitelistedUsers;

    modifier isSaleEnd() {
        require(saleInfo.endTime >= block.timestamp, "SALE_ENDED");
        _;
    }

    constructor(
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
    ) {
        Sale storage sale = saleInfo;
        sale.token = token;
        sale.tokenRaise = tokenRaise;
        sale.lpLockupTime = lpLockupTime;
        sale.unLockTime = unLockTime;
        sale.amountToSell = amountToSell;
        sale.price = price;
        sale.dexPrice = dexPrice;
        sale.startTime = startTime;
        sale.endTime = endTime;
        sale.isPrivate = isPrivate;
        sale.isWhitlisted = isWhitlisted;

        // SALE created
        status = 0;

        transferOwnership(tx.origin);
    }

    function isSaleLive() internal view returns (bool) {
        if (
            status == 1 &&
            saleInfo.startTime <= block.timestamp &&
            saleInfo.endTime > block.timestamp
        ) {
            return true;
        }

        return false;
    }

    function depositTokens() public payable onlyOwner {
        require(status == 0, "WRONG_STATUS");

        uint256 value = saleInfo.amountToSell * 2;
        IERC20(saleInfo.token).transferFrom(msg.sender, address(this), value);

        // update the sale status
        status = 1;
    }

    function participateInSale(
        uint256 _amount
    ) public payable returns (uint256 totalAmount) {
        require(block.timestamp >= saleInfo.startTime, "SALE_NOT_STARTED");
        require(block.timestamp <= saleInfo.endTime, "SALE_ENDED");
        require(status == 1, "WRONG_STATUS");

        if (saleInfo.isWhitlisted) {
            require(whitelistedUsers[msg.sender] == true, "NOT_WHITELISTED");
        }

        uint256 _totalAmount = 0;
        for (
            uint32 index = 0;
            index < saleContribution[msg.sender].length;
            index++
        ) {
            SaleContribution memory _sc = saleContribution[msg.sender][index];
            _totalAmount += _sc.amountRaised;
        }

        uint256 tokenSale;
        uint256 amount;
        if (saleInfo.tokenRaise != address(0)) {
            require(
                _amount >= saleInfo.minParticipation,
                "Insufficient Contribution Amount"
            );
            // validate maximum Participation amount
            require(
                _totalAmount + _amount > saleInfo.maxParticipation,
                "GREATER_THAN_MAX"
            );

            tokenSale = _amount / saleInfo.price;
            IERC20(saleInfo.tokenRaise).transferFrom(
                msg.sender,
                address(this),
                _amount
            );

            amount = _amount;
        } else {
            require(
                msg.value >= saleInfo.minParticipation,
                "Insufficient Contribution Amount"
            );
            // validate maximum Participation amount
            require(
                _totalAmount + msg.value > saleInfo.maxParticipation,
                "GREATER_THAN_MAX"
            );

            tokenSale = msg.value / saleInfo.price;
            amount = msg.value;
        }

        SaleContribution memory sc = SaleContribution(
            block.timestamp,
            tokenSale,
            amount
        );

        // update user sales
        sales[msg.sender].tokenSold = sales[msg.sender].tokenSold + tokenSale;
        sales[msg.sender].amountRaised = sales[msg.sender].amountRaised + amount;

        // update total sale stats
        saleStats.totalRaised = saleStats.totalRaised + amount;
        saleStats.totalSold = saleStats.totalSold + tokenSale;

        SaleContribution[] storage uCont = saleContribution[msg.sender];
        uCont.push(sc);
        userContributionCount[msg.sender] =
            userContributionCount[msg.sender] +
            1;

        return _totalAmount;
    }

    function withdrawTokens() public isSaleEnd {
        require(status == 2, "WRONG_STATUS");
        require(sales[msg.sender].tokenSold > 0, "NOT_PARTICIPATED");
        require(block.timestamp > saleInfo.unLockTime, "NOT_UNLOCKED");
        require(sales[msg.sender].isWithdrawn == false, "ALREADY_WITHDRAWN");

        IERC20(saleInfo.token).transfer(msg.sender, sales[msg.sender].tokenSold);
        sales[msg.sender].isWithdrawn = true;
    }

    function rescueFunds(uint256 tokenAmount) public onlyOwner {
        // Only in case of emergency
        IERC20(saleInfo.token).transfer(msg.sender, tokenAmount);
    }

    function addUserToWhitelist(address _user) public onlyOwner isSaleEnd {
        whitelistedUsers[_user] = true;
    }

    function removeUserFromwhitelist(address _user) public onlyOwner isSaleEnd {
        delete whitelistedUsers[_user];
    }
}
