// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20Token.sol";

contract TokenFactory {
    mapping(address => address[]) public userTokens;
    mapping(address => uint32) public usersCount;
    address[] public tokens;
    uint256 public tokenCount;

    event TokenDeployed(address tokenAddress);

    function deployToken(
        string calldata _name,
        string calldata _symbol,
        uint256 _supply,
        uint8 _tokDecimals,
        bool _isMintable,
        bool _isBurnable,
        bool _isPausable
    ) public returns (address) {
        ERC20Token token = new ERC20Token(
            _name,
            _symbol,
            _supply,
            _tokDecimals,
            _isMintable,
            _isBurnable,
            _isPausable
        );

        // update the storage
        tokens.push(address(token));
        usersCount[msg.sender] = usersCount[msg.sender] + 1;
        address[] storage utokens = userTokens[msg.sender];
        utokens.push(address(token));
        tokenCount += 1;

        emit TokenDeployed(address(token));
        return address(token);
    }
}
