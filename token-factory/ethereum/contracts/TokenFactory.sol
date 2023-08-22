// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20Token.sol";

contract TokenFactory {
    mapping(address => address) public userTokens;
    address[] public tokens;
    uint256 public tokenCount;

    event TokenDeployed(address tokenAddress);

    function deployToken(
        string calldata _name,
        string calldata _ticker,
        uint256 _supply,
        bool _isMintable,
        bool _isBurnable,
        bool _isPausable
    ) public returns (address) {
        ERC20Token token = new ERC20Token(
            _name,
            _ticker,
            _supply,
            _isMintable,
            _isBurnable,
            _isPausable
        );
        token.transfer(msg.sender, _supply);

        // update the storage
        tokens.push(address(token));
        userTokens[msg.sender] = address(token);
        tokenCount += 1;

        emit TokenDeployed(address(token));
        return address(token);
    }
}
