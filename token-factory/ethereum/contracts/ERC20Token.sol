// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Pausable, Ownable {
    bool private isMintable;
    bool private isBurnable;
    bool private isPausable;

    modifier isTokenMintable() {
        require(
            isMintable == true,
            "Not Mintable: Token not allowed to mint more!"
        );
        _;
    }

    modifier isTokenBurnable() {
        require(isBurnable == true, "Not Burnable: Tokens are not burnable!");
        _;
    }

    modifier isTokenPausable() {
        require(isPausable == true, "Not Pausable: Token not Pausable!");
        _;
    }

    constructor(
        string memory _name,
        string memory _ticker,
        uint256 _supply,
        bool _isMintable,
        bool _isBurnable,
        bool _isPausable
    ) ERC20(_name, _ticker) {
        isMintable = _isMintable;
        isBurnable = _isBurnable;
        isPausable = _isPausable;

        _mint(msg.sender, _supply);
        transferOwnership(tx.origin);
    }

    function mint(address to, uint256 amount) public onlyOwner isTokenMintable {
        _mint(to, amount);
    }

    function burn(
        address account,
        uint256 amount
    ) public onlyOwner isTokenBurnable {
        _burn(account, amount);
    }

    function burnFrom(
        address account,
        uint256 amount
    ) public virtual onlyOwner isTokenBurnable {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function pause() public onlyOwner isTokenPausable {
        _pause();
    }

    function unpause() public onlyOwner isTokenPausable {
        _unpause();
    }
}
