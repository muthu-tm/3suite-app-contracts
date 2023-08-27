// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSender is Ownable {
    using SafeMath for uint256;

    event Transfer(
        address indexed _token,
        address indexed _caller,
        uint256 _recipientCount,
        uint256 _totalTokensSent
    );

    event PricePerTxChanged(
        address indexed _caller,
        uint256 _oldPrice,
        uint256 _newPrice
    );

    event NativeTokenMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event TokensMoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event CreditsAdded(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event CreditsRemoved(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // mappting that stores User -> txn count
    mapping(address => uint256) public userTxnCount;

    // mappting that stores User -> credits
    mapping(address => uint256) public credits;

    // mappting that stores token transfer count
    mapping(address => uint256) public erc20TokenTransfers;

    // mappting that stores users -> native token transfers
    mapping(address => uint256) public nativeTokenTransfers;

    // transaction price
    uint256 public pricePerTx;

    constructor(uint256 _txnPrice) {
        pricePerTx = _txnPrice;
    }

    function transferNativeToken(
        address payable[] calldata _addresses,
        uint256[] calldata _values
    ) external payable returns (bool) {
        // if there is anything left over, I will keep it.
        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");

            totalTokensSent = totalTokensSent.add(_values[i]);
        }
        require(msg.value >= totalTokensSent, "Insufficient Payable Amount!!");
        if (credits[msg.sender] > 0) {
            credits[msg.sender] = credits[msg.sender].sub(1);
        } else {
            require(
                msg.value >= totalTokensSent.add(pricePerTx),
                "Insufficient Amount for Txn Price!!"
            );
        }

        for (uint i = 0; i < _addresses.length; i += 1) {
            _addresses[i].transfer(_values[i]);
        }

        nativeTokenTransfers[msg.sender] = nativeTokenTransfers[msg.sender].add(
            totalTokensSent
        );
        userTxnCount[msg.sender]++;
        emit Transfer(
            address(0),
            msg.sender,
            _addresses.length,
            totalTokensSent
        );
        return true;
    }

    function transferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _values
    ) external payable returns (bool) {
        require(
            _addresses.length == _values.length,
            "Address and Values must be in same length!!"
        );

        require(
            credits[msg.sender] > 0 || msg.value >= pricePerTx,
            "Must have Credit or Min Txn amount"
        );

        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");

            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
            totalTokensSent = totalTokensSent.add(_values[i]);
        }

        if (msg.value == 0 && credits[msg.sender] > 0) {
            credits[msg.sender] = credits[msg.sender].sub(1);
        }

        userTxnCount[msg.sender]++;
        erc20TokenTransfers[_token] = erc20TokenTransfers[_token].add(
            totalTokensSent
        );

        emit Transfer(_token, msg.sender, _addresses.length, totalTokensSent);
        return true;
    }

    function moveNativeToken(
        address payable _account
    ) external onlyOwner returns (bool) {
        uint256 contractBalance = address(this).balance;
        _account.transfer(contractBalance);

        emit NativeTokenMoved(msg.sender, _account, contractBalance);
        return true;
    }

    function moveTokens(
        address _token,
        address _account
    ) external onlyOwner returns (bool) {
        uint256 contractTokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_account, contractTokenBalance);

        emit TokensMoved(msg.sender, _account, contractTokenBalance);
        return true;
    }

    function addCredit(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        credits[_to] = credits[_to].add(_amount);

        emit CreditsAdded(msg.sender, _to, _amount);
        return true;
    }

    function reduceCredit(
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        credits[_to] = credits[_to].sub(_amount);

        emit CreditsRemoved(msg.sender, _to, _amount);
        return true;
    }

    function setPricePerTx(
        uint256 _pricePerTx
    ) external onlyOwner returns (bool) {
        uint256 oldPrice = pricePerTx;
        pricePerTx = _pricePerTx;

        emit PricePerTxChanged(msg.sender, oldPrice, pricePerTx);
        return true;
    }
}
